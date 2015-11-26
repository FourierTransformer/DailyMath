--[[

    api.lua

    Gota keep track of that API.
    Which, at the moment deals with the following:
        json error handling
        Problem retrieval

]]


-- and lapis.db to access the database
local db = require("lapis.db")

-- get our caching func!
local cached = require("lapis.cache").cached

-- gotta handle some of our shared date functions!
local dateFunctions = require("util.dateFunctions")

local json = require("cjson")

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
    if dateFunctions.verifyFormat(date) == false then
        return {status = 404, layout = false, json = jsonError("The date string is not properly formatted", "The date string should follow 'YYYY-MM-DD.'")}
    end

    -- ensure that it's within the "today" bounds anywhere around the globe.
    if dateFunctions.validDate(date) == false then
        return {status = 404, layout = false, json = jsonError("That date has not occurred yet", "Valid dates go between 2015-11-02 and today")}
    end

    -- query the database!
    -- NOTE: the "ORDER BY" is only in here because I wrote some bad js
    -- that assumes high school always comes first...
    local query = db.query([[SELECT problem, categories.type category, level, answer, hint, answer_desc, date, name, solution_methods.type solution_method, solution_json
                            FROM problems 
                            LEFT OUTER JOIN categories ON (problems.category_id = categories.id)
                            LEFT OUTER JOIN solution_methods ON (problems.solution_id = solution_methods.id)
                            WHERE date = (SELECT date FROM problems where date <= ? ORDER BY date DESC LIMIT 1)
                            ORDER BY level]], date)

    for _, problem in ipairs(query) do

        --expand it!
        problem.date = dateFunctions.expandDate(problem.date)

        -- the solution section includes things that for problem verification only. 
        problem.solution = {
            ["answer"] = problem.answer,
            ["method"] = problem.solution_method,
            ["json"] = problem.solution_json
        }
        problem.answer = nil
        problem.solution_method = nil

    end

    -- return as necessary
    if query ~= nil and query[1] ~= nil then
        return {layout = false, json = {problems = query}}
    else
        return {status = 404, layout = false, json = jsonError("There are no problems available for that date", "Dates are available from 2015-11-02 onwards until today.")}
    end
end

-- minor issue is when someone selects a problem that's available in Kiritimati but
-- I haven't put it in the database yet... temp fix using 6 hour cache time
-- this should be a little more thought out than this. But for now this is great!
local function cacheDate(request)
    return dateFunctions.validDate(request['url_params'].date)
end

-- get the answer for any specific date
api:get("/api/v1/problems/:date", cached({
    when = cacheDate,
    exptime = 21600, -- 6 hours until i can get that cachedate up to par
    function(self)
        return getProblem(self.params.date)
    end
}))

return api