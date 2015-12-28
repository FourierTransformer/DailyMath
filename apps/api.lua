--[[

    api.lua

    Gota keep track of that API.
    Which, at the moment deals with the following:
        Problem retrieval

]]

-- get our caching func!
local cached = require("lapis.cache").cached

-- gotta handle some of our shared date functions!
local dateFunctions = require("util.dateFunctions")

-- and some magic functions here
local problems = require("util.problems")

-- our submodule loader and subApp
local subApp = require("util.subAppLoader")
local api = subApp:new()

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
        -- the 'true' means get the nearest date
        local ok, query = problems.getProblem(self.params.date, true)

        -- return as necessary
        if ok then
            return {layout = false, json = query}
        else
            return query
        end

    end
}))

return api