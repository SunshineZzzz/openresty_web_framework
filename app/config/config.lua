-- 配置相关

-- 这里还是拼一下路径吧，因为 init_by_lua_file 第一次启动设置openresty的工作路径异常
-- 导致相对路径加载配置异常，找不到文件
-- init_worker_by_lua_file 正常
local work_dir = ngx.config.prefix() or "."

return 
{
	-- 是否开启调试模式
	app_debug = true,
	-- ip白名单
	ip_white_list = {
		["127.0.0.1"] = true,
		-- 允许所有，允许网段啥的以后再说吧
		["*"] = true,
	},
	-- 开启模板
	view_enable = true,
	-- 模板配置
	view = {
		ext = "html",
		views = "./app/views",
		cache = false,
	},
}