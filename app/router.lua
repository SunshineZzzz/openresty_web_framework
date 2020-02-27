local testController = require("app.controllers.test")

local function router(app)
	-- 测试用的啊
	testController(app)

	-- 主页
	app:get("/", function(app, req, res, prms)
		local data = {
			desc =  "This is An OpenResty Lua MVC Web Framework."
		}
		res:render("index", data)
		
		return true
	end)
end

return router