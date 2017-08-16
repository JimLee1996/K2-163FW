--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - lanSet support
    AUTHOR        : xiangjun.fu <xiangjun.fu@phicomm.com.cn>
    CREATED DATE  : 2016-08-16
    MODIFIED DATE : 
]]--

require "luci.sys"

module("luci.tools.scheduletask", package.seeall)
require"nixio.fs"
if not nixio.fs.access("/etc/config/scheduletask") then
    luci.sys.call("touch /etc/config/scheduletask > /dev/null")
end

function generaterules()
    local noreboottask = {}
    local norebootindex = 0
    local reboottask = {}
    local cur = require "luci.model.uci".cursor()
    local crontabpath = "/tmp/crontabs_root"
    local defaultrule="/rom/etc/crontabs/root"
    local tasknum = 0
    local ruleindex = 0
    local hourtimesnum = 0

    cur:foreach("scheduletask", "rule",
        function(s)
            local uci_t = require "luci.model.uci".cursor()
            local actionstr = uci_t:get("scheduletask", s['.name'], "action")
            local timestr = uci_t:get("scheduletask", s['.name'], "timestr")
            local rebootstatus = uci_t:get("scheduletask", s['.name'], "reboot")
            local timeformat = uci_t:get("scheduletask", s['.name'], "timeformat")
            
            if timeformat ~= "1" then
                timeformat = "0"
            end
            if not timestr then
                timestr = uci_t:get(s.config, s.section, s.timeoptionname)
            end
            if actionstr then
                local hourrange = nil
                if timeformat ~= "1" and string.find(timestr,"-") then
                    hourrange = true
                    hourtimesnum = hourtimesnum +1
                else
                    hourrange = false 
                end
                
                if("yes" == rebootstatus) then
                    local indexstr = uci_t:get("scheduletask", s['.name'], "rebootpri")
                    table.insert(reboottask,{action=actionstr, time=timestr,index=indexstr,hourrange=hourrange, timeformat=timeformat})
                    tasknum = tasknum + 1
                else
                    norebootindex = norebootindex + 1
                    table.insert(noreboottask,norebootindex,{action=actionstr, time=timestr,hourrange=hourrange, timeformat=timeformat})
                    tasknum = tasknum + 1
                end
                
            end
        end)
    function comp(a,b)
        if tonumber(a.index) >= tonumber(b.index) then
            return false
        else
            return true
        end
    end
    table.sort(reboottask,comp)

    if hourtimesnum >= 60 or hourtimesnum < 0 then
        return
    else
        interval = math.floor(60 / (hourtimesnum + 1))
        if interval >= 60 then
            interval = 30
        end
    end

    luci.sys.call("cp -f %s %s > /dev/null" % {defaultrule,crontabpath})

    for k1,v1 in ipairs(noreboottask) do
        if type(v1) == "table" then
            if v1.timeformat == "1" then
                luci.sys.call("echo \"%s %s\" >> %s" % {v1.time, v1.action, crontabpath});
            else
                local hour = string.sub(v1.time,1,2)
                local min = string.sub(v1.time,4,5)
                if hour and min then
                    if v1.hourrange  and (ruleindex <= hourtimesnum - 1) then
                        ruleindex = ruleindex + 1
                        local intervalmin = nil
                        if(interval * ruleindex < 10) then
                            intervalmin = "0" .. tostring(interval * ruleindex)
                        else
                            intervalmin = interval * ruleindex
                        end
                        luci.sys.call("echo \"%s %s * * * %s\" >> %s" % {tostring(intervalmin),tostring(hour),tostring(v1.action),crontabpath});
                    else
                        luci.sys.call("echo \"%s %s * * * %s\" >> %s" % {tostring(min),tostring(hour),tostring(v1.action),crontabpath});
                    end
                end
            end
        end
    end
    
    for k1,v1 in ipairs(reboottask) do
        if type(v1) == "table" then
            if v1.timeformat == "1" then
                luci.sys.call("echo \"%s %s __needreboot__\" >> %s" % {v1.time, v1.action, crontabpath});
            else
                local hour = string.sub(v1.time,1,2)
                local min = string.sub(v1.time,4,5)
                if hour and min then
                    if v1.hourrange  and (ruleindex <= hourtimesnum - 1) then
                        ruleindex = ruleindex + 1
                        local intervalmin = nil
                        if(interval * ruleindex < 10) then
                            intervalmin = "0" .. tostring(interval * ruleindex)
                        else
                            intervalmin = interval * ruleindex
                        end
                        luci.sys.call("echo \"%s %s * * * %s __needreboot__\" >> %s" % {tostring(intervalmin),tostring(hour),tostring(v1.action),crontabpath});
                    else
                        luci.sys.call("echo \"%s %s * * * %s __needreboot__\" >> %s" % {tostring(min),tostring(hour),tostring(v1.action),crontabpath});
                    end
                end
            end
        end
    end
    
    luci.sys.call("crontab %s > /dev/null" % crontabpath)
    luci.sys.call("rm -rf %s > /dev/null" % crontabpath)
