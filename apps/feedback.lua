--[[

    feedback.lua

    Everything that has to do with the feedback form is in here!

]]

-- csrf for form validation yo and let's capture some errors?!
local csrf = require("lapis.csrf")
local capture_errors = require("lapis.application").capture_errors

-- verify that recaptcha yo
local http = require("lapis.nginx.http")
local from_json = require("lapis.util").from_json

-- configs
local config = require("lapis.config").get()

-- let's send some email!
local email = require("util.email")

-- our submodule loader and subApp
local subApp = require("util.subAppLoader")
local feedback = subApp:new()

-- main feedback page
feedback:get("feedback", "/feedback", function(self)
    self.title = "DailyMath - Feedback"
    self.recaptchaRequired = true
    self.csrf_token = csrf.generate_token(self)
    return { render = "feedback" }
end)

--verify the feedback
feedback:post("feedback", "/feedback", capture_errors(function(self)
    csrf.assert_token(self)
    local result, code, headers = http.simple("https://www.google.com/recaptcha/api/siteverify", {
        secret = config.googleSecret,
        response = self.params['g-recaptcha-response']
    })
    assert(code == 200)
    -- convert result string to json
    local jsonResult = from_json(result)
    assert(jsonResult.success)

    -- sorry this looks a little gross. I blame string formatting
    if self.params['email'] and self.params['email'] ~= "" then

        -- just ensuring it's a real email before sending it out
        if self.params['email']:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") then
            
            -- might as well thank the person by name if we can!
            local thanks = "Thanks"
            if self.params['name'] and self.params['name'] ~= "" then thanks = thanks .. " " .. self.params['name'] end
            
            -- send an email to them, so they know we got their feedback
            email.sendFeedback(self.params['email'],
thanks .. [[ for the feedback!
--The DailyMath Team

--------------------
Please Do Not Respond to this Email.
We'll reach out if we have to!
]])
        end
    end

    -- also send the email to me!
    email.sendFeedback(config.adminEmail, 
        "Name: " .. self.params['name'] .. "\n" ..
        "Email: " .. self.params['email'] .. "\n\n" ..
        "Feedback: " .. self.params['feedback']
        )

    -- email.sendFeedback("shakil.thakur@gmail.com", )
    return { redirect_to = self:url_for("thanks") }
end))

return feedback