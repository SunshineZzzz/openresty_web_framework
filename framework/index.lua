-- 创建Application

local Application = require("framework.lib.application")

local function CreateApplication(options)
	local app = Application:new()
	app:init(options)

	return app
end

return CreateApplication