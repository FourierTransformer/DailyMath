--[[

    email.lua

	provides functionality to use the mailgun api to send emails

]]

-- http stuffs
local ltn12 = require("ltn12")
local http = require("lapis.nginx.http")
local util = require("lapis.util")
local encoding = require("lapis.util.encoding")

-- configs
local config = require("lapis.config").get()

-- utility object
local email = {}

-- https request handler
local function httpRequest(url, method, header, data)
    --handle when no data/header is sent in
    local data = data or ""
    local header = header or {}

    -- create a string out of data
    local source = ltn12.source.string(data)

    -- create a response table
    local response = {}
    local save = ltn12.sink.table(response)

    -- add datasize to header
    local dataSize = data:len()
    local sizeHeader = header
    sizeHeader["content-length"] = dataSize

    -- REQUEST IT!
    ok, code, headers, status = http.request{
        url = url,
        method = method,
        headers = sizeHeader,
        source = source,
        sink = save,
        protocol = "tlsv1",
        options = "all",
        verify = "none" -- not entirely sure if this is what i want...
    }

    if code ~= 200 then
        print("Error Code:", code, table.concat(response, "\n\n\n"))
        print(url)
        print(data)
    end

    return table.concat(response)
end

local function sendEmail(to, from, subject, message)
	local mailAuthHeader = {
	    ["Content-Type"] = "application/x-www-form-urlencoded",
	    ["authentication"] = "Basic " .. encoding.encode_base64("api:" .. config.mailgunAPIKey)
	}

	local mailData = {
	    ["to"] = to,
	    ["from"] = from,
	    ["subject"] = subject,
	    ["text"] = message
	}
	httpRequest("https://api.mailgun.net/v3/" .. config.email.mailDomain .. "/messages", "POST", mailAuthHeader, util.encode_query_string(mailData))
end

function email.sendFeedback(to, message)
	sendEmail(to, config.email.feedbackEmail, "DailyMath Feedback", message)
end

return email
