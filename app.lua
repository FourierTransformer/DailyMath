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

-- setup that homepage yo
app:match("/", function(self)
    self.title = "DailyMath - a new math problem every weekday!"
    self.mainPage = true
    return { render = "index" }
end)

return app
