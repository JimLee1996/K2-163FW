require("luci.sys")
--require("luci.sys.zoneinfo")
--require("luci.tools.webadmin")
require("luci.fs")
require("luci.config")
require("luci.model.uci")

local netm = require "luci.model.network".init()

data ={
	wan = {}
    }

--[[ get wan port value]]--
local cur = luci.model.uci.cursor()
local wan_section = cur:get_all("network","wan")
local opt_value = wan_section.peerdns
wan2 = netm:get_wannet()

if wan2 then
	ipaddr  = wan2:ipaddr()
	netmask = wan2:netmask()
	gateway  = wan2:gwaddr()
	mtu = cur:get("network", "wan", "mtu")
	if opt_value == nil or opt_value == "1" then
		dns = wan2:dnsaddrs()
	else
		dns = {wan_section.dns1,wan_section.dns2}
		if not dns[1] then
			dns = {wan_section.static_dns1, wan_section.static_dns2}
		end
	end

	if dns and #dns > 0 then
		data.wan.dns = dns
	end

	if ipaddr and #ipaddr > 0 then
		data.wan.ipaddr = ipaddr
	end

	if netmask and #netmask > 0 then
		data.wan.netmask = netmask
	end

	if gateway and #gateway > 0 then
		data.wan.gateway = gateway
	end

	if mtu and #mtu > 0 then
		data.wan.mtu = mtu
	end

	cur:section("network", "tmp", "static", data.wan)
	cur:tset("network", "static", data.wan)
	cur:save("network")
	cur:commit("network")
else
	cur:delete("network", "static")
	cur:save("network")
	cur:commit("network")
end

local uci = require("luci.model.uci")
local m

m = Map("network", translate("WAN Config"), "")
m:addmodule("networkset")
m.wanconnect = true
m.idname = "wanset"

s = m:section(NamedSection, "wan", "interface", "","")
s.anonymous = true
s.addremove = false

s:tab("wan_connect_set", "")

detectwan = s:taboption("wan_connect_set", Button, "detectwanproto", translate("detect wan type"))
detectwan.hide_label = true
detectwan.jump_node="wandetect"

accessproto = s:taboption("wan_connect_set",ListValue, "proto", translate("internet access mode:"))
accessproto:value("dhcp",translate("dhcp"))
accessproto:value("pppoe",translate("pppoe"))
accessproto:value("static",translate("static"))
accessproto.default = "dhcp"
accessproto.widget = "radio"
accessproto.centerclass = "no_margin_left200"
accessproto.orientation = "horizontal"

if cur:get("network", "wan", "detectonetime") then
	function accessproto.cfgvalue(self, section)
		luci.sys.call("uci set network.wan.detectonetime=\"\"")
		luci.sys.call("uci commit network")
		local protovalue = cur:get("network", "wan", "detectwanproto")
		if protovalue then
			protovalue = string.lower(protovalue)
			return protovalue
		end
	end
end

pppoemode = s:taboption("wan_connect_set", ListValue, "DiaMode", translate("Dial Mode:"))
pppoemode:value("0",translate("normal dial_mode"))
pppoemode:value("1",translate("spec dial_mode_1"))
pppoemode:value("2",translate("spec dial_mode_2"))
pppoemode:value("3",translate("spec dial_mode_3"))
pppoemode:value("4",translate("spec dial_mode_4"))
pppoemode:depends("proto", "pppoe")
pppoemode.widget = "select"
pppoemode.default = "0"
pppoemode.centerclass = "no_margin_left200"
pppoemode.display = "none"

pppoeuser = s:taboption("wan_connect_set", Value, "username", translate("username:"))
pppoeuser.notnull = true
pppoeuser.rmempty = false
pppoeuser.datatype = "and(sperangelength(1,32),checkPPPspechar,blank)"
pppoeuser.centerclass="no_margin_left200"
pppoeuser.primpterror = true
pppoeuser.display = "none"
pppoeuser:depends("proto","pppoe")
pppoeuser.focus = true

pppoepwd = s:taboption("wan_connect_set", Value, "password", translate("password:"))
pppoepwd.password = true
pppoepwd.notnull = true
pppoepwd.rmempty = false
pppoepwd.datatype = "and(rangelength(1,32),checkPPPspechar_cn,blank)"
pppoepwd.centerclass="no_margin_left200"
pppoepwd.primpterror = true
pppoepwd.display = "none"
pppoepwd.idname = "pppoepwd"
pppoepwd.focus = true
pppoepwd:depends("proto","pppoe")

