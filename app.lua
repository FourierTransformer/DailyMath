--[[

    app.lua

    The main code for DailyMath. This guy runs the show!

]]

-- setup lapis and get our configuration
local lapis = require("lapis")
local app = lapis.Application()
local config = require("lapis.config").get()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- get some caching up in here!
local cached
if config._name == "development" then
	function cached(func) return func end
else
	cached = require("lapis.cache").cached
end

-- sometimes you just need to get some stuff
local resty = require("resty.core.base64")
local problems = require("util.problems")
local subApp = require("util.subAppLoader")
local json = require("cjson")

-- load all our subApps
local subApps = {
    require("apps.feedback"),
    require("apps.api"),
    require("apps.admin")
}
subApp.loadSubApps(app, subApps)

-- dateFunctions
local dateFunctions = require("util.dateFunctions")

-- setup that homepage yo
app:match("/", cached(function(self)
    self.title = "DailyMath - a new math problem 3x a week!"
    self.definedDate = ""
    self.mainPage = true
    return { render = "index" }
end))

-- handle individual problems
app:get("/p/:date", cached(function(self)
    self.isomorphic = true
    local ok, query = problems.getProblem(self.params.date)
    if ok then
        self.problem = query.problems[1]
        self.title = "DailyMath - " .. query.problems[1].name
        self.date = query.dateInfo
        self.jsonPayload = ngx.encode_base64(json.encode(query))
        if query.dateInfo.next then self.next = "pseudo" else self.next = "disabled" end
        if query.dateInfo.previous then self.previous = "pseudo" else self.previous = "disabled" end
        return { render = "isomorphic" }
    else
        self.errorTitle = query.json.errors.title
        self.errorDetail = query.json.errors.detail
        return { render = "404" }
    end
end))

app:match("about", "/about", cached(function(self)
	self.title = "DailyMath - About"
	return { render = true }
end))

app:match("thanks", "/thank-you", cached(function(self)
	self.title = "DailyMath - Thanks!"
	return { render = true }
end))

return app
