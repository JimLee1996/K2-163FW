--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - parent control support
    AUTHOR        : xiangjun.fu <xiangjun.fu@phicomm.com.cn>
    CREATED DATE  : 2016-05-16
    MODIFIED DATE : 
]]--
local uci_t    = require "luci.model.uci"
local datatype = require("luci.cbi.datatypes")
local util = require("luci.util")
local sys = require "luci.sys"
require "luci.controller.admin.system"

module("luci.controller.admin.parentctl", package.seeall)

function index()
    entry({"admin", "more_parentctl"}, call("parentcntl"), _("parentctl"), 65)
    entry({"admin", "more_parentctl", "edit"}, call("parentcntl_edit"), _("parentctl"), 1)
    entry({"admin", "more_parentctl", "del"}, call("parentcntl_del"), _("parentctl"), 2)
    entry({"admin", "more_parentctl", "save"}, call("parentcntl_save"), _("parentctl"), 3)
end

function parentcntl()
    if luci.http.formvalue("opstatus") == "1" then
        luci.template.render("parentctl/parentctl",{showstatus = 1})
    else
        luci.template.render("parentctl/parentctl")
    end
end

local weekday_table = { "week1", "week2", "week3", "week4", "week5", "week6", "week7"}

function hostname_cfg(hostname,cur_mac,original_mac,action)
    local cur = uci_t.cursor()
    local count_curmac = 0
    local count_ori_mac = 0
   
    cur:foreach("parentctl", "rule",
        function(s)
            if 0 == count_curmac and s.src_mac == cur_mac then
                count_curmac = count_curmac + 1
                if 1 == count_ori_mac then
                    return
                end
            end
            
            if 0 == count_ori_mac and s.src_mac == original_mac then
                count_ori_mac = count_ori_mac + 1
                if 1 == count_curmac then
                    return
                end
            end
        end)
    
    if 0 == count_curmac and action == "del" then
        cur:foreach("common_host", "host",
            function(s)
                if s[".name"] == string.gsub(cur_mac,":","_")then
                    cur:delete("common_host", s[".name"])
                    return
                end
            end)    
    elseif action == "edit"then 
        local cfg_cur = 0
        local cfg_ori = 0
        cur:foreach("common_host", "host",
            function(s)
                if 0 == cfg_cur and s[".name"] == string.gsub(cur_mac,":","_") then
                    cur:set("common_host", s[".name"], "hostname", hostname)
                    cfg_cur = 1
                end
                if 0 == cfg_ori and 0 == count_ori_mac and s[".name"] == string.gsub(original_mac,":","_") 
                    and original_mac ~= cur_mac then
                    cur:delete("common_host", s[".name"])
                    cfg_ori = 1
                end
            end)
        if 0 == cfg_cur then
            cur:section("common_host","host",string.gsub(cur_mac,":","_"),{hostname=hostname})
        end
    end
    cur:commit("common_host")
end

function freshruleindex()
    local count = 0
    local cur = uci_t.cursor()
    cur:foreach("parentctl", "rule",
        function(s)
            count = count + 1
            cur:set("parentctl", s[".name"], "ruleindex", count)
        end)
    cur:commit("parentctl")
end

