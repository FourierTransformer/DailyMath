local lapis = require("lapis")
local app = lapis.Application()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- get some caching up in here!
local cached = require("lapis.cache").cached

-- our utility to load subapps
local subApp = require("util.subAppLoader")

-- load all our subApps
local subApps = {
    require("apps.feedback"),
    require("apps.api")
}
subApp.loadSubApps(app, subApps)

-- dateFunctions
local dateFunctions = require("util.dateFunctions")

-- setup that homepage yo
app:match("/", function(self)
    self.title = "DailyMath - a new math problem every weekday!"
    self.definedDate = ""
    self.mainPage = true
    return { render = "index" }
end)

app:match("/p/:date", function(self)
	local date = self.params.date
	if dateFunctions.verifyFormat(date) == false then
		self.title = "DailyMath - 404 Not Found"
		self.errorTitle = "The date is formatted incorrectly"
		self.errorDetail = "The date in the URL should follow the pattern /p/YYYY-MM-DD."
		return {status = 404, render = "404"}
	else
		self.title = "DailyMath - " .. date
		self.definedDate = date
		self.mainPage = true
		return { render = "index"}
	end
end)

app:match("about", "/about", cached(function(self)
    self.title = "DailyMath - About"
    return { render = true }
end))

return app