pppoeservername = s:taboption("wan_connect_set", Value, "service", translate("service name:"))
pppoeservername.datatype = "and(checkPPPspechar,blank)"
pppoeservername.forceempty = true
pppoeservername.forcewrite = true
pppoeservername.centerclass = "no_margin_left200"
pppoeservername.primpterror = true
pppoeservername.display = "none"
pppoeservername:depends("proto", "pppoe")
pppoeservername.warning = translate("not must fail")
pppoeservername.force = true

function pppoeservername.write(self, section, value)
	if value then
		luci.util.exec("uci set network.wan.service=%q" % value)
	else
		luci.util.exec("uci delete network.wan.service")
	end
end

dhcpmtu = s:taboption("wan_connect_set", Value, "dhcpmtu", translate("mtu:"))
dhcpmtu.notnull = true
dhcpmtu.rmempty = false
dhcpmtu.forcewrite = true
dhcpmtu.datatype = "range(576, 1500)"
dhcpmtu.centerclass="no_margin_left200"
dhcpmtu.size = "short"
dhcpmtu.warning = translate("dhcp_default_mtu")
dhcpmtu:depends("proto", "dhcp")

function dhcpmtu.cfgvalue(self, section)
	local mtu_dhcp = 1500
	local proto = cur:get("network", "wan", "proto")
	if proto == "dhcp" or proto == "static" then
		mtu_dhcp = cur:get("network", "static", "mtu")
		if not mtu_dhcp then
			mtu_dhcp = 1500
		end
	end
	return mtu_dhcp
end

function dhcpmtu.write(self, section, value)
	if value then
		luci.util.exec("uci set network.wan.mtu=%q" % value)
	else
		luci.util.exec("uci set network.wan.mtu=1500")
	end
end

pppoemtu = s:taboption("wan_connect_set", Value, "pppoemtu", translate("mtu:"))
pppoemtu.notnull = true
pppoemtu.forcewrite = true
pppoemtu.rmempty = false
pppoemtu.display = "none"
pppoemtu.datatype = "range(576, 1492)"
pppoemtu.centerclass="no_margin_left200"
pppoemtu.size = "short"
pppoemtu.warning = translate("pppoe_default_mtu")
pppoemtu:depends("proto", "pppoe")


function pppoemtu.cfgvalue(self, section)
        local mtu_pppoe = 1488
        local proto = cur:get("network", "wan", "proto")
        if proto == "pppoe" then
                mtu_pppoe = cur:get("network", "static", "mtu")
		if not mtu_pppoe then
			mtu_pppoe = 1488
		end
        end
        return mtu_pppoe-8
end

function pppoemtu.write(self, section, value)
        if value then
                luci.util.exec("uci set network.wan.mtu=%q" % tostring(tonumber(value)+8))
        else
                luci.util.exec("uci set network.wan.mtu=1488")
        end
end

staticip = s:taboption("wan_connect_set", Value, "ipaddr", translate("IP Address:"))
staticip.notnull = true
staticip.rmempty = false
staticip.datatype = "ipv4"
staticip.forcewrite = true
staticip.centerclass="no_margin_left200"
staticip.primpterror = true
staticip.display = "none"
staticip:depends("proto","static")

function staticip.cfgvalue(self, section)
	local value = self.map:get(section, self.option)
	if value then
		return value
	else
		local value = cur:get("network", "static", "ipaddr")
		if value then
			return value
		end
	end
end

staticmask = s:taboption("wan_connect_set", Value, "netmask", translate("Sub NetMask:"))
staticmask.notnull = true
staticmask.rmempty = false
staticmask.datatype = "ipv4mask"
staticmask.forcewrite = true
staticmask.centerclass="no_margin_left200"
staticmask.primpterror = true
staticmask.display = "none"
staticmask:depends("proto","static")

function staticmask.cfgvalue(self, section)
	local value = cur:get("network", "static", "netmask")
	if value then
		return value
	end
end

staticgw = s:taboption("wan_connect_set", Value, "gateway", translate("GateWay:"))
staticgw.notnull = true
staticgw.rmempty = false
staticgw.datatype = "ipv4"
staticgw.forcewrite = true
staticgw.centerclass="no_margin_left200"
staticgw.primpterror = true
staticgw.display = "none"
staticgw:depends("proto","static")

function staticgw.cfgvalue(self, section)
	local value = cur:get("network", "static", "gateway")
	if value then
		return value
	end
end

static_dns1 = s:taboption("wan_connect_set", Value, "static_dns1", translate("static_primary_dns:"))
static_dns1.notnull = true 
static_dns1.rmempty = false
static_dns1.datatype = "ipv4"
static_dns1.forcewrite = true
static_dns1.centerclass="no_margin_left200"
static_dns1.primpterror = true
static_dns1.display = "none"
static_dns1:depends("proto","static")

