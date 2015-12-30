--[[

    patch-database.lua

    This code will patch a database for you! Make sure you are logged in as the
    database superuser (usually "postgres") before executing this script and
    that you are in the "database" directory!

    Note: It'll only patch things for the current major database release. I
    still need to write a script for upgrading major database versions. I'll
    get to it, when I get to it!

    It's somewhat interactive. Call it via:
    lua patch-database.lua [DATABASE]

]]

-- see if peeps are asking for help
if arg[1] == "-h" or arg[1] == "--help" then print("lua patch-database.lua [DATABASE]") return end

-- setup the configuration
local config = {
	psql = "psql",
	database = arg[1]
}

if not config.database then print("Please pass in a database name: lua patch-database.lua [DATABASE]") return end

-- this is just for easy output during development
-- local json = require("cjson")

-- LOGGING YO
file = io.open(os.date("%F") .. "--" .. os.date("%X"):gsub(":", "_") .. ".log", "a")
io.output(file)

-- this is a little dicey! But writing a logfile is a must!
local function print(...)
	local printResult = ""
	for i,v in ipairs({...}) do
		printResult = printResult .. tostring(v) .. "\t"
	end
	printResult = printResult .. "\n"
	io.write(printResult)
	io.stdout:write(printResult)
end

-- there ain't no string splitting in lua!
function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

-- a quick 'n dirty user prompt (y/n)
local function promptUser(query)
	local answer
	repeat
	   io.stdout:write(query .. " (y/n) ")
	   io.stdout:flush()
	   answer=io.read()
	until answer=="y" or answer=="n"
	return answer == "y"
end

-- a wrapper of io.popen
local function execute(command, printOutput)
	-- we don't always need to print out to the command prompt!
	local printOutput = printOutput
	if printOutput == nil then printOutput = true end

	-- but we will always print out for the actual command!
	print("\n" .. command)

	-- magic here " 2>&1" outputs stderr to stdout
	local returnValue = io.popen(command .. " 2>&1", "r")

	-- still good for now!
	local weGood = true

	-- sometimes we need the output!
	local output = {}
	for line in returnValue:lines() do
		-- print at times!
		if printOutput then print(line) end

		-- add it to the output
		output[#output+1] = line

		-- this guy only really checks for Postgres errors. It's alright.
		-- Ideally it could return poorly for bad return codes. However,
		-- that's a little hard to do in Lua
		if line:find("ERROR") or line:find("FATAL") then weGood = false end
	end

	-- print it out if we're not good!
	if not weGood then print(table.concat(output, "\n")) end

	return weGood, output
end

-- show some basic connection info
print("Connecting to " .. config.database .. " as " .. os.getenv("USER"))

-- get all the version info from the database
local command = config.psql .. " -d " .. config.database .. " -c 'SELECT * from versions;'"
local ok, outTable = execute(command, false)
if not ok then
	print("\nThere was an error connecting to the database.\n")
	return
end

-- parse out the fields
local fields = outTable[1]:gsub("%s+", ""):split("|")

-- make a table with all the versions
local versions = {}
for i = 3, #outTable do --skips the first row of field names and the second row of "-----" :P
	if outTable[i]:sub(1,1) == "(" then break end
	local version = outTable[i]:gsub("%s+", ""):split("|")

	local index = #versions + 1
	versions[index] = {}
	for j = 2, #fields do
		versions[index][fields[j]] = version[j]
	end
end

-- show the change history and get major release nubmber
print("\nSchema Change History")
local majorRelease = -math.huge
for i = 1, #versions do
	local patchNumber = versions[i].major_release_number .. "." .. versions[i].minor_release_number .. "." .. versions[i].point_release_number
	print(patchNumber, versions[i].script_name, "applied on", versions[i].date_applied)
	if tonumber(versions[i].major_release_number) > majorRelease then
		majorRelease = tonumber(versions[i].major_release_number)
	end
end

print("\nCurrent Major Database Version: ", string.format("%02d", majorRelease))

-- get all available scripts
local availableScripts = {}
local scripts = io.popen("ls -1", "r")
for line in scripts:lines() do
	local majorPatches = "sc." .. string.format("%02d", majorRelease)
	if line:sub(1, 5) == majorPatches then
		availableScripts[line] = {}
		availableScripts[line].installed = false
	end
end

-- run through all the scripts that have been executed in the database
for _, version in pairs(versions) do

	-- check off which ones have been installed
	if availableScripts[version.script_name] then
		availableScripts[version.script_name].installed = true
	end
end

-- figure out which ones still need to be applied
local scriptToApply = {}
for key, script in pairs(availableScripts) do
	if not script.installed then
		table.insert(scriptToApply, key)
	end
end

if #scriptToApply == 0 then
	print("\nThere are no patches to apply\n")
	return
end

-- sort it because we need to apply our patches in order!
table.sort(scriptToApply)

-- show which patches are available
print("\nThe following patches are available:")
for i = 1, #scriptToApply do
	print(scriptToApply[i])
end

local applyPatches = promptUser("\nShould the patches be applied?")

if applyPatches then
	print("Applying patches...")
	for i = 1, #scriptToApply do
		-- run the script!
		local command = config.psql .. " -d " .. config.database .. " -f " .. scriptToApply[i]
		local ok = execute(command)
		if not ok then
			print("\nAn error was found! Please fix it before re-running this script!\n")
			return
		end
		
		-- add the version info to the script
		local scriptNumbers = scriptToApply[i]:split("%.")
		local command = config.psql .. " -d " .. config.database .. " -c " .. [["insert into versions (major_release_number, minor_release_number, point_release_number, script_name) VALUES (']] .. scriptNumbers[2] .. "', '" .. scriptNumbers[3] .. "', '" .. scriptNumbers[4] .. "', '" .. scriptToApply[i] .. [[');"]]
		local ok = execute(command)
		if not ok then
			print("\nAn error was found while trying to add the version info to the database... This shouldn't happen. File a bug at http://github.com/FourierTransformer/DailyMath\n")
			return
		end
		print("\nPatching Completed Successfully!\n")
	end
else
	print("\nYou have elected to not patch. Exiting.\n")
end
