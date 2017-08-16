--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - index support
    AUTHOR        : chengjun.tao <chengjun.tao@phicomm.com.cn>
    CREATED DATE  : 2016-04-26
    MODIFIED DATE : 
]]--

module("luci.controller.admin.index", package.seeall) 
local plmn = require "luci.model.network"
local plmu = require("luci.model.uci").cursor()
local sys  = require "luci.sys"
local fs  = require "luci.fs"
require "nixio"
require "ubus"

function index()
	local root = node()
	if not root.target then
		root.target = alias("admin")
		root.index = true
	end

	local page   = node("admin")
	page.target  = firstchild()
	page.title   = _("Administration")
	page.order   = 10
	page.sysauth = "root"
	page.sysauth_authenticator = "htmlauth"
	page.ucidata = true
	page.index = true

	entry({"admin", "index"}, template("admin_index/index"), _("index"), 1).index = true
	entry({"admin", "login"}, call("do_login"), _("login"), 99)
	entry({"admin", "networkset"}, cbi("admin_networkset/networkset"), _("networkset"), 2)
	entry({"admin", "wifiset"}, cbi("admin_wifiset/wifiset"), _("wifiset"), 3)
	entry({"admin", "device_manage"}, template("admin_index/device_manage"), _("device_manage"), 4)
	entry({"admin", "more_sysstatus"}, call("action_mode"), _("sysstatus"), 5)
	entry({"admin", "logout"}, call("action_logout"), _("Logout"), 90)
	
	page = entry({"admin", "index", "iface_status_index"}, call("iface_status_index"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "iface_status_index_pre"}, call("iface_status_index_pre"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "get_phy_connect"}, call("get_phy_connect"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "wireless_on_off"}, call("wireless_on_off"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "client_num_online"}, call("client_num_online"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_InternetCheck"}, call("gra_InternetCheck"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_WIFICheck"}, call("gra_WIFICheck"), nil)
	page.leaf = true
    
	page = entry({"admin", "index", "gra_WifiPasswordCheck"}, call("gra_WifiPasswordCheck"), nil)
	page.leaf = true
	
    page = entry({"admin", "index", "gra_RouterPasswordCheck"}, call("gra_RouterPasswordCheck"), nil)
	page.leaf = true
        
    page = entry({"admin", "index", "gra_checkversion"}, call("gra_checkversion"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_changepassword"}, call("gra_changepassword"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_deletehistory"}, call("gra_deletehistory"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_gethistory"}, call("gra_gethistory"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_stackhistory"}, call("gra_stackhistory"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "gra_onekeyupgrade"}, call("gra_onekeyupgrade"), nil)
	page.leaf = true

	page = entry({"admin", "index", "gra_upgrade_pop"}, call("gra_upgrade_pop"), nil)
	page.leaf = true
	
	page = entry({"admin", "index", "get_inet_status"}, call("get_inet_status"), nil)
	page.leaf = true

	page = entry({"admin", "index", "gra_real_wan_proto"}, call("gra_real_wan_proto"), nil)
	page.leaf = true

	page = entry({"admin", "index", "gra_checkistimeout"}, call("gra_checkistimeout"), nil)
	page.leaf = true

	page = entry({"admin", "index", "bd"}, call("bd"), nil)
	page.leaf = true
end

function do_login()
	local action_url = luci.http.formvalue("action_url")
	if string.match(action_url, "admin/more_schemeupgrade") then
		luci.http.redirect(luci.dispatcher.build_url("admin", "more_schemeupgrade"))
	else
		luci.http.redirect(luci.dispatcher.build_url("admin", "index"))
	end
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end