function static_dns1.cfgvalue(self, section)
	local value = self.map:get(section, self.option)
	if value then
		return value
	else
		local value = cur:get("network", "static", "dns")
		if value then
			return value[1]
		end
	end
end

static_dns2 = s:taboption("wan_connect_set", Value, "static_dns2", translate("static_second_dns:"))
static_dns2.datatype = "ipv4"
static_dns2.forcewrite = true
static_dns2.centerclass="no_margin_left200"
static_dns2.primpterror = true
static_dns2.display = "none"
static_dns2:depends("proto","static")

function static_dns2.cfgvalue(self, section)
	local valuebefore = cur:get("network", "wan", "static_dns2")
	
	if valuebefore == nil then
		local value = self.map:get(section, self.option)
		if value then
			return value
		else
			local value = cur:get("network", "static", "dns")
			if value then
				return value[2]
			end
		end
	else
		local value = self.map:get(section, self.option)
		if value then
			return value
		else
			return nil
		end
	end
end

function static_dns1.write(self, section, value)
	local cur = m.uci
	local wan_section = cur:get_all("network", "wan")
	local dns_first_value = luci.http.formvalue("cbid.network.wan.static_dns1")
	local dns_second_value = luci.http.formvalue("cbid.network.wan.static_dns2")
	if dns_first_value then
		value = dns_first_value
		luci.util.exec("uci set network.wan.static_dns1=%q" % dns_first_value)
		if dns_second_value then
			luci.util.exec("uci set network.wan.static_dns2=%q" % dns_second_value)
			value = value .. " " .. dns_second_value
		end
	end
	luci.util.exec("uci del network.wan.dns1")
	luci.util.exec("uci del network.wan.dns2")
	luci.util.exec("uci set network.wan.dns=%q" % value)
	luci.util.exec("uci set network.wan.dns_opt=0")
	luci.util.exec("uci set network.wan.peerdns=0")
end

static_mtu = s:taboption("wan_connect_set", Value, "static_mtu", translate("mtu:"))
static_mtu.notnull = true
static_mtu.rmempty = false
static_mtu.centerclass="no_margin_left200"
static_mtu.forcewrite = true
static_mtu.display = "none"
static_mtu.datatype = "range(576, 1500)"
static_mtu:depends("proto", "static")

function static_mtu.cfgvalue(self, section)
	local mtu_static = 1500
	local proto = cur:get("network", "wan", "proto")
	if proto == "dhcp" or proto == "static" then
		local value = cur:get("network", "static", "mtu")
		if value then
			mtu_static = value
		end
	end
	return mtu_static
end

function static_mtu.write(self, section, value)
	if value then
		luci.util.exec("uci set network.wan.mtu=%q" % value)
	else
		luci.util.exec("uci set network.wan.mtu=1500")
	end
end

enable_advance = s:taboption("wan_connect_set", Flag, "enable_advance", translate("advance enable"))
enable_advance.rmempty = false
enable_advance.centerclass="margin_left_40per"

function enable_advance.write(self, section, value)
	if value == "1" then
		return AbstractValue.write(self, section, value)
	elseif not value then
		local proto = luci.http.formvalue("cbid.network.wan.proto")
		if proto ~= "static" then
			luci.util.exec("uci delete network.wan.netmask")
			luci.util.exec("uci delete network.wan.gateway")
			luci.util.exec("uci delete network.wan.static_dns1")
			luci.util.exec("uci delete network.wan.static_dns2")
			luci.util.exec("uci delete network.wan.dns")
			luci.util.exec("uci set network.wan.peerdns=1")
		else
			luci.util.exec("uci set network.wan.peerdns=0")
		end
		luci.util.exec("uci delete network.wan.dns1")
		luci.util.exec("uci delete network.wan.dns2")
		luci.util.exec("uci set network.wan.ignore=1") 
		luci.util.exec("uci commit network")
		return AbstractValue.remove(self, section)
	end
end

mac_operate = s:taboption("wan_connect_set", ListValue, "macoperate", translate("operate:"))
mac_operate:value("1",translate("no clone"))
mac_operate:value("2",translate("auto clone")) 
mac_operate:value("3",translate("input clone"))
mac_operate:depends("enable_advance", "1")
mac_operate.widget = "select"
mac_operate.centerclass="no_margin_left200"
mac_operate.macclone = true
mac_operate.display = "none"
mac_operate.macclone_help = true
mac_operate.help_desc = translate("mac_operate_help")
mac_operate.conflict_wisp = true
--mac_operate.template = "cbi/lvaluemac"