end

function settaskatr(config, section, action, reboot, rebootpri, timeoptionname)
    luci.sys.call("uci set scheduletask.%s_%s=rule > /dev/null" % {config,section})
    luci.sys.call("uci set scheduletask.%s_%s.action=%s > /dev/null" % {config, section, action})
    luci.sys.call("uci set scheduletask.%s_%s.reboot=%s > /dev/null" % {config, section, reboot})
    luci.sys.call("uci set scheduletask.%s_%s.timeoptionname=%s > /dev/null" % {config, section, timeoptionname})
    if rebootpri then
        luci.sys.call("uci set scheduletask.%s_%s.rebootpri=%s > /dev/null" % {config, section, rebootpri})
    end
    luci.sys.call("uci commit scheduletask.%s_%s > /dev/null" % {config, section})
end

-- use for lua script
function cfgscdutskbylua(addordel, config, section)
    local uci_t = require "luci.model.uci".cursor()
    if config and section then
        if addordel=="edit" or addordel=="add" then
            luci.sys.call("uci set scheduletask.%s_%s=rule > /dev/null" % {config,section})
            luci.sys.call("uci set scheduletask.%s_%s.config=%s > /dev/null" % {config,section,config})
            luci.sys.call("uci set scheduletask.%s_%s.section=%s > /dev/null" % {config,section,section})
            luci.sys.call("uci commit scheduletask > /dev/null")
            generaterules()
        elseif addordel=="del" then 
            luci.sys.call("uci del scheduletask.%s_%s > /dev/null" % {config,section})
            luci.sys.call("uci commit scheduletask > /dev/null")
            generaterules()
        end
    end
end

-- use for crontab command
if arg[1] == "-add" and arg[2] and arg[3] then
    luci.sys.call("uci set scheduletask.%s_%s=rule > /dev/null" % {arg[2],arg[3]})
    luci.sys.call("uci set scheduletask.%s_%s.config=%s > /dev/null" % {arg[2],arg[3],arg[2]})
    luci.sys.call("uci set scheduletask.%s_%s.section=%s > /dev/null" % {arg[2],arg[3],arg[3]})
    luci.sys.call("uci commit scheduletask > /dev/null")
    generaterules()
end
if arg[1] == "-del" and arg[2] and arg[3] then
    luci.sys.call("uci del scheduletask.%s_%s > /dev/null" % {arg[2],arg[3]})
    luci.sys.call("uci commit scheduletask > /dev/null")
    generaterules()
end

-- add section action reboot rebootpri timestr
-- del section
if arg[1] == "add" then
    if #arg < 6 then
        return
    end
    
    local ucicur = require "luci.model.uci".cursor()
    ucicur:set("scheduletask", arg[2], "rule")
    ucicur:set("scheduletask", arg[2], "action", arg[3])
    ucicur:set("scheduletask", arg[2], "reboot", arg[4])
    ucicur:set("scheduletask", arg[2], "rebootpri", arg[5])
    ucicur:set("scheduletask", arg[2], "timeformat", "1")
    ucicur:set("scheduletask", arg[2], "timestr", arg[6])
    ucicur:commit("scheduletask")
    generaterules()
elseif arg[1] == "del" then
    if #arg < 2 then
        return
    end
    
    local ucicur = require "luci.model.uci".cursor()
    ucicur:delete("scheduletask", arg[2])
    ucicur:commit("scheduletask")
    generaterules()
end


if arg[1] == "generaterule" and not arg[2] and not arg[3] then
    local uci_t = require "luci.model.uci".cursor()
    if uci_t:get("system", "autoupgrade", "up_type") == "0" then
        settaskatr("system", "autoupgrade", "/lib/auto_upgrade.sh", "yes", "10","up_time")
        cfgscdutskbylua("add","system","autoupgrade")
    end
    generaterules()
end

