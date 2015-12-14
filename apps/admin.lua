--[[

    admin.lua

    Let's put things in the database and stuff!

]]

-- csrf for form validation yo and let's capture some errors?!
local csrf = require("lapis.csrf")
local capture_errors = require("lapis.application").capture_errors

-- modules the admin pages need
local config = require("lapis.config").get()
local bcrypt = require("bcrypt")
local json = require("cjson")
local cache = require("lapis.cache")
local db = require("lapis.db")

-- our submodule loader and subApp
local subApp = require("util.subAppLoader")
local admin = subApp:new()

local function verifyLogin(username, password)
    local dbPassword = db.query("SELECT password FROM users WHERE displayname = ?", username)
    local verified = bcrypt.verify(password, dbPassword[1].password)
    password = nil
    return verified
end

local function doesAdminExist()
	local exists = db.query("select exists (SELECT 1 from users where account_id = 1 LIMIT 1)")
	return exists[1].exists
end

-- check if user exists in databse
local function checkUser(username, email)
	local checkprepare = db.query("PREPARE checkUser(text, citext) AS select exists (select 1 from users where (displayname=$1 OR primary_email=$2) LIMIT 1)")
	print(json.encode(checkprepare))
	local execute = db.query("EXECUTE checkUser(?, ?)", username, email)
	print(json.encode(execute))
	return execute[1].exists
end

-- ensure password from the database is correct (returns true if valid)
local function verifyPassword(usernameOrEmail, password)
	local prepare = db.query("PREPARE getPassword(text, citext) AS select displayname, password from users where (displayname=$1 OR primary_email=$2) LIMIT 1")
	print(json.encode(prepare))
	local dbPassword = db.query("EXECUTE getPassword(?, ?)", usernameOrEmail, usernameOrEmail:lower())
	-- print(json.encode(execute))
	local verified = bcrypt.verify(password, dbPassword[1].password)
	password = nil
	usernameOrEmail = nil
	return verified, dbPassword[1].displayname
end

-- hrefToID is a set, if you have a field in that set, it'll add an href to the given url
-- with the ".id" appended (it also assumes that id exists in the tableInput)
-- ex: self.problem_table = createHTMLTable(problems, {"id", "name", "date"}, {["name"] = "/admin/edit-problem/"})
-- the name field will be hyperlinked to "/admin/edit-problem/id"
local function createHTMLTable(tableInput, fields, hrefToID)
	local htmlTable = "<table>"
	local hrefToID = hrefToID or {}

	-- create the header
	htmlTable = htmlTable .. "<thead><tr>"
	for i = 1, #fields do
		htmlTable = htmlTable .. "<th>" .. fields[i] .. "</th>"
	end
	htmlTable = htmlTable .. "</tr></thead><tbody>"

	-- go through and create the body
	for i = 1, #tableInput do
		htmlTable = htmlTable .. "<tr>"
		for j = 1, #fields do
			if hrefToID[fields[j]] then
				htmlTable = htmlTable .. "<td>" .. "<a href='" .. hrefToID[fields[j]] .. tableInput[i].id .."'>" .. tableInput[i][fields[j]] .. "</a></td>"
			else
				htmlTable = htmlTable .. "<td>" .. tableInput[i][fields[j]] .. "</td>"
			end
		end
		htmlTable = htmlTable .. "</tr>"
	end

	-- close it out
	htmlTable = htmlTable .. "</tbody></table>"

	-- and return!
	return htmlTable
end

admin:get("admin-dashboard", "/admin/dashboard", function(self)
	self.title = "Admin Page"
	self.csrf_token = csrf.generate_token(self)
	if doesAdminExist() then
		if self.session.admin then
			return { render = "admin.dashboard" }
		else
			self.redirect_to = "admin-dashboard"
			return { render = "admin.login" }
		end
	else
		--gotta create an admin!
		return { render = "admin.create" }
	end
end)

