-- 封装对UUID的操作

local bit = require("bit")
-- Converts its first argument to a hex string. 
-- The number of hex digits is given by the absolute value of the optional second argument.
local tohex = bit.tohex
-- 按位与
local band = bit.band
-- 按位或
local bor = bit.bor
-- 日历时
local ngx_time = ngx.time
-- nginx process id
local ngx_worker_pid = ngx.worker.pid
local type = type
local ngx_re_find = ngx.re.find
local fmt = string.format
local random = math.random
-- 8-4-4-4-12
local regex = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"


local Uuid = {
	_seed = 0
}

-- 创建UUID对象
function Uuid:new()
	local instance = {}
	setmetatable(instance, {__index = self})

	instance:seed()
	return instance
end

-- 随机数种子初始化
function Uuid:seed()
	if self._seed == 0 then
		if ngx then
			self._seed = ngx_time() + ngx_worker_pid()
		else
			self._seed = os.time()
		end
	end

	math.randomseed(self._seed)

	return self._seed
end

-- 验证UUID格式是否正确
function Uuid:valid(str)
	if type(str) ~= "string" or #str ~= 36 then
		return false
	end

	return ngx_re_find(str, regex, "ijo")
end

-- UUID版本4生成器
function Uuid:generate_v4()
	-- xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx
	return (fmt('%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s', 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 

		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 

		-- 第3段高8位指定版本为v4
		tohex(bor(band(random(0, 255), 0x0F), 0x40), 2), 
		tohex(random(0, 255), 2), 

		-- 第4段 变体版本
		tohex(bor(band(random(0, 255), 0x3F), 0x80), 2), 
		tohex(random(0, 255), 2), 

		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2), 
		tohex(random(0, 255), 2)))
end

return Uuid