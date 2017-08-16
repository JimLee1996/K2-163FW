--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - upnpset support
    AUTHOR        : shijie.gao <shijie.gao@phicomm.com.cn>
    CREATED DATE  : 2016-05-06
    MODIFIED DATE :
]]--

module("luci.controller.admin.UPnP", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/UPnP") then
        return
    end

    local page

    entry({"admin", "more_forward"}, alias("admin", "more_forward", "UPnPset"), _("UpnpSet"), 77)
    page = entry({"admin", "more_forward", "UPnPset"}, cbi("Upnp_config",{autoapply=true}), _("UpnpSet"), 78)
    entry({"admin", "more_forward", "UPnPset" , "status"}, call("act_status")).leaf = true
    page.dependent = true
end

local function upnp_get_record()
        local t = {}
        local util = require "luci.util"
        local cur = require "luci.model.uci".cursor()
        local leasefile = cur:get("upnpd", "config", "upnp_lease_file")
        if not leasefile then
                leasefile = "/var/upnp.leases"
        end
        if leasefile then
                local fd = io.open(leasefile, "r")
                if fd then
                        while true do
                                local ln = fd:read("*l")
                                if not ln then
                                        break
                                end
                                local tmp = util.split(ln, ":")
                                if not tmp or #tmp ~= 6 then
                                        t = {}
                                        break
                                end
                                t[#t+1] = tmp
                        end
                end
        end

        return t
end

function act_status()                                                         
        local ipt = io.popen("iptables --line-numbers -t nat -xnvL MINIUPNPD")
        local entry = upnp_get_record()                                
        if ipt then                                           
                local fwd = { } 
                local number = 0                 
                while true do                    
                        local ln = ipt:read("*l")
                        if not ln then              
                                break                                        
                        elseif ln:match("^%d+") then                                          
                                local num, proto, extport, intaddr, intport =                 
                                        ln:match("^(%d+).-([a-z]+).-dpt:(%d+) to:(%S-):(%d+)")
                                                                                         
                                if num and proto and extport and intaddr and intport then
                                        number = number + 1        
                                        num     = number           
                                        extport = tonumber(extport)                              
                                        intport = tonumber(intport)                         
                                                                                          
                                        fwd[#fwd+1] = {                                   
                                                num     = num,                            
                                                desc = entry[num] and entry[num][6] or "",
                                                extport = extport,      
                                                proto   = proto:upper(),
                                                intport = intport,
                                                intaddr = intaddr,
                                                status = "1",          
                                        }
                                end           
                        end
                end        
                                                  
                ipt:close()                                  
                                                             
                luci.http.prepare_content("application/json")
                luci.http.write_json(fwd)     
        end                                  
end   