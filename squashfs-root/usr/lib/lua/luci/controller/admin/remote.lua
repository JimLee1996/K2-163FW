--[[

  Function  : module controller, remote

  Creater   : shijie.gao@feixun.com.cn, 2016-06-30

  Copyright : Shanghai Phicomm

]]--

local uci = require "luci.model.uci"
local sys = require "luci.sys"
local fs =  require "nixio.fs"
local uci = require("luci.model.uci").cursor()

module("luci.controller.admin.remote", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/remote") then
		return
	end

	local page

	page = entry({"admin", "more_remotemgt"}, template("remote"), _("remote management"), 72)
	entry({"admin", "more_remotemgt", "set"}, call("enable_setting"), nil, nil).leaf = true
	entry({"admin", "more_remotemgt", "portcheck"}, call("check_port"), nil, nil).leaf = true
end

function check_port(remoteport)
	local num = 0
	local rv = { }
	remoteport = tonumber(remoteport);
	uci:foreach("appportfwd", "setting", function(s)
		num = num + 1
	end)
	fwdenable = luci.util.exec("uci get appportfwd.config.enable")
	fwdenable = tonumber(fwdenable)
	if fwdenable == 1 then
		for i = 0, num - 1 do
			exterport = luci.util.exec("uci get appportfwd.@setting[%q].exterport" % i)
			local ports = luci.util.split(exterport, "-")
			sport = tonumber(ports[1])
			if(ports[2]) then
				eport = tonumber(ports[2])
			else
				eport = sport
			end
			if remoteport >= sport and remoteport <= eport then
				rv[#rv+1] = {
					checkerror = 1,
				}
				break
			end
		end
	end

	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
	end
end

function enable_setting()
	local switch
	switch = luci.http.formvalue("switch")
	if switch == "0" then
		uci:set("remote", "remote", "remote_enable", switch)
	else
		remport = luci.http.formvalue("remote_port")
		remip = luci.http.formvalue("remote_ip")
		uci:set("remote", "remote", "remote_enable", switch)
		uci:set("remote", "remote", "remote_ip", remip)
		uci:set("remote", "remote", "remote_port", remport)
	end
	uci:commit("remote")
	luci.util.exec("/sbin/luci-reload remote")
	luci.sys.addhistory("more_remotemgt")
	luci.http.redirect(luci.dispatcher.build_url("admin", "more_remotemgt"))
end
