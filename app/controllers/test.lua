local tonumber = tonumber
local json = require("framework.lib.utils.json")
local config = require("app.config.config")
local utils = require("framework.lib.utils.utils")
local is_empty = utils.is_empty

-- get /test
local function get_test(app, req, res, prms)
	return true
end

local function init(app)
	app:get("/test", get_test)
end

return init