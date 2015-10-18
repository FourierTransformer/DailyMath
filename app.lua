local lapis = require("lapis")
local app = lapis.Application()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- bcrypt for encryption
local bcrypt = require("bcrypt")

-- and db to access the database layer
local db = require("lapis.db")

local function verifyLogin(username, password)
    local dbPassword = db.query("SELECT password FROM users WHERE displayname = ?", username)
    local verified = bcrypt.verify(password, dbPassword[1].password)
    password = nil
    return verified
end

-- setup that homepage yo
app:match("/", function(self)
    self.title = "DailyMath - a new math problem every weekday!"
    return { render = "index" }
    --return "Welcome to DailyMath" .. tostring(verifyLogin("admin", "MMG8Z9b4qQuZrpDy")) .. bcrypt.digest("PAUL", 4)
end)

local function getProblem(date)
    local date = date or os.date("%F")
    local query = db.query([[SELECT problem, categories.type, level, answer, hint, answer_desc FROM problems 
                            LEFT OUTER JOIN categories ON (problems.category_id = categories.id)
                            WHERE date = ? AND approved = true]], date)
    if query ~= nil and query[1] ~= nil then
        return {layout = false, json = {problems = query}}
    else
        return {status = 404, layout = false, json = {error = "There are no problems available for that date."}}
    end
end

local function getAnswer(date)
    local date = date or os.date("%F")
    local query = db.query("SELECT answer, level FROM problems WHERE date = ? AND approved = true", date)
    if query ~= nil and query[1] ~= nil then
        return {layout = false, json = {answers = query}}
    else
        return {status = 404, layout = false, json = { error = "There is no answer available for that date." } }
    end
end

local function getHint(date)
    local date = date or os.date("%F")
    local query = db.query("SELECT hint, level FROM problems WHERE date = ? AND approved = true", date)
    if query ~= nil and query[1] ~= nil then
        return {layout = false, query[1].answer}
    else
        return {status = 404, layout = false, json = { error = "There is no hint available for that date."} }
    end
end

-- get the answer for today
app:get("/api/v1/answers/today", function(self)
    return getAnswer()
end)

-- get the answer for any specific date
app:get("/api/v1/answers/:date", function(self)
    -- TODO: actually check if date is in the right format and error gracefully if it isnt
    -- TODO: potentially add filter for level
    return getAnswer(self.params.date)
end)

-- get the answer for today
app:get("/api/v1/problems/today", function(self)
    return getProblem()
end)

-- get the answer for any specific date
app:get("/api/v1/problems/:date", function(self)
    -- TODO: actually check if date is in the right format and error gracefully if it isnt
    -- TODO: potentially add filter for level
    return getProblem(self.params.date)
end)

app:match("about", "/about", function(self)
  return { render = true }
end)



return app
