--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - light support
    AUTHOR        : kaiwen.zhao <kaiwen.zhao@feixun.com.cn>
    CREATED DATE  : 2016-05-25
    MODIFIED DATE :
]]--

module ("luci.controller.admin.indicatorlight",package.seeall)
local dispatcher = require "luci.dispatcher"
local uci_t = require "luci.model.uci".cursor()

function index()
    if not nixio.fs.access("/etc/config/light_manage") then
        return
    end

    local page
    page = entry({"admin", "more_sysset", "indicatorlight"}, template("indicatorlight"), _("lightmanage"), 79)
	page = entry({"admin", "more_sysset", "indicatorlight", "switch"}, call("action_light_switch"), nil, nil)
	page.leaf = true
end

function action_light_switch()
	luci.sys.addhistory("indicatorlight")
	
	if luci.http.formvalue("button_change") then
		uci_t:set("light_manage", "pagelight", "ignore", luci.http.formvalue("button_change"))
		uci_t:save("light_manage")
		uci_t:commit("light_manage")
	end
	
	luci.http.redirect(
		luci.dispatcher.build_url("admin","more_sysset","indicatorlight")
	)
end
