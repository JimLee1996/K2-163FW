--[[
Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

DISCREPTION   : 自动升级
AUTHOR        : jiajian,lv <jiajian.lv@phicomm.com.cn>
CREATED DATE  : 2016-05-24
MODIFIED DATE :
]]--

module("luci.controller.admin.autoupgrade", package.seeall)

local util = require "luci.util"
local sys  = require "luci.sys"
local fs  = require "nixio.fs"
local uci_t = require("luci.model.uci").cursor()
local scheduletask = require"luci.tools.scheduletask"

function index()
    local page
    page = entry({"admin", "more_sysset", "autoupgrade"}, call("auto_up"), _("autoupgrade"), 81)
    entry({"admin", "more_sysset", "autoupgrade", "save"}, call("save"), nil, nil)
    entry({"admin", "more_sysset", "autoupgrade", "recheck"}, call("recheck"), nil, nil)
    entry({"admin", "more_sysset", "autoupgrade", "upgrade"}, call("upgrade"), nil, nil)
end

function auto_up()
    local upgrading = "1"
    local up_type = uci_t:get("system","autoupgrade","up_type")
    local mode = "0"

    if up_type == "0" then
        mode = "1"
    elseif up_type == "1" then
        mode = "0"
    end
    luci.sys.addhistory("autoupgrade")
    luci.template.render("autoupgrade",{
        mode = mode,
        upgrading = upgrading
    })
end

function upgrade()
    local info = {
        upgrading = "0",
        err = "0"
    }

    local prompts = {
        [1] = "0",
        [2] = "检测不到版本",
        [3] = "下载固件失败",
        [4] = "非法固件",
    }

    luci.sys.call("ubus call tr069 check_upgrade > /dev/null")

    local retstate = uci_t:get("onekeyupgrade","config","retState")
    local errcode = uci_t:get("onekeyupgrade","config","ErrorCode")

    if retstate == "1" and errcode == "0" then
        local url = uci_t:get("onekeyupgrade","config","newurl") or ""
        local size = uci_t:get("onekeyupgrade","config","Size") or "0"
        if url == "" then
            info.upgrading = "0"
            info.err = prompts[2]
        else
            local ret = os.execute(". /lib/loadbin.sh %q %q" % {url,size})
            local imgname = "/tmp/"..string.match(url,".+/(.+)")
            if ret == 0 then
                ret = sys.firmware.check_image(imgname)
                if ret == 0 then
                    sys.firmware.system_upgrade(imgname)
                    info.upgrading = "1"
                    info.err = prompts[1]
                else
                    luci.sys.call("rm -rf %s" % imgname)
                    info.upgrading = "0"
                    info.err = prompts[4]
                end
            else
                luci.sys.call("rm -rf %s" % imgname)
                info.upgrading = "0"
                info.err = prompts[3]
            end
        end
    else
        info.upgrading = "0"
        info.err = prompts[2]
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

function save()
    local time = luci.http.formvalue("autoUpTime")
    local mode = luci.http.formvalue("mode")
    local upgrading = "1"

    if mode == "1" then
        luci.sys.call("uci set system.autoupgrade.up_time=%s" % time)
        luci.sys.call("uci set system.autoupgrade.up_type=0")
        luci.sys.call("uci commit system")

        scheduletask.settaskatr("system", "autoupgrade", "/lib/auto_upgrade.sh", "yes", "10","up_time")
        scheduletask.cfgscdutskbylua("add","system","autoupgrade")
    elseif mode == "0" then
        luci.sys.call("uci set system.autoupgrade.up_type=1")
        luci.sys.call("uci commit system")
        scheduletask.cfgscdutskbylua("del","system","autoupgrade")
    end
    
    luci.http.redirect(luci.dispatcher.build_url("admin","more_sysset","autoupgrade"),{
        mode=mode,
        upgrading = upgrading
        })
end

function recheck()
	local verdesc

    luci.sys.call("ubus call tr069 check_upgrade > /dev/null")
    local info = {
        retstate = "",
        errcode = "",
        version = "",
        detaile = ""
    }
    info.retstate = uci_t:get("onekeyupgrade","config","retState") or "0"
    info.errcode = uci_t:get("onekeyupgrade","config","ErrorCode") or "8802"
    info.version = uci_t:get("onekeyupgrade","config","newversion") or "0.0.0.0"
	verdesc = fs.readfile("/tmp/verdesc")
	if verdesc ~= nil then
		info.detaile = verdesc:gsub("\\","\\\\") or "#x65b0#x7248#x672c#x53d1#x5e03"
	end
    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

