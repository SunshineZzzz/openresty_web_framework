-- 封装对debug的相关操作

local config = require("app.config.config")
local config_debug = config.app_debug
local utils = require("framework.lib.utils.utils")
local is_function, is_table = utils.is_function, utils.is_table
local pcall = pcall
local pairs = pairs
local json = require("framework.lib.utils.json")

local function app_debug(...)
	if not config_debug then
		return
	end

	local info = { ... }
	if info and is_function(info[1]) then
		pcall(info[1])
	elseif info and is_table(info[1]) then
		for i, v in pairs(info[1]) do
			ngx.log(ngx.DEBUG, i .. "," .. v)
		end
		-- 就不递归了
	elseif ... ~= nil then
		ngx.log(ngx.DEBUG, json.encode(info))
	else
		ngx.log(ngx.ERR, "app_debug not works...")
	end
end

return app_debug
