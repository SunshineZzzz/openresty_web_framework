-- 封装对Application的操作

local assert = assert
local xpcall = xpcall
local setmetatable = setmetatable
local router = require("framework.lib.router")
local request = require("framework.lib.request")
local response = require("framework.lib.response")
-- http support methods
local methods = require("framework.lib.methods")
local version = require("framework.version")
local view = require("framework.lib.view")
local utils = require("framework.lib.utils.utils")
local sprintf = utils.sprintf

local App = {}

-- 创建application对象
function App:new()
	local instance = {
		-- 版本
		version = version,
		-- 配置
		settings = {},
		-- 路由
		router = router:new(),
	}

	setmetatable(instance, {
		__index = self,
		__call = self.handle
	})

	-- 初始化路由注册函数
	instance:init_method()
	return instance
end

-- 运行
function App:run()
	local request = request:new()
	local response = response:new()

	local view_enable = self:get_conf("view_enable")
	if view_enable then
		local view_config = {
			view_enable = view_enable,
			view_ext = self:get_conf("view_ext"),
			view_layout = self:get_conf("view_layout"),
			views = self:get_conf("views"),
			enable_view_cache = self:get_conf("view_cache"),
		}

		local view = view:new(view_config)
		response.view = view
	end

	self:handle(request, response)
end

-- 初始化
function App:init(config)
	self:configuration(config)
end

-- 配置
function App:configuration(config)
	self:conf("backend", true)
	if not config.backend_mq_enable then
		self:conf("backend", false)
	end

	config = config or {view_config={}}

	if config.view_enable ~= nil and config.view_enable == true then
		self:conf("view_enable", true)
	else
		self:conf("view_enable", false)
	end

	self:conf("view_ext", config.view.view_ext or "html")
	self:conf("view_layout", config.view.view_layout or "")
	self:conf("views", config.view.views or "./app/views/")

	if config.view.cache ~= nil and config.view.cache == true then
		self:conf("view_cache", true)
	else
		self:conf("view_cache", false)
	end
end

-- 处理路由匹配
function App:handle(request, response)
	local router = self.router

	if not router then
		return false, "no router!"
	end

	local fin_err
	local ept, ok, err
	ept, ok, err = xpcall(
	function()
		-- return true|false, [err]
		return router:handle(self, request, response)
	end, 
	function(err)
		fin_err = err
	end)

	if ept == true and not ok then
		fin_err = err or "no error msg"
	end

	if fin_err then
		ngx.log(ngx.ERR, sprintf("router:handle() %s error: %s", request.path, fin_err))
		return false, fin_err
	end

	return true
end

-- 初始化method路由注册函数
function App:init_method()
	for http_method, _ in pairs(methods) do
		self[http_method] = function(self, path, handler)
			local ok, err = self.router:add_route(http_method, path, handler)
			if err then
				ngx.log(ngx.ERR,  sprintf("router:add_route(%s, %s, handler) error: %s", http_method, path, err))
			end
			return ok, err
		end
	end
end

-- 给所有method增加路由
function App:all(path, handler)
	self.router:all(path, handler)
	return self
end

-- 注册中间件
function App:middle(fname, func)
	local ok, err = self.router:middle(fname, func)
	if err then
		ngx.log(ngx.ERR,  sprintf("router:middle(%s, func) error: %s", fname, err))
	end
	return ok, err
end

-- 设置指定配置的value
function App:conf(setting, val)
	self.settings[setting] = val
	return self
end

-- 获取指定配置的value
function App:get_conf(setting)
	return self.settings[setting]
end

return App