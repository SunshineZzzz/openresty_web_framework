-- 封装对stack的操作 

local setmetatable = setmetatable
local table_insert = table.insert
local table_remove = table.remove
local tostring = tostring
local ipairs = ipairs

local _LuaStackMeta = {
	__index = {
		push = function(self, ele)
			table_insert(self._data, ele)
		end,
		pop = function(self)
			table_remove(self._data)
		end,
		peek = function(self)
			return self._data[#self._data]
		end,
		count = function(self)
			return #self._data
		end,
	},
	__tostring = function(self)
		local str = "-----\n"
		for i, v in ipairs(self._data) do
			str = str .. i .. " " .. tostring(v) .. "\n"
		end
		str = str .. "-----"

		return str
	end
}

local function Stack()
	return setmetatable({_data = {}}, _LuaStackMeta)
end

return Stack