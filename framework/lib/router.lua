-- 封装对router的操作

local setmetatable = setmetatable
local string_len = string.len
local string_byte = string.byte
local string_sub = string.sub
-- local string_gsub = string.gsub
local ngx_re_gsub = ngx.re.gsub
local ngx_re_gmatch = ngx.re.gmatch
local sprintf = string.format
local string_lower = string.lower
-- local string_find = string.find
local ngx_re_find = ngx.re.find
local tostring = tostring
local pcall = pcall
-- http support methods
local methods = require("framework.lib.methods")
-- response
local response = require("framework.lib.response")
-- utils
local utils = require("framework.lib.utils.utils")
local is_function, is_string, is_table = utils.is_function, utils.is_string, utils.is_table
-- list
local list = require("framework.lib.utils.list")
-- 节点类型
local node_type = {
	-- 默认 - 普通节点
	normal = 1,
	-- : - 通配符节点
	wildcard = 2,
	-- *, *.xxx - 捕获全部节点
	catchall = 3,
}

-- 调试打印
local function dump_table(tbl, indent)
	indent = indent or "\t"
	local str = ""
	if not is_table(tbl) then
		return ""
	end

	for k, v in pairs(tbl) do
		if is_table(v) then
			str = str .. indent .. tostring(k) .. " => " .. "{\n"
			str = str .. dump_table(v, indent .. "\t")
			str = str .. indent .. "}\n"
		else
			str = str .. indent .. tostring(k) .. " => " .. tostring(v) .. "\n"
		end
	end

	return str
end

local Router = {}

-- 创建router对象
function Router:new()
	local instance = {
		-- 非固定路由
		routes = {},
		-- 固定路由
		const_routes = {},
		-- 中间件
		middle_list = list:new(),
	}

	return setmetatable(instance, {__index = self})
end

-- 创建节点
function Router:new_child(token)
	if not token then
		return nil
	end

	local c = string_byte(token, 1)
	local n = string_len(token)
	local ntype = node_type.normal

	-- :xxx
	if c == 58 then
		token = string_sub(token, 2)
		ntype = node_type.wildcard
	-- *
	elseif c == 42 and n == 1 then
		ntype = node_type.catchall
	-- *.xxx
	elseif c == 42 and n > 2 and string_byte(token, 2) == 46 then
		ntype = node_type.catchall
	end

	return {
		-- token关键字
		token = token,
		-- 子节点
		childs = {},
		-- 子节点数量
		nchild = 0,
		-- 处理函数
		handler = nil,
		-- 节点类型
		node_type = ntype,
	}
end

