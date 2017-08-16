--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - upnpset support
    AUTHOR        : shijie.gao <shijie.gao@phicomm.com.cn>
    CREATED DATE  : 2016-05-06
    MODIFIED DATE :
]]--

local m, s, o

m = Map("UPnP", translate("phicomm UpnpSet"))

m:addmodule("UPnPset")

s = m:section(NamedSection, "config", "upnpd")
s.addremove = false
s.anonymous = true

s:tab("upnp_enable", "")

switch = s:taboption("upnp_enable", Flag, "enable", translate("upnp enable:"))
switch.widget = "on_off_button"
switch.cbi_apply_click = true

s = m:section(TypedSection, "setting", "")
s.template = "cbi/upnp"

return m
