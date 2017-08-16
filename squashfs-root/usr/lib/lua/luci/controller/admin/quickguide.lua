--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - lanSet support
    AUTHOR        :     xiangjun.fu <    xiangjun.fu@phicomm.com.cn>
    CREATED DATE  : 2016-05-05
    MODIFIED DATE : 
]]--

local io = require "io"
require "luci.sys"
require "luci.util"
require "luci.template"
require "luci.dispatcher"
require "luci.controller.admin.system"
phicomm_lua = require "phic"

module("luci.controller.admin.quickguide", package.seeall)

function index()
    entry({"admin", "quickguide"}, alias("admin", "quickguide", "welcome"), _("welcome"), 99).index = true
    entry({"admin", "quickguide", "welcome"},call("do_welcome"), _("Overview"), 20)
    entry({"admin", "quickguide", "wireless_setting"},call("do_wireless_setting"), _("internet_setting"), 31)
    entry({"admin", "quickguide", "quickguide_finish"},call("do_quickguide_finish"), _("internet_setting"), 32)
    entry({"admin", "quickguide", "internet_setting"},call("do_internet_setting"), _("internet_setting"), 33)

    entry({"admin", "quickguide", "find_pppoe_passwd"},template("quickguide/find_pwd"), _("pppoe_setting"), 34)
	entry({"admin", "quickguide", "start_find_passwd"},call("do_find_pppoe_pwd"), _("pppoe_setting"), 35)
	entry({"admin", "quickguide", "kill_pppoe_server"},call("do_kill_pppoe_server"), _("pppoe_setting"), 35)
end

function do_welcome()
    if luci.dispatcher.urlfilter() then
       return 
    end
    local uci_t = require "luci.model.uci".cursor()
    local userprotocol = luci.http.formvalue("userprotocol") or ""
    local configclick = luci.http.formvalue("configclick") or ""
    if userprotocol and (userprotocol == "0" or userprotocol == "1") then
        local uci_t = require "luci.model.uci".cursor()
        uci_t:set("luci", "main", "userprotocol", userprotocol)
        uci_t:save("luci")
        uci_t:commit("luci")
    end
    if configclick and configclick == "click" then
        luci.template.render("quickguide/welcome",{autodetect = "show"})
    else
        luci.template.render("quickguide/welcome")
    end
end

function dns_set(uci_t, pd)
    uci_t:set("network", "wan", "dns1", pd)
    local wan_section = uci_t:get_all("network","wan")

    local value = pd
    local dns1value = value
    local dns2value 

    uci_t:foreach("network", "interface",
        function(s)
            if s.ifname then
                if s.ifname == "eth0.2" or s.ifname == "apclii0" or s.ifname == "apcli0" then
                    if s.dns2 then
                        dns2value = s.dns2
                    end
                end
            end
        end) 

    if dns1value then
        value = dns1value
        if dns2value then
        value = value .. " " .. dns2value
        end
    else 
        value = dns2value
    end
                                                                         
        local t = { }                                                          
    t = {value}
    value = table.concat(t," ")
                                                        
    uci_t:set("network", "wan", "dns", value)       
end

function do_internet_setting()
    if luci.dispatcher.urlfilter() then
       return 
    end
    local uci_t = require "luci.model.uci".cursor()
    if luci.http.formvalue("autodetect") == "1" then
        luci.template.render("quickguide/internet_setting",{fromautodetect = 1})
        luci.controller.admin.system.fork_exec("autonetwork")
    elseif luci.http.formvalue("autodetect") == "2" then
        luci.template.render("quickguide/internet_setting",{fromautodetect = 2})
    elseif luci.http.formvalue("autodetect") == "0" then
        if luci.http.formvalue("connectionType") == "DHCP" then
            luci.sys.call("uci set network.wan.proto=dhcp > /dev/null")
            luci.sys.call("uci set network.wan.peerdns=1 > /dev/null")
        elseif luci.http.formvalue("connectionType") == "PPPOE" then
            luci.sys.call("uci set network.wan.proto=pppoe > /dev/null")
            local usr = luci.http.formvalue("pppoeUser") or ""
            local pwd = luci.http.formvalue("pppoePass") or ""
            phicomm_lua.set_normal_config("network", "wan", "username", usr)
            phicomm_lua.set_normal_config("network", "wan", "password", pwd)
            luci.sys.call("uci set network.wan.peerdns=1 > /dev/null")
        elseif luci.http.formvalue("connectionType") == "STATIC" then
            luci.sys.call("uci set network.wan.proto=static > /dev/null")
            local ip = luci.http.formvalue("staticIp") or ""
            local nm = luci.http.formvalue("staticNetmask") or ""
            local gw = luci.http.formvalue("staticGateway") or ""
            local pd = luci.http.formvalue("staticPriDns") or ""
            uci_t:set("network", "wan", "proto", "static")
            uci_t:set("network", "wan", "ipaddr", ip)
            uci_t:set("network", "wan", "netmask", nm)
            uci_t:set("network", "wan", "gateway", gw)
            uci_t:set("network", "wan", "peerdns", "0")
            uci_t:set("network", "wan", "dns_opt", "0")
            uci_t:set("network", "wan", "static_dns1", pd)
            uci_t:set("network", "wan", "dns", pd)
        end
        uci_t:save("network")

		luci.http.redirect(luci.dispatcher.build_url("admin", "quickguide", "wireless_setting"))
    else
        luci.template.render("quickguide/internet_setting")
    end
