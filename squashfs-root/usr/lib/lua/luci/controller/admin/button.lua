--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - wifi/wps/reset button support
    AUTHOR        : kaiwen.zhao <kaiwen.zhao@feixun.com.cn>
    CREATED DATE  : 2016-04-29
    MODIFIED DATE : 
]]--

module("luci.controller.admin.button", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/button") then
		return
    end 

    local page

    page = entry({"admin", "more_sysset", "buttonset"}, cbi("button"), _("button"), 80)
end
