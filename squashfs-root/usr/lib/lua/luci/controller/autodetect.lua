--[[
Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

DISCREPTION   : 自动上网检测
AUTHOR        : maoyuan.li <maoyuan.li@phicomm.com.cn>
CREATED DATE  : 2016-06-22
MODIFIED DATE :
]]--

module("luci.controller.autodetect", package.seeall)

function index()
	local page
	page = entry({"autodetect"}, alias("autodetect", "status"), nil, 60)
	page = entry({"autodetect", "status"}, call("autodetect_status"), nil, 60)
	page = entry({"autodetect", "trigger"}, call("autodetect_trigger"), nil, 60)
end

function autodetect_status()
    local uci_t = require("luci.model.uci").cursor()
    local status = "0"
    if not nixio.fs.access("/tmp/autonetwork.lock") then
        status = "1"
    end
	local retval = {
		val = status
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(retval)
end
function autodetect_trigger()
    luci.sys.call("autonetwork > /dev/null &")
	local retval = {
		val = 1
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(retval)
end
