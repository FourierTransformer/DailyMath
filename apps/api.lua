--[[

    api.lua

    Gota keep track of that API.
    Which, at the moment deals with the following:
        json error handling
        Problem retrieval

]]


-- and lapis.db to access the database
local db = require("lapis.db")

-- our submodule loader and subApp
local subApp = require("util.subAppLoader")
local api = subApp:new()

-- makes the json errors consistent
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
api:get("/api/v1/problems/:date", function(self)
    -- TODO: ensure that the date is within 24 hours of the problem.
    return getProblem(self.params.date)
end)

api:get("about", "/about", function(self)
    self.title = "DailyMath - About"
    return { render = true }
end)

return api