function mac_operate.write(self, section, value)
	if value == "2" then
		luci.util.exec("uci set network.wan.macoperate=2")
		luci.util.exec("uci set network.wan.ignore=0")
	elseif value == "3" then
		luci.util.exec("uci set network.wan.macoperate=3")
		luci.util.exec("uci set network.wan.ignore=0")
	else
		luci.util.exec("uci set network.wan.macoperate=1")
		luci.util.exec("uci set network.wan.ignore=1")
	end
	luci.util.exec("uci commit network")
end

mac_addr1 = s:taboption("wan_connect_set", Value, "mac_addr",translate("curent mac addr:"))
mac_addr1.notnull = true
mac_addr1.rmempty = false
mac_addr1.datatype = "macaddr"
mac_addr1.display = "none"
mac_addr1:depends("enable_advance", "1")
mac_addr1.centerclass="no_margin_left200"
mac_addr1.readonly = true
mac_addr1.conflict_wisp = true

function mac_addr1.cfgvalue(self, section)
	local macoperatevalue = luci.util.exec("uci get network.wan.macoperate")
	if macoperatevalue == "1" then
		curUserLoginMac = luci.util.exec("uci get network.wan.macaddr") 
	else
		curUserLoginMac = luci.util.exec("uci get network.wan.mac_addr")
		if curUserLoginMac == "" then
			curUserLoginMac = luci.util.exec("uci get network.wan.macaddr")
		elseif string.len(curUserLoginMac) < 12 then  
			curUserLoginMac = luci.util.exec("uci get network.wan.macaddr")
		end
	end
	return string.sub(curUserLoginMac,0,#curUserLoginMac-1)
end

dnsenable = s:taboption("wan_connect_set", ListValue, "dns_opt", translate("custom DNS:"))
dnsenable:value("1",translate("开"))
dnsenable:value("0",translate("关"))
dnsenable.widget = "radio"
dnsenable.default = "0"
dnsenable.display ="none"
dnsenable.centerclass="no_margin_left200"
dnsenable:depends({enable_advance="1", proto="dhcp"})
dnsenable:depends({enable_advance="1", proto="pppoe"})
dnsenable.orientation = "horizontal"
dnsenable.forcewrite = true
dnsenable.radio_help = true
dnsenable.left = true
dnsenable.help_desc = translate("custom DNS help")

function dnsenable.write(self, section, value)
	if value == "0" then
		luci.util.exec("uci delete network.wan.dns1")
		luci.util.exec("uci delete network.wan.dns2")
		luci.util.exec("uci delete network.wan.dns")
		luci.util.exec("uci set network.wan.peerdns=1")
		luci.util.exec("uci commit network")
	else
		luci.util.exec("uci set network.wan.peerdns=0")
		luci.util.exec("uci commit network")
	end
	return AbstractValue.write(self, section, value)
end

dns1 = s:taboption("wan_connect_set", Value, "dns1",translate("primary_dns:"))
dns1.size = "long"
dns1.notnull = true
dns1.datatype = "ipv4"
dns1.rmempty = false
dns1.display = "none"
dns1.centerclass="no_margin_left200"
dns1.primpterror = true
dns1.forcewrite = true
dns1:depends("dns_opt","1")

function dns1.cfgvalue(self, section)
	local value = self.map:get(section, self.option)
	if value then
		return value
	else
		local value = cur:get("network", "static", "dns")
		if value then
			return value[1]
		end
	end
end

dns2 = s:taboption("wan_connect_set", Value, "dns2",translate("second_dns:"))
dns2.size = "long"
dns2.datatype = "ipv4"
dns2.display = "none"
dns2.centerclass="no_margin_left200"
dns2:depends("dns_opt","1")
dns2.warning = translate("second_dns_msg")
function dns2.cfgvalue(self, section)
	local valuebefore = cur:get("network", "wan", "dns2")
	
	if valuebefore == nil then
		local value = self.map:get(section, self.option)
		if value then
			return value
		else
			local value = cur:get("network", "static", "dns")
			if value then
				return value[2]
			end
		end
	else
		local value = self.map:get(section, self.option)
		if value then
			return value
		else
			return nil
		end
	end
		
end

function dns1.write(self, section, value)
	local dns_first_value = luci.http.formvalue("cbid.network.wan.dns1")
	local dns_second_value = luci.http.formvalue("cbid.network.wan.dns2")
	if dns_first_value then
		value = dns_first_value
		luci.util.exec("uci set network.wan.dns1=%q" % dns_first_value)
		if dns_second_value then 
			luci.util.exec("uci set network.wan.dns2=%q" % dns_second_value)
				value = value .. " " .. dns_second_value
		end
	end
	luci.util.exec("uci set network.wan.dns=%q" % value)  
	luci.util.exec("uci set network.wan.peerdns=0")
	luci.util.exec("uci commit network")
end

return m
