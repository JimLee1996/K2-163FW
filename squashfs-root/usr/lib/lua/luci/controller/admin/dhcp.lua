--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - dhcp support
    AUTHOR        : chong.zhao <chong.zhao@phicomm.com.cn>
    CREATED DATE  : 2016-04-29
    MODIFIED DATE : 
]]--
local io     = require "io"
local nixio  = require "nixio" 
local fs     = require "nixio.fs"
local uci    = require "luci.model.uci"
local vendor = require "luci.vendor"
local sys    = require "luci.sys"
local status = require "luci.tools.status"

module("luci.controller.admin.dhcp", package.seeall)

function index()
	local page

	page = entry({"admin", "more_wanset", "dhcp"}, template("dhcp_server"), _("dhcp"), 12)
	page = entry({"admin", "more_wanset", "dhcp","set"}, call("global_setting"), nil,nil)
	page = entry({"admin", "more_wanset", "dhcp","bind"}, call("dhcp_bind_action"), nil,nil)
	page = entry({"admin", "more_wanset", "dhcp","rename"}, call("rename"), nil,nil)
	page.leaf = true
end

--返回值
--@clients:表示当前dhcp lease file文件中的用户信息
--@clients_bound:表示已经绑定的dhcp列表信息
function client_list()
	local cur = uci.cursor()
	local clients,clients_bound
	local leases = status.dhcp_leases()

	for _,lease in ipairs(leases) do
		local client = lease
		clients = clients or {}

		client.is_bind = 0
		client.hostname = lease.hostname or "Unknown"
		client.macaddr = string.upper(client.macaddr)

		--dhcp客户端列表中的名称要跟已配置的common_host中的设备名保持一致
		local section_name = string.gsub(client.macaddr,":","_")
		local common_section = cur:get_all("common_host",section_name)
		if common_section ~= nil then
			client.hostname = common_section.hostname
		end

		cur:foreach("dhcp","host",function(cli)
			if cli.mac == client.macaddr and cli.ip == client.ipaddr then
				client.is_bind = 1
			end
		end)
		client.icon = vendor.icon_path_by_mac(client.macaddr)
		clients[#clients+1] = client
    end

	cur:foreach("dhcp","host",function(cli)
		clients_bound = clients_bound or {}
		local c = {
			icon		=	vendor.icon_path_by_mac(cli.mac),
			ipaddr		=	cli.ip,
			macaddr		=	cli.mac,
			hostname	=	cur:get("common_host",string.gsub(cli.mac,":","_"),"hostname") or "Unknown"
		}

		clients_bound[#clients_bound+1] = c
	end)

	return clients or {} , clients_bound or {}
end

--获取dhcp server的全局配置
function dhcp_server_config()
	local cur = uci.cursor()
	local lan,config
	lan = cur:get_all("dhcp","lan")
	if lan ~= nil then
		config = {
			["switch"]		= tonumber(lan.dynamicdhcp) or 1,
			["start"]		= tonumber(lan.start),
			["ending"]		= tonumber(lan.start) + tonumber(lan.limit) - 1
		}
	end
	return config
end

--对dhcp server进行设置
function global_setting()
	local switch,start,ending,limit
	local cur = uci.cursor()
	local lan

	lan = cur:get_all("dhcp","lan")

	switch = luci.http.formvalue("switch")
	if switch == "1" then
		start = luci.http.formvalue("start") or 100
		ending = luci.http.formvalue("end") or luci.http.formvalue("ending") or 250
		limit = tonumber(ending) - tonumber(start) + 1
		lan.start = start
		lan.limit = limit
	end
	lan.dynamicdhcp = switch
	cur:tset("dhcp","lan",lan)
	cur:save("dhcp")
	cur:commit("dhcp")
	cur:apply("dhcp")
	luci.sys.addhistory("dhcp")
	luci.http.redirect(
		luci.dispatcher.build_url("admin","more_wanset","dhcp")
	)
end

function rename()
	local info = {
		status = 0,
		message = "操作成功"
	}
	rename_host()

	luci.http.prepare_content("application/json")
	luci.http.write_json(info)
end

--[[
	函数功能：重新命名设备的hostname,需要从页面获取参数
	@hostname：设备名
	@macaddr：设备mac地址
]]--
function rename_host()
	local hostname,macaddr
	local section_name
	local cur = uci.cursor()

	hostname = luci.http.formvalue("hostname") or luci.http.formvalue("deviceName")
	macaddr = luci.http.formvalue("macaddr") or luci.http.formvalue("mac")

	section_name = string.gsub(macaddr,":","_")
	cur:section("common_host","host",section_name,{hostname=hostname})
	cur:save("common_host")
	cur:commit("common_host")
end

--[[
	函数功能：dhcp 客户端ip/mac绑定操作执行函数,需要从页面获取参数
	@action：执行动作，bind->表示添加一对新的ip/mac绑定,
			modify->表示修改现有的一条绑定记录，此时需要页面传递参数original_mac
			delete->表示删除已有的一条绑定记录,此时只需要页面传递参数original_mac
			rename->表示重命名hostname，如果该记录已绑定，需传递original_mac
	@ipaddr：页面传递需要绑定的ip地址，action=bind和modify时必须
	@macaddr：页面传递需要绑定mac地址，action=bind和modify时必须
	@hostname：页面需要传递绑定的hostname，action=bind和modify时必须
	@original_mac：当action=bind和modify时必须
]]--
function dhcp_bind_action()
	local action
	local ip,mac,hostname,original_mac
	local cur = uci.cursor()
	local cur_section
	local status = 0
	local msg = "操作成功"
	local info

	action = luci.http.formvalue("action")
	ip = luci.http.formvalue("ipaddr")
	mac = luci.http.formvalue("macaddr")
	hostname = luci.http.formvalue("hostname")

	if action ~= "bind" then --修改/删除一条绑定,或者重命名设备的hostname
		original_mac = luci.http.formvalue("original_mac")
		cur:foreach("dhcp","host",function(h)
			if h.mac == original_mac then
				cur_section = h
			end
		end)
		if cur_section == nil then
			if action == "modify" then 
				status = 1
				msg = "修改失败，该记录不存在"
			elseif action == "delete" then
				status = 2
				msg = "删除失败，该记录不存在"
			else --action==rename,对未绑定的设备重命名
				rename_host()
			end
		else
			cur:delete("dhcp",cur_section[".name"])
			local section_name = string.gsub(original_mac,":","_")

			if action == "modify" or action == "rename" then
				cur_section = nil
				cur:foreach("dhcp","host",function(h)
					if h.mac == mac or h.ip == ip then
						cur_section = h
					end
				end)
				if cur_section == nil then
					cur:section("dhcp","host",nil,{ip=ip,mac=mac})
					rename_host()
				else
					status = 3
					msg = "绑定失败，绑定记录与已有记录冲突"
				end
			end
		end
	else--添加新的绑定
		cur:foreach("dhcp","host",function(h)
			if h.mac == mac or h.ip == ip then
				cur_section = h
			end
		end)

		--新的绑定跟现有记录冲突
		if cur_section ~= nil then
			status = 4
			msg = "绑定失败，绑定记录跟现有记录冲突"
		else 
			cur_section = cur:section("dhcp","host",nil,{ip=ip,mac=mac})
			rename_host()
		end
	end

	if status == 0 then
		cur:save("dhcp")
		cur:commit("dhcp")
		cur:apply("dhcp")

		if action == "delete" or action == "modify" then
			cur:save("common_host")
			cur:commit("common_host")
		end
	end

	info = {
		status = status,
		message = msg
	}

	luci.sys.addhistory("dhcp")
	luci.http.prepare_content("application/json")
	luci.http.write_json(info)
--[[
	luci.http.redirect(
		luci.dispatcher.build_url("admin","more_wanset","dhcp")
	)
]]--
end
