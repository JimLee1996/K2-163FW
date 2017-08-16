--[[
Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

DISCREPTION   : 策略升级
AUTHOR        : maoyuan.li <maoyuan.li@phicomm.com.cn>
CREATED DATE  : 2016-06-02
MODIFIED DATE :
]]--

module("luci.controller.schemeaction", package.seeall)

function index()
	local page
	page = entry({"schemeaction"}, call("schemeaction"), nil, 60)
end

function schemeaction()
    local uci_t = require("luci.model.uci").cursor()
	local retval = {
		status = 1
	}
	uci_t:set("schemeupgrade", "config", "up_scheme", "0")
	uci_t:save("schemeupgrade")
	uci_t:commit("schemeupgrade")
	luci.sys.call("schemeupgrade > /dev/null &")
	luci.http.prepare_content("application/json")
	luci.http.write_json(retval)
end
