--[[
Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

DISCREPTION   : 策略升级
AUTHOR        : maoyuan.li <maoyuan.li@phicomm.com.cn>
CREATED DATE  : 2016-06-02
MODIFIED DATE :
]]--

module ("luci.controller.admin.schemeupgrade",package.seeall)
local dispatcher = require "luci.dispatcher"
local uci_t = require "luci.model.uci".cursor()
local sys = require "luci.sys"

function index()
    local page
    page = entry({"admin", "more_schemeupgrade"}, template("schemeupgrade/upgrade"), _("schemeupgrade"), 78)
    page = entry({"admin", "more_schemeupgrade", "download"}, call("action_schemeupgrade"), _("schemeupgrade"), 78)
end
function action_schemeupgrade()                                                    
    local rc                                                                       
    local retval=0                                                                 
    local upgrading="0"                                                            
    local firmurl = uci_t:get("schemeupgrade", "config", "firmurl");               
    local filesize= uci_t:get("schemeupgrade", "config", "filesize");
    os.execute("chmod +x /lib/loadbin.sh")                                       
    local cmd="/lib/loadbin.sh %s %s" % {firmurl,filesize}                       
    local retval=os.execute(cmd);                                                
    local image_tmp="/tmp/"..string.match(firmurl,".+/(.+)")                     
    if retval == 0 then                                           
        rc=sys.firmware.check_image(image_tmp);                   
        if rc == 0 then                                           
            sys.firmware.system_upgrade(image_tmp);               
            upgrading = "1";                              
		else
			upgrading = "2";
        end
    end
	local retval = {
		status = upgrading
	}
	luci.http.prepare_content("application/json")
	luci.http.write_json(retval)
end
