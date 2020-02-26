-- 封装对View的操作

local pairs = pairs
local type = type
local setmetatable = setmetatable
local tostring = tostring
local template = require("resty.template")
local template_new = template.new

local View = {}

-- 创建模板渲染对象
function View:new(view_config)
	local instance = {}
	instance.view_enable = view_config.view_enable
	if instance.view_enable then
		--[[
			https://github.com/bungle/lua-resty-template
			When lua-resty-template is used in context of Nginx / OpenResty 
			there are a few configuration directives that you need to be aware:
				template_root (set $template_root /var/www/site/templates)
				template_location (set $template_location /templates)
			If none of these are set in Nginx configuration, 
			ngx.var.document_root (aka root-directive) value is used. 
			If template_location is set, it will be used first, 
			and if the location returns anything but 200 as a status code, 
			we do fallback to either template_root (if defined) or document_root.
		]]
		if ngx.var.template_root then
			ngx.var.template_root = view_config.views
		else
			ngx.log(ngx.ERR, "$template_root is not set in nginx.conf")
		end
	end

	-- 模板文件后缀
	instance.view_ext = view_config.view_ext
	-- 模板布局文件
	instance.view_layout = view_config.view_layout
	-- 模板文件目录
	instance.views = view_config.views
	-- 是否缓存
	instance.view_cache = view_config.enable_view_cache
	template.caching(instance.view_cache)

	setmetatable(instance, {__index = self})
	return instance
end

-- 渲染
function View:render(view_file, data)
	if not self.view_enable then
		ngx.log(ngx.ERR, "view is not enabled. you may need `app:conf('view enable', true)`")
	else
		local view_file_name = view_file .. "." .. self.view_ext
		local layout_file_name = self.view_layout .. "." .. self.view_ext

		local t = template_new(view_file_name)
		if self.view_layout ~= "" then
			t = template_new(view_file_name, layout_file_name)
		end
		
		if data and type(data) == "table" then
			for k, v in pairs(data) do
				t[k] = v
			end
		end

		return tostring(t)
	end
end

return View