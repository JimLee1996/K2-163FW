--[[
	Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

	DISCREPTION   : LuCI - Lua Configuration Interface - ddns support
	AUTHOR        : kaiwen.zhao <kaiwen.zhao@feixun.com.cn>
	CREATED DATE  : 2016-04-28
	MODIFIED DATE : 
]]--

m = Map("ddns", translate("dynamic DNS"))
m:addmodule("more_ddns")

function m.on_after_commit(map)  
     luci.sys.call("/usr/lib/ddns/dynamic_dns_updater.sh myddns 1>/dev/null &")    
end

s = m:section(NamedSection, "myddns","service", "")
s.addremove = false

switch = s:option(ListValue, "enabled", translate("DDNS"))                                 
switch.widget = "radio"              
switch.orientation = "horizontal"
switch.advance_second_title = true
switch:value("1", translate("open"))
switch:value("0", translate("close"))
switch.default = "0"
switch.show_help = true
switch.min_size = true
switch.radio_help = true
switch.help_desc = translate("DDNS help")

svc = s:option(ListValue, "service_name", translate("DDNS Service"))
svc.default = "3322.org"
svc.rmempty = false
svc:depends("enabled","1")
svc.display = "none"


local services = { }
local fd = io.open("/usr/lib/ddns/services", "r")
if fd then
    local ln
    repeat
        ln = fd:read("*l")
        local s = ln and ln:match('^%s*"([^"]+)"')
        if s then services[#services+1] = s end
    until not ln
    fd:close()
end

local v
for _, v in ipairs(services) do
    svc:value(v)
end

function svc.cfgvalue(...)
	local v = Value.cfgvalue(...)
	if not v or #v == 0 then
		return nil
	else
		return v
	end
end


local username = s:option(Value, "username", translate("user"))
username.rmempty = false
username.datatype = "and(maxlength(64), ddnscheckspecialchar)"
username.notnull = true
username.primpterror = true
username:depends("enabled","1")
username.display = "none"
 
local pw = s:option(Value, "password", translate("passwd"))
pw.password = true
pw.rmempty = false
pw.datatype = "and(maxlength(64), ddnscheckspecialchar)"
pw.notnull = true
pw.primpterror = true
pw:depends("enabled","1")
pw.display = "none"
pw.idname = "ddns_key" --注：密码框现为区别取值到页面

local hostname = s:option(Value, "domain", translate("DDNS domain"))
hostname.rmempty = false
hostname.datatype = "and(ddnsdomain, maxlength(64))"
hostname.notnull = true
hostname.primpterror = true
hostname:depends("enabled","1") 
hostname.display = "none"

return m

