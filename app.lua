local lapis = require("lapis")
local app = lapis.Application()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- and db to access the database layer
local db = require("lapis.db")

-- setup that homepage yo
app:match("/", function(self)
    self.title = "DailyMath - a new math problem every weekday!"
    return { render = "index" }
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
