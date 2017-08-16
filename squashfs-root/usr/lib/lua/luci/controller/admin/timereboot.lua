--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - parent control support
    AUTHOR        : xiangjun.fu <xiangjun.fu@phicomm.com.cn>
    CREATED DATE  : 2016-08-18
    MODIFIED DATE : 
]]--
require "luci.sys"
require "luci.util"
require "luci.template"
require "luci.dispatcher"
require "luci.controller.admin.system"
local scheduletask = require"luci.tools.scheduletask"

module("luci.controller.admin.timereboot", package.seeall)

local reboot = "yes"
local rebootpri = "90"
local action = "reboot"

function index()
    entry({"admin", "timereboot"}, call("do_timereboot"), _("timereboot"), 91)
end

function do_timereboot()
    local uci_t = require "luci.model.uci".cursor()
    local rebootenable = luci.http.formvalue("timeRebootEnablestatus")
    local timerange = luci.http.formvalue("timeRebootrange")
    local cururl = luci.http.formvalue("cururl")
    
    luci.sys.call("uci set timereboot.timereboot.enable=%s > /dev/null" % rebootenable)
    luci.sys.call("uci set timereboot.timereboot.time=%s > /dev/null" % timerange)
    luci.sys.call("uci commit timereboot.timereboot> /dev/null")

    scheduletask.settaskatr("timereboot", "timereboot", action, reboot, rebootpri,"time")
    
    if rebootenable == "on" then
        scheduletask.cfgscdutskbylua("add","timereboot","timereboot")
    else
        scheduletask.cfgscdutskbylua("del","timereboot","timereboot")
    end
        
    local charindex = string.find(cururl,"/admin/")
    if charindex then
        luci.http.redirect(cururl)
    else
        luci.http.redirect(luci.dispatcher.build_url("admin", "index"))
    end
end
