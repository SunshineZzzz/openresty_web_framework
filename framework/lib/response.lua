-- 封装对response的操作

local pairs = pairs
local tostring = tostring
local setmetatable = setmetatable
local table_insert = table.insert
local table_concat = table.concat
local json = require("framework.lib.utils.json")
local utils = require("framework.lib.utils.utils")
local is_table, is_number = utils.is_table, utils.is_number

local Response = {}

-- 创建Response对象
function Response:new()
	local instance = {
		-- 状态
		http_status = nil,
		-- Response headers
		headers = {},
		-- Response body
		body = "--default body. you should not see this by default--",
		-- 模板渲染对象
		view = nil
	}

	setmetatable(instance, { __index = self })
	return instance	
end

-- 模板渲染
function Response:render(view_file, data)
	if not self.view then
		ngx.log(ngx.ERR, "`view` object is nil, maybe you disabled the view engine.")
		error("`view` object is nil, maybe you disabled the view engine.")
	else
		self:set_header("Content-Type", "text/html; charset=UTF-8")
		data = data or {}
		local body = self.view:render(view_file, data)
		self:_send(body)
	end
end

-- 返回html
function Response:html(data)
	self:set_header('Content-Type', 'text/html; charset=UTF-8')
	self:_send(data)
end

-- 返回json
function Response:json(data)
	self:set_header('Content-Type', 'application/json; charset=utf-8')
	local rData, err = json.encode(data)
	if err then
		ngx.log(ngx.ERR, "Response json encode err ", err)
		error("Response json encode err " .. err)	
		return
	end
	self:_send(rData)
end

-- 301/302重定向
-- 301 - 永久跳转
-- 302 - 临时跳转
function Response:redirect(url, code, query)
	if url and not code and not query then
		-- 默认302
		ngx.redirect(url)
	elseif url and code and not query then
		if is_number(code) then
			ngx.redirect(url, code)
		elseif is_table(code) then
			query = code
			local q = {}
			-- 是否存在url参数
			local is_q_exist = false
			if query and is_table(query) then
				for i, v in pairs(query) do
					table_insert(q, i .. "=" .. v)
					is_q_exist = true
				end
			end

			if is_q_exist then
				url = url .. "?" .. table_concat(q, "&")
			end

			ngx.redirect(url)
		else
			ngx.redirect(url)
		end
	else
		local q = {}
		local is_q_exist = false
		if query and is_table(query) then
			for i,v in pairs(query) do
				table_insert(q, i .. "=" .. v)
				is_q_exist = true
			end
		end

		if is_q_exist then
			url = url .. "?" .. table_concat(q, "&")
		end

		ngx.redirect(url ,code)
	end
end

-- rewrite
function Response:location(url, data)
	if data and is_table(data) then
		ngx.req.set_uri_args(data)
		-- false 等价于 rewrite ^ url break;
		-- true 等价于 rewrite ^ url last;
		ngx.req.set_uri(url, false)
	else
		-- ngx.say(url)
		ngx.req.set_uri(url, false)
	end
end

-- 发送文本
function Response:send(text)
	self:set_header('Content-Type', 'text/plain; charset=UTF-8')
	self:_send(text)
end

-- raw send
function Response:_send(content)
	ngx.status = self.http_status or ngx.HTTP_OK
	ngx.say(content)
end

-- body
function Response:get_body()
	return self.body
end

-- headers
function Response:get_headers()
	return self.headers
end

-- header[key]
function Response:get_header(key)
	return self.headers[key]
end

-- set body
function Response:set_body(body)
	if body ~= nil then 
		self.body = body 
	end
end

-- set status
function Response:status(status)
	ngx.status = status
	self.http_status = status
	return self
end

-- 设置header
function Response:set_header(key, value)
	ngx.header[key] = value
end

return Response