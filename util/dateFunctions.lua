--[[

    dateFunctions.lua

    Just a file to help with some of the date functions that may be needed

]]

local dateFunctions = {}
local date = require("date")

local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
local numberEnds = {"st", "nd", "rd"}

-- date will always come in as YYYY-MM-DD
function dateFunctions.expandDate(dateString)
    -- month string
    local expanded = months[tonumber(string.sub(dateString, 6,7))] .. " "

    -- day number (WITH CORRECT ENDINGS!)
    expanded = expanded .. tonumber(string.sub(dateString, 9, 10)) --minor hack to have dates with 1 digit
    local lastNumber = numberEnds[tonumber(string.sub(dateString, 10, 10))] or "th"
    expanded = expanded .. lastNumber .. ", "

    -- year
    expanded = expanded .. string.sub(dateString, 1, 4)

    return expanded
end

-- ensure that the date is in YYYY-MM-DD format
function dateFunctions.verifyFormat(dateString)
    local dateObject
    if dateString:len() == 10 or string.match(dateString, "%d%d%d%d%-%d%d%-%d%d") then
        dateObject = date(dateString)
        if dateObject == nil then
            return false
        end
        return true, dateObject
    end
    return false
end

-- check to see if tomorrow has happened on earth yet.
-- this is for you Kiritimati (+14 UTC)
local function hasTomorrowOccured()
    local now = os.time()
    local currentTimeZone = os.difftime(now, os.time(os.date("!*t", now)))/3600
    local KiritimatiTimeDifference
    if currentTimeZone < 0 then
        KiritimatiTimeDifference = -currentTimeZone + 14
    else
        KiritimatiTimeDifference = 14 - currentTimeZone
    end

    -- os.date("%H") returns the hour of the day and goes form 00-23
    local timeAdjust = os.date("%H") + KiritimatiTimeDifference
    if timeAdjust >= 24 then
        return true, 1
    else
        return false
    end
end

function dateFunctions.validDate(dateString)
    -- just making sure it's coming in the expected format
    local verifyFormat, selectedDate = dateFunctions.verifyFormat(dateString)
    if verifyFormat == false then
        return false
    end
    
    -- figure out if we should compare today or tomorrow
    local dateToCompare
    local tomorrow, numDays = hasTomorrowOccured()
    if tomorrow then
        dateToCompare = date(true):adddays(numDays)
    else
        dateToCompare = date(true)
    end

    if selectedDate <= dateToCompare then
        return true
    else
        return false
    end

end

return dateFunctions