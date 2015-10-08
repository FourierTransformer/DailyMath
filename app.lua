local lapis = require("lapis")
local app = lapis.Application()

-- enable etlua and set the base template
app:enable("etlua")
app.layout = require("views.baseLayout")

-- bcrypt for encryption
local bcrypt = require("bcrypt")

-- and db to access the database layer
local db = require("lapis.db")


function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

local function verifyLogin(username, password)
    local dbPassword = db.query("SELECT password FROM users WHERE displayname = ?", username)
    local verified = bcrypt.verify(password, dbPassword[1].password)
    password = nil
    return verified
end


app:match("/", function(self)
    self.title = "dailyMath - Where a Problem a Day Keeps Alzheimer's at Bay!"
    self.text = db.query("SELECT problem FROM problems where date = ?", os.date())[1].problem
    return { render = "hello" }
    --return "Welcome to DailyMath" .. tostring(verifyLogin("admin", "MMG8Z9b4qQuZrpDy")) .. bcrypt.digest("PAUL", 4)
end)

app:match("about", "/about", function(self)
  return { render = true }
end)



return app