admin:post("admin-create", "/admin/create", function(self)
	-- assert all the things
	csrf.assert_token(self)
	assert(self.params["username"]:len() >= 1, "Username must be filled in!")
	assert(self.params["password"]:len() >= 12, "Password must be greater than 12 characters")
	assert(self.params["password"] == self.params["repeat-password"], "Password must equal the repeat password")
	assert(self.params['email']:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?"), "email must be real!")
	checkUser(self.params["username"], self.params["email"]:lower())
	assert(not validUser, "Username or email already in database")

	-- insert into the database!
	local firstquery = db.query("PREPARE insertAdmin (text, CITEXT, text) AS INSERT INTO USERS (DISPLAYNAME, PRIMARY_EMAIL, PASSWORD, ACCOUNT_ID) VALUES($1, $2, $3, 1)")
    print(json.encode(firstquery))
	local query = db.query("EXECUTE insertAdmin(?, ?, ?)", self.params["username"], self.params["email"]:lower(), bcrypt.digest(self.params["password"], 10))
	return { redirect_to = self:url_for("admin-dashboard")}
end)

admin:post("admin-login", "/admin/login", function(self)
	-- assert things to ensure they are golden!
	csrf.assert_token(self)
	local validUser = checkUser(self.params["username"],self.params["username"]:lower())
	assert(validUser, "Username or Email not in database")
	local passwordCorrect
	passwordCorrect, self.params["username"] = verifyPassword(self.params["username"], self.params["password"])
	assert(passwordCorrect, "Password is incorrect")

	-- create a cookie and go back to the dashboard. At some other point, it might make more sense
	-- to pass around which page they were on before being sent to the login form.
	-- I'll get there if there's a need.

	self.session.username = self.params["username"]
	self.session.admin = true
	return { redirect_to = self:url_for(self.params["redirect_to"])}

end)

admin:get("admin-create-problem", "/admin/create-problem", function(self)
	if not self.session.admin then
		self.redirect_to = "admin-create-problem"
		return { render = "admin.login" }
	end

	-- some niceties
	self.title = "Create a New Problem"
	self.postform = "/admin/post-problem/new"
	self.csrf_token = csrf.generate_token(self)

	-- values are empty. This is only set because the create and edit share a form
	self.values = {}

	-- let's get the solution methods and put them in a table!
	local solution_methods = db.select("* from solution_methods")
	self.solution_method = createHTMLTable(solution_methods, {"id", "type"})

	-- do the same thing for categories
	local dbcategories = db.select("* from categories")
	self.categories = createHTMLTable(dbcategories, {"id", "type"})

  	return { render = "admin.create-problem" }
end)


-- WAAAY too much trust with this one. Very little actual checking. Might be dangerous.
-- https://youtu.be/E8b4xYbEugo
admin:post("admin-post-problem", "/admin/post-problem/:id", function(self)
	-- better hope we're looking good here
	csrf.assert_token(self)
	if not self.session.admin then
		self.redirect_to = "admin-create-problem"
		return { render = "admin.login" }
	end

	-- if you try to create a new solution_id or category here, the code will
	-- error out, but these two functions will run. You need to go back and then
	-- resubmit the form (or even a smart refresh)
	-- creates the solution id
	if tonumber(self.params['solution_id']) == nil then
		self.params['solution_id'] = db.insert("solution_methods", {
			type = self.params['solution_id']
		}, "id")
	end

	-- creates the category
	if tonumber(self.params['category']) == nil then
		self.params['category'] = db.insert("categories", {
			type = self.params['category']
		}, "id")
	end

	-- BUILD THE INSERTS!
	local insertTable = {
		date = self.params['date'],
		category_id = self.params['category'],
		solution_id = self.params['solution_id'],
		name = self.params['name'],
		level = self.params['level'],
		problem = self.params['problem'],
		answer = self.params['answer'],
		answer_desc = self.params['answer_description']
	}

	if self.params['hint'] and self.params['hint'] ~= "" then
		insertTable.hint = self.params['hint']
	end

	-- consider turning this into a prepared statement.
	-- however, SQLi here would be a little hard.
	-- regardless I'll do it at some point!
	-- we need to do an update instead of an insert if the id is given.
	if self.params.id == "new" then
		db.insert("problems", insertTable)
	else
		db.update("problems", insertTable, "id = ?", self.params.id)
	end
	cache.delete_path("/p/" .. insertTable.date)

	return { render = "admin.success" }
end)

admin:get("admin-select-problem", "/admin/select-problem", function(self)
	if not self.session.admin then
		-- hmm maybe something a little different
		self.redirect_to = "admin-select-problem"
		return { render = "admin.login" }
	end

	-- gotta title the page!
	self.title = "Select a problem to edit"

	local problems = db.select("id, name, date, level from problems order by id desc")
	self.problem_table = createHTMLTable(problems, {"id", "name", "date", "level"}, {["name"] = "/admin/edit-problem/"})

	return { render = "admin.select-problem" }

end)

admin:get("admin-edit-problem", "/admin/edit-problem/:id", function(self)
	if not self.session.admin then
		-- hmm maybe something a little different to account for the date.
		self.redirect_to = "admin-select-problem"
		return { render = "admin.login" }
	end

	-- some niceties
	self.title = "Edit an existing Problem"
	self.postform = "/admin/post-problem/" .. self.params.id
	self.csrf_token = csrf.generate_token(self)

	-- grab the values from the database and send them in!
	self.values = db.select("* from problems where id = ?", self.params.id)[1]

	-- let's get the solution methods and put them in a table!
	local solution_methods = db.select("* from solution_methods")
	self.solution_method = createHTMLTable(solution_methods, {"id", "type"})

	-- do the same thing for categories
	local dbcategories = db.select("* from categories")
	self.categories = createHTMLTable(dbcategories, {"id", "type"})

  	return { render = "admin.edit-problem" }
end)

admin:post("admin-delete-problem", "/admin/delete-problem/:id", function(self)
	csrf.assert_token(self)
	if not self.session.admin then
		-- hmm maybe something a little different to account for the date.
		self.redirect_to = "admin-select-problem"
		return { render = "admin.login" }
	end

	-- let's also clear the cache. We'll need the date tho!
	-- BONUS: if id is invalid, this should bomb out.
	local date = db.select("date from problems where id = ?", self.params.id)[1].date
	cache.delete_path("/p/" .. date)
	db.delete("problems", "id = ?", self.params.id)

	return { render = "admin.success" }
end)

return admin
