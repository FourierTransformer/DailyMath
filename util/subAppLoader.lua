--[[

    subAppLoader.lua

    allows you to load files with routes into a lapis application

]]

-- Internal class constructor from Yonaba
local class = function(...)
  local klass = {}
  klass.__index = klass
  klass.__call = function(_,...) return klass:new(...) end
  function klass:new(...)
    local instance = setmetatable({}, klass)
    klass.__init(instance, ...)
    return instance
  end
  return setmetatable(klass,{__call = klass.__call})
end

local subApp = class()
function subApp:__init(name)
    self.name = name
    self.gets = {}
    self.posts = {}
end

function subApp:post(name, route, returnFunction)
	self.posts[#self.posts + 1] = {name, route, returnFunction}
end

function subApp:get(name, route, returnFunction)
	self.gets[#self.gets + 1] = {name, route, returnFunction}
end

function subApp.loadSubApps(app, subApps)
	for _, subApp in ipairs(subApps) do
		for i = 1, #subApp.gets do
			local currentSubApp = subApp.gets[i]
			app:get(currentSubApp[1], currentSubApp[2], currentSubApp[3])
		end
		for i = 1, #subApp.posts do
			local currentSubApp = subApp.posts[i]
			app:post(currentSubApp[1], currentSubApp[2], currentSubApp[3])
		end
	end
end

return subApp