end

function do_wireless_setting()
    if luci.dispatcher.urlfilter() then
       return 
    end
    local uci_t = require "luci.model.uci".cursor()
    if luci.http.formvalue("savevalidate") == "1" then
        local ssid = luci.http.formvalue("ssid") or ""
        local key = luci.http.formvalue("key") or ""
        local inic_ssid = luci.http.formvalue("inic_ssid") or ""
        local inic_key = luci.http.formvalue("inic_key") or ""
        
        local num_24g = uci_t:get_num_by_name("wireless", "wifi-iface", "ifname", "ra0")
        local num_5g = uci_t:get_num_by_name("wireless", "wifi-iface", "ifname", "rai0")
        
        phicomm_lua.set_wifi_iface_config("ra0", "ssid", ssid)
        phicomm_lua.set_wifi_iface_config("ra0", "key", key)
        phicomm_lua.set_wifi_iface_config("rai0", "ssid", inic_ssid)
        phicomm_lua.set_wifi_iface_config("rai0", "key", inic_key)
        
        if key ~= ""  then
            luci.sys.call("uci set wireless.@wifi-iface[%s].encryption=\"psk-mixed+tkip+ccmp\"" % num_24g)
        else
            luci.sys.call("uci set wireless.@wifi-iface[%s].encryption=\"none\"" % num_24g)
        end
        
        if inic_key ~= "" then
            luci.sys.call("uci set wireless.@wifi-iface[%s].encryption=\"psk-mixed+tkip+ccmp\"" % num_5g)
        else
            luci.sys.call("uci set wireless.@wifi-iface[%s].encryption=\"none\"" % num_5g)
        end
        
        local firststart = uci_t:get("luci", "main", "firststart")
        local firstconfig = uci_t:get("luci", "main", "first_config")
        if(firststart == "1") then
            if(firstconfig == "0") then
                uci_t:set("luci", "main", "first_config", "1")
            end        
            uci_t:set("luci", "main", "firststart", "0")
            uci_t:save("luci")
            uci_t:commit("luci")
            luci.dispatcher.domain_hijack_close()
        end
        
        luci.sys.call("uci commit wireless")
        luci.template.render("quickguide/wireless_setting",{showprocess = 1})
		luci.sys.call("sed -i \"/url.redirect/d\" /etc/lighttpd/lighttpd.conf 2>/dev/null")
        luci.controller.admin.system.fork_exec("sleep 2;/etc/init.d/lighttpd restart;sleep 1;/sbin/luci-reload network")
    elseif luci.http.formvalue("savevalidate") == "2" then
		--快速向导结束,停止pppoe-server
		luci.sys.call("/etc/init.d/pppoe-server stop")

        luci.http.redirect(luci.dispatcher.build_url("admin", "quickguide", "quickguide_finish"))
    else
        luci.template.render("quickguide/wireless_setting")
    end
end


function do_find_pppoe_pwd()
	local f
	local num = 0
	local status
	local f_protocol, f_user, f_passwd

	local uci_t = require "luci.model.uci".cursor()

	luci.sys.call("/etc/init.d/pppoe-server start")

	nixio.fs.remove("/etc/pppoe-passwd")

	repeat
		os.execute("sleep 2")
		num = num + 1
		status = nixio.fs.access("/etc/pppoe-passwd")
	until status or num==4

	if (status) then
		f = io.open("/etc/pppoe-passwd", "r")
		f_protocol = f:read() or ""
		f_user = f:read() or ""
		f_passwd = f:read() or ""
		f:close()

		f_protocol = string.sub(f_protocol, 10, -1)
		if f_user and f_passwd then
			f_user = string.sub(f_user, 6, -1)
			f_passwd = string.sub(f_passwd, 8, -1)
			uci_t:set("network", "wan", "username", f_user)
			uci_t:set("network", "wan", "password", f_passwd)
			uci_t:save("network")
			uci_t:commit("network")
		end
	else
		f_protocol = ""
		f_user = ""
		f_passwd = ""
	end

	local info = {
		protocol = f_protocol,
		user = f_user,
		passwd = f_passwd
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(info)
end


function do_kill_pppoe_server()
	local uci_t = require "luci.model.uci".cursor()
	--若执行了找回密码功能，则默认设置为pppoe上网,自动获取dns,并关闭pppoe-server
	uci_t:set("network", "wan", "proto", "pppoe")
	uci_t:set("network", "wan", "peerdns", "1")
	uci_t:save("network")
	uci_t:commit("network")

	luci.http.redirect(luci.dispatcher.build_url("admin", "quickguide", "wireless_setting"))
end

function do_quickguide_finish()
	if luci.http.formvalue("chg2moreset") == "1" then
		luci.http.redirect(luci.dispatcher.build_url("admin", "index"))
	else
		luci.template.render("quickguide/quickguide_finish")
	end
end
