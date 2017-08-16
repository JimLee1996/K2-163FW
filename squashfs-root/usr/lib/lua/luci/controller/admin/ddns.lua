--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - ddns support
    AUTHOR        : kaiwen.zhao <kaiwen.zhao@feixun.com.cn>
    CREATED DATE  : 2016-04-28
    MODIFIED DATE : 
]]--

module("luci.controller.admin.ddns", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/ddns") then
	return
    end 

    local page

    page = entry({"admin", "more_ddns"}, cbi("ddns"), _("ddns"), 73)
    page.dependent = true
end
