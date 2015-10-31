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
    return "The form is valid!"
end))

return feedback