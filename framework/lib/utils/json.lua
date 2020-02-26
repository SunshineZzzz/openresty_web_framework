-- 封装对json的操作

local pcall = pcall
local cjson = require("cjson")
local cjson_encode = cjson.encode
local cjson_decode = cjson.decode

local Json = {
	-- JSON null will be converted to a NULL lightuserdata value. 
	-- This can be compared with cjson.null for convenience.
	-- Lua CJSON decodes JSON null as a Lua lightuserdata NULL pointer. 
	-- cjson.null is provided for comparison.
	null = cjson.null
}

-- encode
function Json.encode(var)
	local ok, res = pcall(cjson_encode, var)
	if ok then 
		return res 
	end

	return nil, res
end

-- decode
function Json.decode(text)
	local ok, res = pcall(cjson_decode, text)
	if ok then 
		return res 
	end

	return nil, res
end

return Json