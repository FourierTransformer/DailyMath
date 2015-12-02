--[[

    admin.lua

    Let's put things in the database and stuff!

]]

-- csrf for form validation yo and let's capture some errors?!
local csrf = require("lapis.csrf")
local capture_errors = require("lapis.application").capture_errors

-- configs
local config = require("lapis.config").get()

-- bcrypt for encryption
local bcrypt = require("bcrypt")

local json = require("cjson")

-- and lapis.db to access the database
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
	return json.encode(query)
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
	self.csrf_token = csrf.generate_token(self)

	-- let's get the solution methods and put them in a table!
	local smethod = db.select("* from solution_methods")
	local solution_method = "<table>"
	solution_method = solution_method .. "<thead><tr><th>id</th><th>type</th></tr></thead><tbody>"
	for i = 1, #smethod do
		solution_method = solution_method .. "<tr>"
		solution_method = solution_method .. "<td>" .. smethod[i].id .. "</td>"
		solution_method = solution_method .. "<td>" .. smethod[i].type .. "</td>"
		solution_method = solution_method .. "</tr>"
	end
	solution_method = solution_method .. "</tbody></table>"
	self.solution_method = solution_method

	-- do the same thing for categories
	local dbcategories = db.select("* from categories")
	local categories = "<table>"
	categories = categories .. "<thead><tr><th>id</th><th>type</th></tr></thead><tbody>"
	for i = 1, #dbcategories do
		categories = categories .. "<tr>"
		categories = categories .. "<td>" .. dbcategories[i].id .. "</td>"
		categories = categories .. "<td>" .. dbcategories[i].type .. "</td>"
		categories = categories .. "</tr>"
	end
	categories = categories .. "</tbody></table>"
	self.categories = categories

  	return { render = "admin.create-problem" }
end)


-- WAAAY too much trust with this one. Very little actual checking. Might be dangerous.
-- https://youtu.be/E8b4xYbEugo
admin:post("admin-post-problem", "/admin/post-problem", function(self)
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
	db.insert("problems", insertTable)

	return { render = "admin.success" }
end)

return admin