--[[

    sitemap.lua

    Let's make a sitemap!

]]

-- load some stuff!
local cached = require("lapis.cache").cached
local db = require("lapis.db")

local subApp = require("util.subAppLoader")
local sitemap = subApp:new()

-- get the answer for any specific date
sitemap:get("/sitemap.xml", cached({
    exptime = 86400,
    function(self)
        local dates = db.select("date from problems;")
        self.problems = {}
        self.build_url = self:build_url()
        self.res.headers["Content-Type"] = "application/xml; charset=utf-8"
        for _, v in ipairs(dates) do
            self.problems[#self.problems + 1] = self.build_url .. "/p/" .. v.date
        end
        return { layout = "sitemap.index" }
    end
}))

return sitemap