--[[
	Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

	DISCREPTION   : LuCI - Lua Configuration Interface - wifi/wps/reset support
	AUTHOR        : kaiwen.zhao <kaiwen.zhao@feixun.com.cn>
	CREATED DATE  : 2016-04-29
	MODIFIED DATE : 
]]--

m = Map("button", translate("button set"))
m:addmodule("buttonset")

function m.on_after_commit(map)  

end

s = m:section(NamedSection, "wps_wifi","wps_wifi", "")
s.addremove = false

bt = s:option(ListValue, "switch",translate("hardware button set"), translate("button help"))
bt.help = true
bt.widget="radio"
bt.orientation="horizontal"
bt.rmempty = false
bt.advance_second_title = true
bt:value("wps", translate("WPS/RESET"))
bt:value("wifi", translate("WIFI/RESET"))

return m

