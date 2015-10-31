local lapis = require("lapis")
local app = lapis.Application()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- and lapis.db to access the database
local db = require("lapis.db")

-- get some caching up in here!
local cached = require("lapis.cache").cached

-- csrf for form validation yo and let's capture some errors?!
local csrf = require("lapis.csrf")
local capture_errors = require("lapis.application").capture_errors

-- verify that recaptcha yo
local http = require("lapis.nginx.http")
local from_json = require("lapis.util").from_json

-- configs
local config = require("lapis.config").get()

local function jsonError(titleText, detailText)
    return {
        errors = {
            title = titleText,
            detail = detailText
        }
    }
end

local function getProblem(date)
    -- either use the submitted date or today's date
    local date = date or os.date("%F")

    -- do some quick validation on the date
    if date:len() ~= 10 or not string.match(date, "%d%d%d%d%-%d%d%-%d%d") then
        return {status = 404, layout = false, json = jsonError("The date string is not properly formatted", "The date string should follow 'YYYY-MM-DD.'")}
    end

    -- query the database!
    local query = db.query([[SELECT problem, categories.type, level, answer, hint, answer_desc FROM problems 
                            LEFT OUTER JOIN categories ON (problems.category_id = categories.id)
                            WHERE date = ? AND approved = true]], date)

    -- return as necessary
    if query ~= nil and query[1] ~= nil then
        return {layout = false, json = {problems = query}}
    else
        return {status = 404, layout = false, json = jsonError("There are no problems available for that date", "Dates are available from 2015-11-02 onwards until today.")}
    end
end

-- get the answer for any specific date
app:get("/api/v1/problems/:date", function(self)
    -- TODO: actually check if date is in the right format and error gracefully if it isnt
    return getProblem(self.params.date)
end)

-- setup that homepage yo
app:match("/", function(self)
    self.title = "DailyMath - a new math problem every weekday!"
    self.mainPage = true
    return { render = "index" }
end)

app:match("about", "/about", cached(function(self)
    self.title = "DailyMath - About"
    return { render = true }
end))

app:get("feedback", "/feedback", function(self)
    self.title = "DailyMath - Feedback"
    self.recaptchaRequired = true
    self.csrf_token = csrf.generate_token(self)
    return { render = "feedback" }
end)

app:post("feedback", "/feedback", capture_errors(function(self)
  -- for i, v in pairs(self.req) do print(i,v) end
  csrf.assert_token(self)
  local result, code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
    secret = config.googleSecret,
    response = self.params['g-recaptcha-response']
  })
  assert(code == 200)
  -- convert result string to json
  local jsonResult = from_json(result)
  assert(jsonResult.success)
  return "The form is valid!"
end))

return app