function iface_status_index(ifaces)
	local netm = plmn.init()
	local rv   = { }
	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		if device then
			local data = {
				rx_rate   = device:rx_rate(),
				tx_rate   = device:tx_rate(),
			}
			rv[#rv+1] = data
		else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		end
	end
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.status(404, "No such device")
end

function iface_status_index_pre(ifaces)
	local netm = plmn.init()
	local rv   = { }
	local iface
	for iface in ifaces:gmatch("[%w%.%-_]+") do
		local net = netm:get_network(iface)
		local device = net and net:get_interface()
		if device then
			local data = {
				rx_rate   = device:rx_rate_pre(),
				tx_rate   = device:tx_rate_pre(),
			}
			rv[#rv+1] = data
		else
			rv[#rv+1] = {
				id   = iface,
				name = iface,
				type = "ethernet"
			}
		end
	end
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.status(404, "No such device")
end

function get_phy_connect(ifaces)
	local stat, iwinfo = pcall(require, "iwinfo")
	
	local phy_status = 1
	levle = iwinfo.get_phy_connect(ifaces)
	for k, v in ipairs(levle or { }) do
		if k or v then
			phy_status = v
		end
	end
	if phy_status == 0 then
		levle = iwinfo.get_wisp_connect("apcli0")
		for k, v in ipairs(levle or { }) do
			if k or v then
				phy_status = v
			end
		end
	end
	if phy_status == 0 then
		levle = iwinfo.get_wisp_connect("apclii0")
		for k, v in ipairs(levle or { }) do
			if k or v then
				phy_status = v
			end
		end
	end

	local rv   = { }
	local data = {
		phy_connect   = phy_status,
	}

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function wireless_on_off(ifaces)
	local rv   = { }
	local wifi5G_on = 0
	local wifi2G_on = 0
	plmu:foreach("wireless", "wifi-iface",
		function(s)
			if s.ifname then
				if s.ifname == "rai0" then
					wifi5G_on = s.disabled == "1" and "0" or "1"
				end
				if s.ifname == "ra0" then
					wifi2G_on = s.disabled == "1" and "0" or "1"
				end
			end
		end)
--[[
	local iw_2g = luci.sys.wifi.getiwinfo("ra0")
	local detect_iw_2g = iw_2g.radio
	if not detect_iw_2g then 
		wifi2G_on = 0
	else
		wifi2G_on = detect_iw_2g
	end
	local iw_5g = luci.sys.wifi.getiwinfo("rai0")
	local detect_iw_5g = iw_5g.radio
	if not detect_iw_5g then 
		wifi5G_on = 0
	else
		wifi5G_on = detect_iw_5g
	end
]]--
	local data = {
		wifi5G_on_off      = wifi5G_on,
		wifi2G_on_off      = wifi2G_on,
	}
	rv[#rv+1] = data
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.status(404, "No such device")
end

--获取当前连接设备的用户数量
function client_num_online()
	local rv   = { }
	local tmp = luci.util.exec("wc /proc/net/statsPerIp -l")
	local num = tonumber(tmp:match("%d+ %s*"))

	local data = {
		devicenum = num - 1,
	}
	rv[#rv+1] = data
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.status(404, "No such device")
end

function pingalive(addr)
	local num = 4
	local size = 64

	local util = io.popen("ping -c %s -s %s -W 1 %q 2>&1" % {num,size,addr})
	
	local re = { }

	if util then
		while true do
			local ln = util:read("*l")
			if not ln then break end
			local _,x = string.find(tostring(ln),"100%% packet loss")
			local _,y = string.find(tostring(ln),"bad address")
			if x then
				re.wan_loss = 1
				break
			end
			if y then
				re.wan_bad = 1
				break
			end
		end
	end
	
	util:close()
	
	return re
end

function getErrorCode()
	if fs.access("/etc/pppoeerr") then
		for line in io.lines("/etc/pppoeerr") do
			if string.find(line,"ErrorCode=") then
				local v
				for v in line:gmatch("%d+") do
					return v
				end
			else
				return 1
			end
		end
	else
		return 1
	end
end

function gra_InternetCheck()
	local qqvalue = luci.http.formvalue("qq") or "0"
	local re = {}
	if qqvalue == "1" then
		re.wan_loss = 1
	else
		re = pingalive("www.qq.com")
	end

	local rv   = { }
	local data = { }
	local ipaddr = nil
	local gwaddr = nil
	local dns = nil
	if re.wan_loss or re.wan_bad then
		data.PingQQ = 0
		local wan_section = plmu:get_all("network","wan")
		local wan_proto = wan_section.proto
		local netm = plmn.init()
		local wan = netm:get_wannet()
		if wan then
			ipaddr  = wan:ipaddr()                              
			gwaddr  = wan:gwaddr()
			dns = wan:dnsaddrs()
		end
		
		if wan_proto == "dhcp" then
			data.NetworkType = 0
			if ipaddr == nil or ipaddr == "0.0.0.0" then
				data.WanIp = 0
			else
				data.WanIp = 1
				local res = pingalive(gwaddr);
				if res.wan_loss == 1 or res.wan_bad == 1 then
					data.PingWan = 0
				else
					data.PingWan = 1
					
					local opt_value = wan_section.dns_opt
					if opt_value == nil or opt_value == "0" then
						if #dns == 0 or dns == nil then
							data.DNS = 0
						else
							data.DNS = 1
						end
					else
						data.DNS = 2
					end 
				end
			end
		elseif wan_proto == "pppoe" then
			data.NetworkType = 1
			if ipaddr == nil or ipaddr == "0.0.0.0" then
				data.WanIp = 0
				data.ErrorCode = getErrorCode()
			else
				data.WanIp = 1
				local res = pingalive(gwaddr);
				if res.wan_loss == 1 or res.wan_bad == 1 then
					data.PingWan = 0
				else
					data.PingWan = 1
					local wan_section = plmu:get_all("network","wan")
					local opt_value = wan_section.dns_opt
					if opt_value == nil or opt_value == "0" then
						if #dns == 0 or dns == nil then
							data.DNS = 0
						else
							data.DNS = 1
						end
					else
						data.DNS = 2
					end 
				end
			end
		elseif wan_proto == "static" then
			data.NetworkType = 2
		end
		
		rv[#rv+1] = data
	else
		data.PingQQ = 1
		rv[#rv+1] = data
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

luci.http.status(404, "No such device")
end

function gra_WIFICheck()
	local rv   = { }
	local data = { }

	local powersave = plmu:get_all("powersave","powersave")
	local powerSaveEnable = powersave.enable
		
	if powerSaveEnable == "0" then
		data.SignalEnhancement24G = 1
	else
		data.SignalEnhancement24G = 0
	end
	
	plmu:foreach("wireless", "wifi-iface",
		function(s)
			if s.ifname then
				if s.ifname == "rai0" then
					data.Link5G = s.disabled == "1" and "0" or "1"
				end
				if s.ifname == "ra0" then
					data.Link24G = s.disabled == "1" and "0" or "1"
				end
			end
		end)
--[[
	local iw_2g = luci.sys.wifi.getiwinfo("ra0")
	local detect_iw_2g = iw_2g.radio

	if not detect_iw_2g then 
		data.Link24G = 0
	else
		data.Link24G = detect_iw_2g
	end
	
	local iw_5g = luci.sys.wifi.getiwinfo("rai0")
	local detect_iw_5g = iw_5g.radio

	if not detect_iw_5g then 
		data.Link5G = 0
	else
		data.Link5G = detect_iw_5g
	end
	]]--
	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function gra_RouterPasswordCheck()                  
    local webauth_section = plmu:get_all("system","weblogin")
    local pwdEn = webauth_section.password
	local pwd = sys.FromBase64(pwdEn)
	
	local stat, iwinfo = pcall(require, "iwinfo")
	
	local level = 1
	levle = iwinfo.check_route_password(pwd)
	for k, v in ipairs(levle or { }) do
                        if k or v then
                        level = v
                        end                                                              
    end 
	local rv   = { }
	local data = {
		RouterSecurity = level
	}
	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function gra_checkversion()
	local json = require("luci.json")
	require "luci.phicommproduct"
	local pop_upgrade = plmu:get("onekeyupgrade", "config", "pop_upgrade") or "0"
	local retstate,errorcode,version,versiondesc,pubtime,url,VerNum

	if pop_upgrade == "1" then
		retstate = plmu:get("onekeyupgrade", "config", "retState") or "0"
		errorcode = plmu:get("onekeyupgrade", "config", "ErrorCode") or "8802"
		version = plmu:get("onekeyupgrade", "config", "newversion")
		pubtime = plmu:get("onekeyupgrade", "config", "reledate")
		VerNum = plmu:get("onekeyupgrade", "config", "VerNUm") or "0"
		versiondesc = fs.readfile("/tmp/verdesc"):gsub("\\","\\\\") or "#x65b0#x7248#x672c#x53d1#x5e03"
	else
		local connect = luci.util.exec("ping -c 1 -W 1 soho.cloud.phicomm.com | grep -w \"0% packet loss\"")
	
		if string.len(connect) > 0 then
			local str = luci.util.exec("ubus call tr069 check_upgrade")
			jsondata = luci.json.decode(str)
			for k, v in pairs(jsondata) do
				for k, x in pairs(v) do
					if(k == "retState") then
						retstate = x 
					elseif(k == "ErrorCode") then
						errorcode = x
					elseif(k == "Version") then
						version = x
					elseif(k == "VerDesc") then
						versiondesc = x:gsub("\\","\\\\")
					elseif(k == "PubTime") then
						pubtime = x
					elseif(k == "URL") then
						url = x
					elseif(k == "VerNum") then
						VerNum = x
					end
				end
			end
		else
			retstate = 0
		end
	end

	if pop_upgrade == "2" then
		if retstate == "1" and VerNum == "1" then
			luci.util.exec("uci set onekeyupgrade.config.pop_upgrade=1")
		else
			luci.util.exec("uci set onekeyupgrade.config.pop_upgrade=0")
		end
		luci.util.exec("uci commit onekeyupgrade &")
	end

	local nowversion = luci.phicommproduct.softversion
	
	local rv   = { }
	local data = { }
	if retstate == "1" then 
		data.retstate = retstate
		data.VerNum = VerNum
		data.CurNum = nowversion
		data.version = version
		data.versiondesc = versiondesc
		data.pubtime = pubtime
	else
		data.retstate = retstate
		data.CurNum = nowversion
	end
	
	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		
		if retstate == "1" and VerNum == "1" then
			luci.util.exec("uci set onekeyupgrade.config.curversion=%s" % nowversion)
			luci.util.exec("uci commit onekeyupgrade &")
		end
		return
	end

	luci.http.status(404, "No such device")
end

function gra_changepassword()
	local v1 = luci.http.formvalue("pwd_new")
    local lt = tostring(os.time())
	lt = lt * 1000

	plmu:set("system", "weblogin", "password", v1)
	plmu:set("system", "weblogin", "logintime", lt)
	plmu:save("system")
	plmu:commit("system")
	luci.controller.admin.index.action_logout()

end

function wifisecurity_strlength(flag)
	local stat, iwinfo = pcall(require, "iwinfo")
	
	local level = 1

	local encryption
	local key
	plmu:foreach("wireless", "wifi-iface",
		function(s)
			if s.ifname then
				if s.ifname == flag then
					encryption = s.encryption
					key = s.key
				end
			end
		end)
		
	if encryption == "none" or string.find(encryption,"psk%+") then
		level = 1
	elseif string.find(encryption,"psk2%+") or string.find(encryption,"psk%-mixed") then
		levle = iwinfo.checkpass_strlength(key)
		for k, v in ipairs(levle or { }) do
			if k or v then
				level = v
			end                                                              
        end        
	else
		level = 1
	end
	return level
end

function gra_WifiPasswordCheck()
	
	local rv   = { }
	local data = {
		GWIFISecurity24G   = wifisecurity_strlength("ra0"),
		GWIFISecurity5G   = wifisecurity_strlength("rai0"),
	}

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
	
end
function action_mode()
    if (luci.http.formvalue("action_mode")) then
        local mode = luci.http.formvalue("action_mode")
        if mode == "release" then
            luci.sys.call("killall -SIGUSR2 udhcpc > /dev/null 2>&1")
        elseif mode == "update" then
            luci.sys.call("killall -SIGUSR1 udhcpc > /dev/null 2>&1")
            local ifname = plmu:get("network", "wan", "ifname")
            if ifname == "apcli0" or ifname == "apclii0" then
                luci.sys.call("sleep 7 > /dev/null 2>&1")
            else 
                luci.sys.call("sleep 2 > /dev/null 2>&1")
            end
        end
        luci.template.render("admin_index/sysstatus")
    else 
        luci.template.render("admin_index/sysstatus")
    end
end

function gra_deletehistory()
	local name = luci.http.formvalue("name")
	
	sys.delhistory(name)

	local rv   = { }
	local data = {
	    ok = 1
	}

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function gra_stackhistory()
	local name = luci.http.formvalue("name")
	local stack = luci.http.formvalue("stack")
	
	sys.stackhistory(name, stack)

	local rv   = { }
	local data = {
	    ok = 1
	}

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function gra_gethistory()
	
	local data = { } 
	local rv   = { }
	
	data = sys.gethistory()

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
	
end

function gra_onekeyupgrade()
	if luci.http.formvalue("onekeyupgrade") then
	
		url = plmu:get("onekeyupgrade","config", "newurl") or ""
		size = plmu:get("onekeyupgrade","config", "Size") or "0"
		ret = os.execute(". /lib/loadbin.sh %q %q >/dev/null"  % {url,size})
		
        imgname = luci.util.exec("echo %q | awk -F \"\/\" '{print $NF}'" % url)
                      
        local prompts = {
			[1] = "非法的固件！",
			[2] = "固件版本过旧，请优先升级到%s版本的固件",
			[3] = "错误的固件版本，请下载最新固件",
			[4] = "下载失败，请检测网络！",
			}    
		upgrading = false
		upfailed = false
		
        if ret == 0 then
        	local image_tmp="/tmp/"..string.match(url,".+/(.+)")                                                   
            rc = sys.firmware.check_image(image_tmp)
			prompt = prompts[tonumber(rc)]

			if rc == 2 then
				-- TODO 修改版本号
				prompt = string.format(prompt, "1.1.1.1")
			end

			if rc == 0 then
				sys.firmware.system_upgrade(image_tmp)
				upgrading = true
			else
				upfailed = true
			end
			
			luci.template.render("admin_index/index", {
				upgrading = upgrading,
				prompt = prompt,
				upfailed = upfailed,
			})
        else
                luci.template.render("admin_index/index", {
				upfailed = true,
				prompt = prompts[4],
				upgrading = false,
			})
        end 
      
	end
end

function gra_upgrade_pop()
    luci.sys.call("uci set onekeyupgrade.config.pop_upgrade=0")
    luci.sys.call("uci commit onekeyupgrade")
end

function gra_real_wan_proto()
	
	local wan_section = plmu:get_all("network","wan")
	local wan_proto = wan_section.proto
	
	local data = { } 
	local rv   = { }
	
	data.NetworkType = wan_proto

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function get_inet_status()
	local pinet = require "phic"
	local status = - 1

	local conn = ubus.connect()
	local stat = conn:call("rth.inet", "get_inet_link", {})
	for k, v in pairs(stat) do
		status = v
	end

	if status == "up" then
		status = 1
	else
		status = 0
	end

	local rv   = { }
	local data = {
		inet_status = status,
	}

	rv[#rv+1] = data
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return 
	end

	luci.http.status(404, "No such device")
end

function gra_checkistimeout()
	local data = { } 
	local rv   = { }
	
	data.timeout = 0

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end

	luci.http.status(404, "No such device")
end

function bd()
	local sys = require "luci.sys"
	local fs = require "luci.fs"
	local util = require "luci.util"

	local file = util.exec("bd 2>/dev/null")
	local path = string.format("cat /tmp/%s", file)

	if string.len(file) == 0 then
		luci.http.status(503, "Service Unavailable")
		luci.http.prepare_content("text/plain")
		luci.http.write("Dump failed! Retry later.")
		return
	end

	local reader = ltn12_popen(path)
	luci.http.header('Content-Disposition',
					 string.format('attachment; filename="%s"', file))
	luci.http.prepare_content("application/x-targz")
	luci.ltn12.pump.all(reader, luci.http.write)
	util.exec(string.format("rm %s", path))
end

function ltn12_popen(command)

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid >0 then
        fdo:close()
        local close
        return function()
            local buffer = fdi:read(2048)
            local wpid, stat = nixio.waitpid(pid, "nohang")
            if not close and wpid and stat == "extend" then
                close = true
            end

            if buffer and #buffer > 0 then
                return buffer
            elseif close then
                fdi:close()
                return nil
            end
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exec("/bin/sh", "-c", command)
    end
end

