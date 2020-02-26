-- 公共函数

local getmetatable = getmetatable
local setmetatable = setmetatable
-- local string_gsub = string.gsub
local ngx_re_gsub, ngx_re_gmatch, ngx_re_match = ngx.re.gsub, ngx.re.gmatch, ngx.re.match
local ngx_re_find = ngx.re.find
local type = type
local pairs = pairs
local io_open, io_close = io.open, io.close
local json = require("framework.lib.utils.json")
local ok, new_tab = pcall(require, "table.new")
if not ok then
	new_tab = function (narr, nrec) return {} end
end
local string_sub, string_byte, string_format = string.sub, string.byte, string.format
local assert = assert

local Utilis = {}

-- create table
Utilis.new_tab = new_tab

-- 深拷贝
function Utilis.clone(o)
	local lookup_table = {}

	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end

		local new_object = {}
		lookup_table[object] = new_object
		for key, value in pairs(object) do
			new_object[_copy(key)] = _copy(value)
		end

		return setmetatable(new_object, getmetatable(object))
	end
	
	return _copy(o)
end

-- sprintf
function Utilis.sprintf(fmt, ...)
	assert(Utilis.is_string(fmt) == true)
	return string_format(fmt, ...)
end

-- 去掉开头的bom头部
function Utilis.trim_bom_prefix(str)
	local rStr = str
	local a, b, c = string_byte(str, 1, 3)
	-- 跳过bom头部的"EFBBBF"
	if a == 0xEF and b == 0xBB and c == 0xBF then
		rStr = string_sub(str, 4)
	end
	return rStr
end

-- 前后空格刪除
function Utilis.trim(str)
	local rStr = Utilis.trim_prefix(str)
	rStr = Utilis.trim_suffix(rStr)
	return rStr 
end

-- 去掉结尾换行和回车
function Utilis.trim_1013_suffix(str)
	local rStr = ngx_re_gsub(str, "(\r+)$", "", "jo")
	local rStr = ngx_re_gsub(rStr, "(\n+)$", "", "jo")
	return rStr
end

-- 前缀空格去除
function Utilis.trim_prefix(str)
	local rStr = ngx_re_gsub(str, "^(\\s+)", "", "jo")
	return rStr
end

-- 后缀空格去除
function Utilis.trim_suffix(str)
	local rStr = ngx_re_gsub(str, "(\\s+)$", "", "jo")
	return rStr
end

-- 前缀斜线去除
function Utilis.trim_prefix_slash(str)
	local rStr = ngx_re_gsub(str, "^(/+)(.+)", "$2", "jo")
	return rStr
end

-- 后缀斜线去除
function Utilis.trim_suffix_slash(str)
	local rStr = ngx_re_gsub(str, "(.+)(/+)$", "$1", "jo")
	return rStr
end

-- 判断给定值是否是nil
function Utilis.is_nil(o)
	return type(o) == "nil"
end

-- 判断给定值是否是table
function Utilis.is_table(o)
	return type(o) == "table"
end

-- 是否是数字
function Utilis.is_number(o)
	return type(o) == "number"
end

-- 判断给定值是否是数组
function Utilis.is_array(o)
	if not Utilis.is_table(o) then
		return false
	end

	local i = 0
	for _ in pairs(o) do
		i = i + 1
		if Utilis.is_nil(o[i]) then
			return false
		end
	end

	return true
end

-- 是否是函数
function Utilis.is_function(o)
	return type(o) == "function"
end

-- 是否是字符串
function Utilis.is_string(o)
	return type(o) == "string"
end

-- 判断给定值是否为空
function Utilis.is_empty(o)
	local t = type(o)
	if t == "nil" then
		return true
	end

	if t == "string" then
		return #o == 0
	end

	-- {}也算哦
	if Utilis.is_array(o) then
		return next(o) == nil
	end

	return false
end

-- 加载json文件
function Utilis.load_json(uri)
	local file, err = io_open(uri, "r")
	if err ~= nil then
		return nil, err
	end

	local text, err = file:read("*a")
	if err ~= nil then
		io_close(file)
		return nil, err
	end

	text = Utilis.trim_bom_prefix(text)
	local newText, n, err = ngx_re_gsub(text, "^(\\s*//.*)$", "", "jom")
	if err ~= nil then
		io_close(file)
		return nil, err
	end

	local msg, err = json.decode(newText)
	if msg == nil then
		io_close(file)
		return nil, err
	end

	io_close(file)
	return msg
end

-- 服务于ffi.load
function Utilis.load_shared_lib(so_name)
	local cpath = package.cpath
	local tried_paths = new_tab(32, 0)
	local i = 1

	local it, err = ngx_re_gmatch(cpath, "[^;]+")
	if not it then
		return nil, err
	end

	while true do
		local m, err = it()
		if err then
			return nil, err
		end

		if not m then
			break
		end

		local fpath
		local path = m[0]
		local r, err = ngx_re_match(path, "(.*/)")
		if r then
			fpath = r[0] .. so_name
			local f = io_open(fpath)
			if f ~= nil then
				io_close(f)
				return ffi.load(fpath)
			end
			tried_paths[i] = fpath
			i = i + 1
		end
	end

	return nil, tried_paths
end

return Utilis