-- 注册路由
function Router:add_route(method, route, handler)
	if not method or not route or not handler then
		return false, "method, route, handler can't be empty"
	end

	-- 不允许
	if route == "*" or route == "/*" then
		return false, "root not * or /*"
	end

	if not is_function(handler) and not is_string(handler) then
		return false, sprintf("handler type %s is not allowed", typ)
	end

	if is_string(handler) then
		local ok, handler_or_err = pcall(require, handler)
		if ok == false then
			return false, sprintf("require %s failed, reason: %s", handler, handler_or_err)
		end
		handler = handler_or_err
		if is_table(handler) then
			handler = handler["handle"]
		end
		if is_function(handler) then
			return false, sprintf("handler type %s is not allowed", typ)
		end
	end

	if not self.const_routes[method] then
		self.const_routes[method] = {}
	end

	method = string_lower(method)
	route = string_lower(route)
	route = utils.trim_suffix_slash(route)
	
	local _, nparam = ngx_re_gsub(route, "[:*]", "", "jo")
	-- 没有匹配上 : or *，说明是固定路由
	if nparam == 0 then
		-- 增加固定路由
		self.const_routes[method][route] = handler
		return true, nil
	end

	-- 当前节点
	local cur_node = self.routes[method]
	-- 创建根节点
	if not cur_node then
		cur_node = self:new_child("/")
		if not cur_node then
			return false, "create child / failed"
		end
		self.routes[method] = cur_node
	end

	-- 新建孩子节点
	local child = nil
	local token = nil
	local iterator, err = ngx_re_gmatch(route, "/([^/]+)", "jo")
	if not iterator then
		return false, sprintf("ngx_re_gmatch(%s, \"/([^/]+)\", \"jo\") err: %s", route, err)
	end
	local caps, err = iterator()
	if caps then
		token = caps[1]
	end
	while token and not err do
		if string_len(token) == 0 then
			goto continue
		end

		child = self:new_child(token)
		if not child then
			return false, sprintf("create node %s failed", tostring(token))
		end

		-- 当前结点已经存在通配符子节点
		if cur_node.childs[":token"] then
			-- 当前节点拥有孩子节点，并且孩子节点是通配符节点，
			-- 新建的孩子节点也必须是通配符节点，并且两者的通配符节点token必须相同
			-- 否则出错吧
			-- 即类似 /a/:b 不允许 /a/:c, /a/b, /a/*, /a/*.xx
			-- 必须是 /a/:b
			if child.node_type ~= node_type.wildcard or
			   child.token ~= cur_node.childs[":token"].token then
				return false, "conflicts, while the wildcard param already exists"
			end
		end

		-- 普通节点
		if child.node_type == node_type.normal then
			-- 当前结点的孩子节点里不存在当前结点，就加上吧
			if not cur_node.childs[token] then
				cur_node.childs[token] = child
				cur_node.nchild = cur_node.nchild + 1
				cur_node = child
			-- 已经存在，就用已经存在的子节点
			else
				cur_node = cur_node.childs[token]
			end
		-- 通配符节点
		elseif child.node_type == node_type.wildcard then
			-- 当前节点拥有孩子节点，并且孩子节点是通配符节点，
			-- 当前节点必然只有这一个孩子节点，并且这个孩子必然是通配符节点
			if cur_node.nchild == 1 and cur_node.childs[":token"] and cur_node.childs[":token"].token == child.token then
				cur_node = cur_node.childs[":token"]
			else
				-- 当前结点已经有节点了，不允许
				if cur_node.nchild > 0 then
					return false, "conflicts, nchild > 0 when add wildcard param"
				end
				cur_node.nchild = 1
				cur_node.childs[":token"] = child
				cur_node = child
			end
		end

		-- 下一个
		caps, err = iterator()
		token = nil
		if caps then
			token = caps[1]
		end
	
		-- *不允许出现在路由的中间，只能结尾
		if child.node_type == node_type.catchall and token then
			return false, "`*` shouldn't at the middle of route"
		end

		::continue::
	end

	if err then
		return false, err
	end

	-- 处理捕获全部节点(catchall)
	if child.node_type == node_type.catchall then
		child.handler = handler

		-- 新建的孩子节点如果是*|*.xx，即catchall节点，
		-- 则当前节点的孩子节点中不允许是通配符节点，
		-- 即：/a/:b 不允许 /a/*
		if cur_node.childs[":token"] then
			return false, "conflicts, add `*` when wildcard param already exists"
		end

		if not cur_node.childs["*"] then
			cur_node.childs["*"] = {}
		end

		cur_node.childs["*"][child.token] = child
		cur_node.nchild = cur_node.nchild + 1
	else
		cur_node.handler = handler
	end
end

-- 根据当前结点node 和 path匹配对应的catchall处理函数
function Router:catchall(node, path)
	if not node or not node.childs["*"] then
		return nil
	end

	node = node.childs["*"]

	-- 先尝试匹配后缀
	local r = ngx_re_find(path, "\\.", "jo")
	if r then
		local suffix = "*" .. string_sub(path, r, -1)
		if node and node[suffix] then
			return node[suffix].handler
		end
	end

	-- 再匹配*
	node = node["*"]
	if node then
		return node.handler
	end

	return nil
end

-- 查找路由
-- return handler params err
function Router:find_route(method, path)
	local handler = nil
	-- path中的参数集合
	local params = {}
	if not method or not path then
		return nil, nil, "method or path can't be empty"
	end

	method = string_lower(method)
	path = string_lower(path)
	path = utils.trim_suffix_slash(path)

	-- 固定路由有就用固定路由的
	if self.const_routes[method] and self.const_routes[method][path] then
		return self.const_routes[method][path], nil, nil
	end

	-- 开搞非固定路由
	local cur_node = self.routes[method]
	-- 根节点都没有
	if not cur_node then
		return nil, nil, nil
	end

	local token = nil
	local iterator, err = ngx_re_gmatch(path, "/([^/]+)", "jo")
	local caps, err = iterator()
	if caps then
		token = caps[1]
	end
	while token and not err do
		-- 当前结点的孩子节点中有该token的普通节点
		if cur_node.childs[token] then
			cur_node = cur_node.childs[token]
		-- 当前结点的孩子节点是通配符节点
		elseif cur_node.childs[":token"] then
			cur_node = cur_node.childs[":token"]
			params[cur_node.token] = token
		-- 当前结点的孩子节点是catchall节点
		-- 或者 没有匹配上
		else
			-- 例如注册：/a/*，只能匹配/a/x or /a/x.xx
			-- 没有匹配上：/a/b/c
			-- 如上, 所以再次尝试取token必须为空！
			caps, err = iterator()
			token = nil
			if caps then
				token = caps[1]
			end
			if token == nil and err == nil then
				handler = self:catchall(cur_node, path)
				if handler then
					return handler, params, nil
				end
			end

			goto not_found
		end

		caps, err = iterator()
		token = nil
		if caps then
			token = caps[1]
		end
		if token == nil and err == nil then
			handler = cur_node.handler
		end
	end

	if err then
		return nil, nil, tostring(err)
	end

	if handler then
		return handler, params, nil
	end

	-- /:a/:b/a/*, /:a/:b/a/*.xx
	-- /123/456/a
	-- /a/b/*, /a/b/*.xxx
	-- /a/b
	handler = self:catchall(cur_node, path)
	if handler then
		return handler, params, nil
	end

	::not_found::
	return nil, nil, nil
end

-- 给所有http_method增加路由
function Router:all(path, handler)
	for http_method, _ in pairs(methods) do
		local ok, err = self:add_route(http_method, path, handler)
		if ok == false then
			ngx.log(ngx.ERR,  sprintf("add_route(%s, %s, handler) error: %s", http_method, path, err))
			return err
		end
	end
end

-- 调试就找我
function Router:dump()
	ngx.say(dump_table(self.const_routes, ""))

	ngx.say(dump_table(self.routes , ""))
		
	local str = "middle_list => {\n"
	self.middle_list:reset()
	for data in self.middle_list:iterator() do
		str = str .. "\t" .. data.fname .. " => " .. tostring(data.func) .. "\n"
	end
	str = str .. "}"
	ngx.say(str)
end

-- 注册中间件
function Router:middle(fname, func)
	if utils.is_empty(fname) then
		return false, "fname is empty"
	end
	if not utils.is_function(func) then
		return false, "func type not function"
	end
	self.middle_list:push({fname = fname, func = func})
end

-- 路由匹配，供app来调用
function Router:handle(app, request, response)
	local method = request.method
	local uri = request.path

	local handler, params, err = self:find_route(method, uri)
	if err then
		return false, err
	end

	-- 没有出错，确实没有匹配的路由
	if not handler then
		return false, "not handler found"
	end

	-- 遍历中间件
	self.middle_list:reset()
	for data in self.middle_list:iterator() do
		local ok, rst_or_err, err = pcall(data.func, app, request, response, params)
		if ok == false then
			return false, sprintf("call midlle func[%s] failed, reason %s", data.fname, rst_or_err)
		end
		if not rst_or_err then
			err = err or "no error msg"
			return false, sprintf("call midlle func[%s] return false, reason %s", data.fname, err)
		end
	end

	-- 中间件搞完，开搞注册的函数
	return handler(app, request, response, params)
end

return Router

--[[
app:get("/a", function(req, res, prms)
	ngx.say("/a")
	app.router:dump()
	ngx.exit(ngx.HTTP_OK)

	return true
end)

app:get("/b", function(req, res, prms)
	ngx.say("/b")
	app.router:dump()
	ngx.exit(ngx.HTTP_OK)

	return true
end)

app:get("/a/:b", function(req, res, prms)
	ngx.say("/a/:b")
	app.router:dump()
	ngx.exit(ngx.HTTP_OK)

	return true
end)

app:get("/a/:b/*", function(req, res, prms)
	ngx.say("/a/:b/*")
	app.router:dump()
	ngx.exit(ngx.HTTP_OK)

	return true
end)

app:get("/a/:b/*.h", function(req, res, prms)
	ngx.say("/a/:b/*.h")
	app.router:dump()
	ngx.exit(ngx.HTTP_OK)

	return true
end)

/a/:b/*.h
get => {
	/test => function: 0x7fc33ece2368
	/ => function: 0x7fc33ecfb5d8
	/a => function: 0x7fc33ecfae48
	/b => function: 0x7fc33ecfae10
}

get => {
	node_type => 1
	childs => {
		a => {
			node_type => 1
			childs => {
				:token => {
					node_type => 2
					childs => {
						* => {
							* => {
								node_type => 3
								childs => {
								}
								token => *
								handler => function: 0x7fc33ecfc310
								nchild => 0
							}
							*.h => {
								node_type => 3
								childs => {
								}
								token => *.h
								handler => function: 0x7fc33ecfcf98
								nchild => 0
							}
						}
					}
					token => b
					handler => function: 0x7fc33ecfbb70
					nchild => 2
				}
			}
			token => a
			nchild => 1
		}
	}
	token => /
	nchild => 1
}

middle_list => {
	check_ip => function: 0x7fc33ecfb568
}
]]