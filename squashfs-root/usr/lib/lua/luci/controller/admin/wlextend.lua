module ("luci.controller.admin.wlextend",package.seeall)


function index()
    entry({"admin", "more_wlextend"}, template("admin_network/wlextend"), _("Wireless Extend Setting"), 22)
    entry({"admin", "ap_list"}, template("admin_network/ap_list"), _("ap_list"), 16)
    entry({"admin", "more_wlextend", "trial"}, call("wirTrial"), _("Wireless Extend trialing"), 17)
    entry({"admin", "more_wlextend", "wirExte"}, call("wirExte"), _("Wireless Extend Setting")).leaf = true
    entry({"admin", "more_wlextend", "reboot"}, call("reboot"), _("Wireless Extend Setting")).leaf = true
end

function wirTrial()

	local uci = require("luci.model.uci").cursor()
	local http = require("luci.http")
	local sys = require("luci.sys")
	local utl = require "luci.util"
	local phicomm_lua = require "phic"
	local apcli_lua = require "apcli"

	local enable = luci.http.formvalue("wirExte")
	luci.sys.call("killall -SIGUSR2 apcli_daemon");
	if enable == "0" then
		apcli_lua.config_normal();
	elseif enable == "1" then 
		local ssid = luci.http.formvalue("wir_ssid") or ""
		ssid = (string.gsub(ssid, "\\\"", "\""))
		local authmode = luci.http.formvalue("safeSelect") or ""
		local aptype = luci.http.formvalue("apcli_aptype") or ""
		local wpapsk = ""
		local encryp = ""
		local bssid = ""

		if authmode == "WPAPSK" or authmode == "WPA2PSK" then
			wpapsk = luci.http.formvalue("pskkey") or ""
			wpapsk = (string.gsub(wpapsk, "\\\"", "\""))
			encryp = luci.http.formvalue("encSelect") or ""
		else
			encryp = "NONE"
		end
		bssid = luci.http.formvalue("apcli_bssid") or ""
		apcli_lua.config_apcli(ssid,bssid,authmode,encryp,wpapsk,aptype);
	end
	luci.sys.updatahistory("more_wlextend")
	luci.sys.call("/etc/init.d/network enable > /dev/null; /etc/init.d/network restart > /dev/null")
	luci.http.redirect(
		luci.dispatcher.build_url("admin","more_wlextend")
	)
end

function wirExte()
	local http = require("luci.http")
	local sys = require("luci.sys")
	local utl = require "luci.util"
	local phicomm_lua = require "phic"
	local apcli_lua = require "apcli"
	local enable = luci.http.formvalue("wirExte")
	if enable == "0" then
		apcli_lua.config_normal();
	else
		local ssid = luci.http.formvalue("wir_ssid") or ""
		--传输过程中需要为双引号添加反斜杠，在这里要去掉
		ssid = (string.gsub(ssid, "\\\"", "\""))
		local authmode = luci.http.formvalue("safeSelect") or ""
		--local aptype = luci.http.formvalue("apcli_aptype") or ""
		local aptype = "0"
		local wpapsk = ""
		local encryp = ""
		local bssid = ""
		local tmp = {
			result = "0"
		}
		local rv = {}

		if authmode == "WPAPSK" or authmode == "WPA2PSK" then
			wpapsk = luci.http.formvalue("pskkey") or ""
			wpapsk = (string.gsub(wpapsk, "\\\"", "\""))
			encryp = luci.http.formvalue("encSelect") or ""
		else
			encryp = "NONE"
		end
		bssid = luci.http.formvalue("apcli_bssid") or ""
		--在包含特殊字符的情况下这里是不能这样打印的，会出问题
		--luci.sys.call("echo ssid: \"%s\" bssid: \"%s\" authmode:\"%s\" encryp: \"%s\" wpapsk: \"%s\" aptype: \"%s\" > /dev/console" % {ssid, bssid, authmode, encryp, wpapsk, aptype})
		tmp = apcli_lua.config_apcli(ssid,bssid,authmode,encryp,wpapsk,aptype)
		local data = {
			result = tmp.result
		}
		rv[#rv+1] = data
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
	end
	luci.sys.updatahistory("more_wlextend")
end

function reboot()
	local sys = require("luci.controller.admin.system")
	sys.fork_exec("/etc/init.d/network enable > /dev/null; /etc/init.d/network restart > /dev/null")
end
