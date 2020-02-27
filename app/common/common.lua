local pairs, ipairs = pairs, ipairs
local config = require("app.config.config")
local cmd = cmds.CMD
local uuid = require("framework.lib.utils.uuid")
local require_id = uuid:new()
local utils = require("framework.lib.utils.utils")
local is_empty = utils.is_empty

local Comm = {}

return Comm