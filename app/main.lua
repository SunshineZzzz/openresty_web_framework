local application = require("framework.index")
local config = require("app.config.config")
local router = require("app.router")
local check_ip_middleware = require("app.middleware.check_ip")

-- 生成application
local app = application(config)

-- 注册中间件
app:middle("check_ip", check_ip_middleware(config.ip_white_list))

-- 注册路由
router(app)

-- run
app:run()