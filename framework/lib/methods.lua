-- 支持的http method

-- 记录
--[[
1.什么是RESTful API
URL定位资源，用HTTP动词(GET,POST,PUT,DELETE等)描述操作。
https://blog.csdn.net/hjc1984117/article/details/77334616
2.HTTP请求方法
https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Methods
]]

local supported_http_methods = {
	-- 获取资源
	get = true,
	-- 新建资源
	post = true,
	-- 更新资源
	put = true,
	-- 删除指定的资源
	delete = true,
}

return supported_http_methods