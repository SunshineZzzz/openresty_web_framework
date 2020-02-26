-- 封装对request的操作

local ngx_re_find = ngx.re.find
local pairs = pairs
local setmetatable = setmetatable
local utils = require("framework.lib.utils.utils")
local is_table = utils.is_table
local json = require("framework.lib.utils.json")

local Request = {}

-- 创建Request对象
function Request:new()
	-- body params
	local body = {}
	-- Returns a Lua table holding all the current request headers.
	local headers = ngx.req.get_headers()

	local header = headers['Content-Type']
	-- the post request have Content-Type header set
	-- 关于POST类型，看这里https://www.jianshu.com/p/53b5bd0f1d44
	if header then
		if ngx_re_find(header, "application/x-www-form-urlencoded", "jo") then
			ngx.req.read_body()
			local post_args = ngx.req.get_post_args()
			if post_args and is_table(post_args) then
				for k, v in pairs(post_args) do
					body[k] = v
				end
			end
		elseif ngx_re_find(header, "application/json", "jo") then
			ngx.req.read_body()
			local json_str = ngx.req.get_body_data()
			body = json.json_decode(json_str)
		-- form-data request
		elseif ngx_re_find(header, "multipart", "jo") then
			-- upload request, should not invoke ngx.req.read_body()
			-- parsed as raw by default
		else
			ngx.req.read_body()
			body = ngx.req.get_body_data()
		end
	-- the post request have no Content-Type header set will be parsed as x-www-form-urlencoded by default
	else
		ngx.req.read_body()
		local post_args = ngx.req.get_post_args()
		if post_args and is_table(post_args) then
			for k, v in pairs(post_args) do
				body[k] = v
			end
		end
	end

	local instance = {
		-- 请求的URI，可能和最初的值有不同，比如经过重定向之类的
		path = ngx.var.uri,
		-- Retrieves the current request's request method name. 
		method = ngx.req.get_method(),
		-- Returns a Lua table holding all the current request URL query arguments.
		query = ngx.req.get_uri_args(),
		-- 请求的URI，带参数
		url = ngx.var.request_uri,
		-- request header
		headers = headers,
	}
	
	setmetatable(instance, {__index = self})
	return instance
end

return Request