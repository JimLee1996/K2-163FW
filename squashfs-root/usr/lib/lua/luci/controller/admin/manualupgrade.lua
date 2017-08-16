--[[
Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

DISCREPTION   : 手动升级
AUTHOR        : xiongyi.ouyang <xiongyi.ouyang@phicomm.com.cn>
CREATED DATE  : 2016-05-11
MODIFIED DATE :
]]--

module("luci.controller.admin.manualupgrade", package.seeall)

local util = require "luci.util"
local sys  = require "luci.sys"

function index()
	local page
	entry({"admin", "more_sysset"}, alias("admin", "more_sysset", "manualupgrade"), _("manualupgrade"), 90)
	page = entry({"admin", "more_sysset", "manualupgrade"}, call("man_up"), _("manualupgrade"), 82)
end

local uci    = require "luci.model.uci"
local cur = uci.cursor()
local upgrade_section = cur:get_all("system","upgrade")
local TIME_TO_WAIT = 120000

if upgrade_section then
	TIME_TO_WAIT = tonumber(upgrade_section.wait_time)
end

function man_up()
	local image_tmp = "/tmp/fw.bin"
	local fp

	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta and meta.name == "image" then
					fp = io.open(image_tmp, "w")
				else
					fp = io.open("/tmp/restore_encode", "w")
				end
			end
			if chunk then
				fp:write(chunk)
			end
			if eof then
				fp:close()
			end
		end
	)

	local img_name
	local prompt = nil
	local upgrading = "0"
	local step = tonumber(luci.http.formvalue("step") or 0)
	local rc

	img_name = luci.http.formvalue("img_name") or nil

	if step == 0 then -- 打开页面
		luci.sys.addhistory("manualupgrade")
		prompt = nil
	elseif step == 1 then -- 提交固件
		rc, prompt = sys.firmware.check_image(image_tmp)

		if rc == 0 then
			sys.firmware.system_upgrade(image_tmp)
			upgrading = "1";
		else
			luci.util.exec("rm %q" % image_tmp)
		end
	end

	luci.template.render("manualupgrade", {
		step = step,
		prompt = prompt,
		img_name = img_name,
		upgrading = upgrading,
		wait_time = tonumber(TIME_TO_WAIT/1000),
	})
end