function paramcheck(rule)
    local cur = uci_t.cursor()
    local fail = 0
    cur:foreach("parentctl", "rule",
        function(s)
            if s.src_mac == rule.src_mac and rule.ruleindex ~= s.ruleindex then
                if (1 == tonumber(rule.week1) and string.match(s.weekdays,"1"))
                    or (1 == tonumber(rule.week2) and string.match(s.weekdays,"2"))
                    or (1 == tonumber(rule.week3) and string.match(s.weekdays,"3"))
                    or (1 == tonumber(rule.week4) and string.match(s.weekdays,"4"))
                    or (1 == tonumber(rule.week5) and string.match(s.weekdays,"5"))
                    or (1 == tonumber(rule.week6) and string.match(s.weekdays,"6"))
                    or (1 == tonumber(rule.week7) and string.match(s.weekdays,"7"))
                    then

                    local charindex = string.find(s.start_time,":")
                    local index_cfg_s = charindex
                    charindex = string.find(rule.start_time,":")
                    local index_cur_s = charindex
                    charindex = string.find(s.stop_time,":")
                    local index_cfg_e = charindex
                    charindex = string.find(rule.stop_time,":")
                    local index_cur_e = charindex
                    
                    local s_cfg_hour = tonumber(string.sub(s.start_time, 1,index_cfg_s-1))
                    local s_cfg_min = tonumber(string.sub(s.start_time, index_cfg_s+1))
                    local s_cur_hour = tonumber(string.sub(rule.start_time, 1,index_cur_s-1))
                    local s_cur_min = tonumber(string.sub(rule.start_time, index_cur_s+1))

                    local e_cfg_hour = tonumber(string.sub(s.stop_time, 1,index_cfg_e-1))
                    local e_cfg_min = tonumber(string.sub(s.stop_time, index_cfg_e+1))
                    local e_cur_hour = tonumber(string.sub(rule.stop_time, 1,index_cur_e-1))
                    local e_cur_min = tonumber(string.sub(rule.stop_time, index_cur_e+1))

                    if not (
                            s_cur_hour > e_cfg_hour
                            or (s_cur_hour == e_cfg_hour and s_cur_min >= e_cfg_min)
                            or e_cur_hour < s_cfg_hour
                            or (e_cur_hour == s_cfg_hour and e_cur_min <= s_cfg_min)
                        ) then
                        fail = 1
                        return
                    end
                end
            end
        end)
    if 1 == fail then
        return false
    else
        return true
    end
end

function parentcntl_edit()
    local info = {
        status = "fail",
        message = luci.i18n.translate("parentctl_op_fail")
    }
    local cur = uci_t.cursor()
    local matchstatus = 0;
    local cur_count = 0
    local section_cfg = nil
    local paramchkstatus = nil
    local parentctl_enabled = cur:get("parentctl", "config", "enabled")
    local rule = {
        hostname = luci.http.formvalue("hostname"),
        src_mac = luci.http.formvalue("src_mac"):upper(),
        week1 = luci.http.formvalue("week1"),
        week2 = luci.http.formvalue("week2"),
        week3 = luci.http.formvalue("week3"),
        week4 = luci.http.formvalue("week4"),
        week5 = luci.http.formvalue("week5"),
        week6 = luci.http.formvalue("week6"),
        week7 = luci.http.formvalue("week7"),
        start_time = luci.http.formvalue("start_time"),
        stop_time = luci.http.formvalue("stop_time"),
        original_mac = luci.http.formvalue("original_mac"):upper(),
        ruleindex = luci.http.formvalue("ruleindex")
    }
    local weekdays = nil;
    local new
    
    local parentctl_used = cur:get("collect", "main", "parent_used")
    if parentctl_enabled ~= 1 then
        luci.sys.call("uci set collect.main.parent_used=1 > /dev/null; uci commit collect > /dev/null")
    end

    for i = 1, 7 do
        if rule[weekday_table[i]] == "1" then
            if not weekdays or weekdays == "" then
                    weekdays = tostring(i)
            else
                    weekdays = weekdays .. "," .. tostring(i)
            end
        end
    end

    cur:foreach("parentctl", "rule",
        function(s)
            cur_count = cur_count + 1
        end)

    if cur_count >= 10 and rule.ruleindex == "newrule" then
        info.message = luci.i18n.translate("parentctl_max_support_10")
    elseif paramcheck(rule) then
        if rule.ruleindex == "newrule" then
            local new = cur:add("parentctl", "rule")
            if new then
                cur:set("parentctl", new, "src_mac", rule.src_mac)
                cur:set("parentctl", new, "weekdays", weekdays)
                cur:set("parentctl", new, "start_time", rule.start_time)
                cur:set("parentctl", new, "stop_time", rule.stop_time)
                matchstatus = 1
                if parentctl_enabled ~= 1 then
                    luci.sys.call("uci set parentctl.config.enabled=1 > /dev/null")
                end
                cur:commit("parentctl")
                hostname_cfg(rule.hostname,rule.src_mac,rule.original_mac,"edit")
                freshruleindex()
                luci.controller.admin.system.fork_exec("/etc/init.d/parentctl enable > /dev/null; /etc/init.d/parentctl restart > /dev/null")
            end
        else
            cur:foreach("parentctl", "rule",
                function(s)
                    if s.src_mac == rule.original_mac and rule.ruleindex == s.ruleindex then
                        section_cfg = s
                        return
                    end
                end)
            if section_cfg then
                cur:set("parentctl", section_cfg[".name"], "src_mac", rule.src_mac)
                cur:set("parentctl", section_cfg[".name"], "weekdays", weekdays)
                cur:set("parentctl", section_cfg[".name"], "start_time", rule.start_time)
                cur:set("parentctl", section_cfg[".name"], "stop_time", rule.stop_time)
                matchstatus = 1
                if parentctl_enabled ~= 1 then
                    luci.sys.call("uci set parentctl.config.enabled=1 > /dev/null")
                end
                cur:commit("parentctl")
                hostname_cfg(rule.hostname,rule.src_mac,rule.original_mac,"edit")
                luci.controller.admin.system.fork_exec("/etc/init.d/parentctl enable > /dev/null; /etc/init.d/parentctl restart > /dev/null")
            end
        end
    else
        info.message = luci.i18n.translate("parentctl_rule_cfg_conflict_head") .. rule.src_mac .. 
        luci.i18n.translate("parentctl_rule_cfg_conflict_tail")
    end
    
    if matchstatus == 1 then
        info.status = "success"
    end

    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
    
