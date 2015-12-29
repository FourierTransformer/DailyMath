--[[

    dateFunctions.lua

    Just a file to help with some additional date functions that may be needed

]]

local dateFunctions = {}
local date = require("date")

local months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
local numberEnds = {"st", "nd", "rd"}

-- date will always come in as YYYY-MM-DD
function dateFunctions.expandDate(dateString)
    -- month string
    local expanded = months[tonumber(string.sub(dateString, 6,7))] .. " "

    -- day number (WITH CORRECT ENDINGS!)
    expanded = expanded .. tonumber(string.sub(dateString, 9, 10)) --minor hack to have dates with 1 digit
    local lastNumber

    -- handling the specials 10's case: 10th, 11th, 12th, 13th...
    if (string.sub(dateString, 9, 9) == "1") then
        lastNumber = "th"
    else
        lastNumber = numberEnds[tonumber(string.sub(dateString, 10, 10))] or "th"
    end
    expanded = expanded .. lastNumber .. ", "

    -- year
    expanded = expanded .. string.sub(dateString, 1, 4)

    return expanded
end

-- ensure year is valid
local function checkDate(dateString)
    local year = tonumber(string.sub(dateString, 1, 4))
    local month = tonumber(string.sub(dateString, 6, 7))
    local date = tonumber(string.sub(dateString, 9, 10))

    if month < 1 or month > 12 then return false end;
    
    -- leap years - I tell ya...
    -- I really like how this cascade looks!
    if month == 2 then
        days[2] = 28
        if year % 4 == 0 then
            days[2] = 29
            if year % 100 == 0 then
                days[2] = 28
                if year % 400 == 0 then
                    days[2] = 29
                end
            end
        end
    end

    if date <= days[month] then
        return true
    end

    return false

end

-- ensure that the date is in YYYY-MM-DD format
function dateFunctions.verifyFormat(dateString)
    local dateObject
    if string.match(dateString, "^%d%d%d%d%-%d%d%-%d%d$") then
        if checkDate(dateString) == false then return false end
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
    
    -- make sure it's before the first problem's date!
    if selectedDate < date("2015-11-23") then return false end

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