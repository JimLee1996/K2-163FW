--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - portfwdSet support
    AUTHOR        : shijie.gao <shijie.gao@phicomm.com.cn>
    CREATED DATE  : 2016-05-12
    MODIFIED DATE :
]]--

local uci = require "luci.model.uci"
local sys = require "luci.sys"
local fs =  require "nixio.fs"
local uci = require("luci.model.uci").cursor()

module("luci.controller.admin.appportfwdset", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/appportfwd") then
        return
    end

    local page

    page = entry({"admin", "more_forward", "appportfwdset"}, template("appportfwd"), _("appportfwd"), 70)
    entry({"admin", "more_forward", "appportfwdset", "edit"}, call("edit_rule"), nil, nil).leaf = true
    entry({"admin", "more_forward", "appportfwdset", "dele"}, call("dele_rule"), nil, nil).leaf = true
    entry({"admin", "more_forward", "appportfwdset", "set"}, call("enable_setting"), nil, nil).leaf = true
    entry({"admin", "more_forward", "appportfwdset", "portcheck"}, call("check_port"), nil, nil).leaf = true
end

function fetch_rule()
	local uci_t = uci.cursor()
	local fwdrule ={}
	uci_t:foreach("appportfwd", "setting", function(s)
		local c ={
			name = s.name,
			exterport = s.exterport,
			serverip = s.serverip,
			interport = s.interport,
			proto = s.proto
		}
		fwdrule[#fwdrule+1] = c
	end)
	return fwdrule or {}
end

function check_port(exterport, interport, line, curproto)
	local num = 0
	local startport = 0
	local endport = 0
	local remoteenable = -1
	local remoteport = -1
	local rv = { }
	local ports = luci.util.split(exterport,"-")
	startport = tonumber(ports[1]);
	if(ports[2]) then
		endport = tonumber(ports[2])
	else
		endport = startport
	end
	line = tonumber(line)

	remoteenable = luci.util.exec("uci get remote.remote.remote_enable")
	remoteenable = tonumber(remoteenable)
	if remoteenable == 1 then
		remoteport = luci.util.exec("uci get remote.remote.remote_port")
		remoteport = tonumber(remoteport)
	end
	uci:foreach("appportfwd", "setting", function(s)
		num = num +1
	end)
	if num == 0 then
		if remoteenable == 1 then
			if startport <= remoteport and endport >= remoteport then
				rv[#rv+1] = {
					checkerror = 2,
				}
			end
		end
	else
	for i = 0, num -1 do
		exterport = luci.util.exec("uci get appportfwd.@setting[%q].exterport" % i)
		local ports = luci.util.split(exterport, "-")
		sport = tonumber(ports[1])
		if(ports[2]) then
			eport = tonumber(ports[2])
		else
			eport = sport
		end
		checkproto = luci.util.exec("uci get appportfwd.@setting[%q].proto" % i)
		checkproto = string.sub(checkproto,1,#checkproto-1)

		if remoteenable == 1 then
			if startport <= remoteport and endport >= remoteport then
				rv[#rv+1] = {
					checkerror = 2,
				}
				break
			end
		end

		if line ~= i+1 then
			if startport <= sport and endport >= sport then
				if curproto == "tcp+udp" or curproto == checkproto or checkproto == "tcp+udp" then
					rv[#rv+1] = {
						checkerror = 1,
					}
					break
				end
			end
			if startport >= sport and endport <= eport then
				if curproto == "tcp+udp" or curproto == checkproto or checkproto == "tcp+udp" then
					rv[#rv+1] = {
						checkerror = 1,
					}
					break
				end
			end
			if startport >= sport and startport <= eport and endport >= eport then
				if curproto == "tcp+udp" or curproto == checkproto or checkproto == "tcp+udp" then
					rv[#rv+1] = {
						checkerror = 1,
					}
					break
				end
			end
		end
	end
	end
	if #rv > 0 then
		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)
	end
end

function edit_rule(line, name, exterport,serverip, interport, proto)
	local count = 0
	local section
	local line = tonumber(line)
	local portfwd_enable = uci:get("appportfwd", "config", "enable")
	if line then
	uci:foreach("appportfwd", "setting",
		function(s)
			count = count + 1
			if count == line then
				section = s[".name"]
				return false
			end
	end)
	else
		section = uci:add("appportfwd", "setting")
	end
	uci:set("appportfwd", section, "name", name)
	uci:set("appportfwd", section, "exterport", exterport)
	uci:set("appportfwd", section, "serverip", serverip)
	uci:set("appportfwd", section, "interport", interport)
	uci:set("appportfwd", section, "proto", proto)
	if portfwd_enable ~= 1 then
		uci:set("appportfwd", "config", "enable", "1")
	end
	uci:save("appportfwd")
	uci:commit("appportfwd")
	luci.util.exec("/etc/init.d/portfwd restart")
end

function dele_rule(line)
	local count = 0
	local section
	local line = tonumber(line)
	local portfwd_enable = uci:get("appportfwd", "config", "enable")
	uci:foreach("appportfwd", "setting",
		function(s)
			count = count + 1
			if count == line then
				section = s
				return false
			end
	end)
	if portfwd_enable ~= 1 then
		uci:set("appportfwd", "config", "enable", "1")
	end
	uci:delete("appportfwd", section[".name"])
	uci:save("appportfwd")
	uci:commit("appportfwd")
	luci.util.exec("/etc/init.d/portfwd restart")
end

function enable_setting()
	local switch
	switch = luci.http.formvalue("switch")
	uci:set("appportfwd", "config", "enable", switch)
	uci:commit("appportfwd")
	luci.util.exec("/sbin/luci-reload appportfwd")
	luci.sys.addhistory("appportfwdset")
	luci.http.redirect(luci.dispatcher.build_url("admin", "more_forward", "appportfwdset"))
end
