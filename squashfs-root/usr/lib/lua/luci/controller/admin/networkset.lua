--[[
	Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

	DISCREPTION   : LuCI - Lua Configuration Interface - networkSet support
	AUTHOR        : shijie.gao <shijie.gao@phicomm.com.cn>
	CREATED DATE  : 2016-05-10
	MODIFIED DATE :
]]--

module("luci.controller.admin.networkset", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/network") then
		return
	end

	local page

	page = entry({"admin", "networkset"}, cbi("admin_networkset/networkset"), _("networkset"), 10)
	page = entry({"admin", "networkset","wandetect"}, call("wan_detect"), _("networkset1"), 11)
	page = entry({"admin", "networkset","wanconnect"}, call("get_phy_connect"), _("networkset1"), 12)
	page.leaf=true
end

function wan_detect()
	luci.sys.call("autonetwork >/dev/null &")
	for i=10,1,-1
	do
		os.execute("sleep 1")
		if not nixio.fs.access("/tmp/autonetwork.lock") then
			break
		end
	end
	luci.util.exec("uci set network.wan.detectonetime=\"on\"")
	luci.util.exec("uci commit network")
	luci.http.redirect(luci.dispatcher.build_url("admin/networkset"))
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

	local rv   = { }
	local data = {
		phy_connect = phy_status,
	}

	rv[#rv+1] = data

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
		return
	end
	luci.http.status(404, "No such device")
end