end

function parentcntl_del()
    local section
    local info = {
        status = "fail",
        message = luci.i18n.translate("parentctl_op_fail")
    }
    local matchstatus = 0;
    local cur = uci_t.cursor()
    src_mac = luci.http.formvalue("src_mac")
    ruleindex = luci.http.formvalue("ruleindex")
    local parentctl_enabled = cur:get("parentctl", "config", "enabled")
    local parentctl_used = cur:get("collect", "main", "parent_used")

    if parentctl_enabled ~= 1 then
        luci.sys.call("uci set collect.main.parent_used=1 > /dev/null; uci commit collect > /dev/null")
    end

    cur:foreach("parentctl", "rule",
        function(s)
            if src_mac == s.src_mac and ruleindex == s.ruleindex then
                section = s
                matchstatus = 1;
                return
            end
        end)
    if matchstatus == 1 then
        if parentctl_enabled ~= 1 then
            luci.sys.call("uci set parentctl.config.enabled=1 > /dev/null")
        end
        cur:delete("parentctl", section[".name"])
        cur:commit("parentctl")
        freshruleindex()
        hostname_cfg(nil,src_mac,nil,"del")
        luci.controller.admin.system.fork_exec("/etc/init.d/parentctl enable > /dev/null; /etc/init.d/parentctl restart > /dev/null")
        info.status = "success"
    end
    luci.http.prepare_content("application/json")
    luci.http.write_json(info)
end

function parentcntl_save()
    local cur = uci_t.cursor()
    local parentctl_used = cur:get("collect", "main", "parent_used")
    if parentctl_enabled ~= 1 then
        luci.sys.call("uci set collect.main.parent_used=1 > /dev/null; uci commit collect > /dev/null")
    end

    if luci.http.formvalue("switch") == "1" then
        luci.sys.call("uci set parentctl.config.enabled=1 > /dev/null")
        luci.sys.call("uci commit parentctl.config > /dev/null")
        luci.sys.call("/etc/init.d/parentctl enable > /dev/null; /etc/init.d/parentctl start > /dev/null")
    else
        luci.sys.call("uci set parentctl.config.enabled=0 > /dev/null")
        luci.sys.call("uci commit parentctl.config > /dev/null")
        luci.sys.call("/etc/init.d/parentctl disable > /dev/null; /etc/init.d/parentctl stop > /dev/null")
    end
    
    luci.sys.addhistory("more_parentctl")
    luci.http.redirect(luci.dispatcher.build_url("admin", "more_parentctl"))
end
