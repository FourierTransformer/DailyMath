--[[

    problems.lua

    A sort of internal API.
        Can retrive a problem that'll return a json-friendly table if thre's an error

]]

-- things we need!
local dateFunctions = require("util.dateFunctions")
local db = require("lapis.db")

-- define it.
local problems = {}

-- makes the json errors consistent
local function jsonError(titleText, detailText)
    return {
        errors = {
            title = titleText,
            detail = detailText
        }
    }
end

-- if selectLatest then it'll return the latest problem up to the date given
-- otherwise it returns the exact problem. This is needed to make the homepage
-- return the correct problem (as the js takes into account the user's current date)
function problems.getProblem(date, selectLatest)
    -- either use the submitted date or today's date
    local whereDate
    if selectLatest then
        whereDate = "(SELECT date FROM problems where date <= ? ORDER BY date DESC LIMIT 1) ORDER BY level"
    else
        whereDate = "?"
    end
    local date = date or os.date("%F")

    -- do some quick validation on the date
    if dateFunctions.verifyFormat(date) == false then
        return false, {status = 404, layout = false, json = jsonError("The date string is not properly formatted", "The date string should follow 'YYYY-MM-DD' and be a real date on the Gregorian calendar")}
    end

    -- ensure that it's within the "today" bounds anywhere around the globe.
    if dateFunctions.validDate(date) == false then
        return false, {status = 404, layout = false, json = jsonError("That date is not valid", "Valid dates go between 2015-11-23 and today")}
    end

    -- query the database!
    -- NOTE: the "ORDER BY" is only in here because I wrote some bad js
    -- that assumes high school always comes first...
    local query = db.query([[SELECT problem, categories.type category, level, answer, hint, answer_desc, date, name, solution_methods.type solution_method, correct_message
                            FROM problems 
                            LEFT OUTER JOIN categories ON (problems.category_id = categories.id)
                            LEFT OUTER JOIN solution_methods ON (problems.solution_id = solution_methods.id)
                            WHERE date = ]] .. whereDate, date)

    if query and query[1] then
        date = query[1].date
    else
        -- ruh roh. looks like there's no problem for that in the database
        return false, {status = 404, layout = false, json = jsonError("Date not in database","The date " .. date .. " doesn't exist in the database. Please try another date")}
    end

    local prev_next = db.query([[SELECT distinct on (date) date, previous, next
                                from (
                                    select distinct date, lag(date) OVER date_order AS previous, lead(date) OVER date_order AS next
                                    from problems
                                    WINDOW date_order AS (
                                        ORDER BY date asc
                                    )
                                ) AS laggyleader
                                WHERE date = ?]], date)

    -- add some stuff to the problems
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

    return (query ~= nil and query[1] ~= nil), {problems = query, dateInfo = prev_next[1]}

end

return problems
