module("luci.controller.admin.upgradefromapp", package.seeall)

local util = require "luci.util"
local sys  = require "luci.sys"
local fs   = require("nixio.fs")
require "luci.json"

local uci    = require "luci.model.uci"
local cur = uci.cursor()
local upgrade_section = cur:get_all("system","upgrade")
local TIME_TO_WAIT = 120000

if upgrade_section then
	TIME_TO_WAIT = tonumber(upgrade_section.wait_time)
end

function index()
	entry({"admin", "app_upgrade"},  alias("admin", "app_upgrade", "upload"), _("app_upgrade"), 87)
	entry({"admin", "app_upgrade", "upload"}, call("upload"), _("upload"), 88)
	entry({"admin", "app_upgrade", "upgrade"}, call("upgrade"), _("upgrade"), 89)
end

function upgrade()
	local image_tmp = "/tmp/fw.bin"
	local rc = 0
	local prompt = nil
	local wait_time = nil

	if fs.access(image_tmp) then
		rc, prompt = sys.firmware.check_image(image_tmp)
		if rc == 0 then
			sys.firmware.system_upgrade(image_tmp)
			wait_time = TIME_TO_WAIT
		else
			luci.util.exec("rm %q" % image_tmp)
		end
	else
		rc = 5
		prompt = sys.firmware.prompts[tonumber(rc)]
	end

	local info = {
		err_msg = prompt or luci.json.null,
		err_code = rc,
		wait_time = wait_time or luci.json.null,
	}
	luci.http.prepare_content("application/json")
	info = luci.json.encode(info)
	luci.http.write(info)

end

function upload()
	local image_tmp = "/tmp/fw.bin"
	local fp

	if fs.access(image_tmp) then
		fs.unlink(image_tmp)
	end

	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta then
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

	local prompt = nil
	local rc
	local action = luci.http.formvalue("action")

	if action ~= "upload" then
		rc = 4
	else
		if fs.access(image_tmp) then
			rc, prompt = sys.firmware.check_image(image_tmp)
		else --没有上传文件
			rc = 4
			prompt = sys.firmware.prompts[tonumber(rc)]
		end
	end
	if fs.access(image_tmp) and rc ~= 0 then
		fs.unlink(image_tmp)
	end

	local info = {
		err_msg = prompt or luci.json.null,
		err_code = rc,
	}
	luci.http.prepare_content("application/json")
	info = luci.json.encode(info)
	luci.http.write(info)

end
