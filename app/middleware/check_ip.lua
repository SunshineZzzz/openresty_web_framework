local sprintf = string.format

local function CheckIp(ipWhiteList)
	return function(app, req, res, prms)
		local r = ipWhiteList["*"] or ipWhiteList[ngx.var.remote_addr]
		if not r then
			return false, sprintf("ip[%s] forbid!!!", ngx.var.remote_addr)
		end
		return true
	end
end

return CheckIp