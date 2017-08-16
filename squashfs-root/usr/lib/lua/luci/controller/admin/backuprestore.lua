--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - system backup support
    AUTHOR        : ge.zhang <ge.zhang@phicomm.com.cn>
    CREATED DATE  : 2016-04-29
    MODIFIED DATE : 
]]--

module("luci.controller.admin.backuprestore", package.seeall)

function index()
    local page
    page = entry({"admin", "more_sysset", "backuprecovery"}, call("backup_restore_reset"), _("backuprecovery"), 99)
end

function checkfwversion()
    local uci_t = require "luci.model.uci".cursor()
    local curfwversion=uci_t:get("system", "system", "fw_ver") or "0.0.0.0"
    local cfgfwversion=luci.util.exec("head /tmp/restore_decode -n 10 | grep -m 1 \"fw_ver\" | awk -F= '{print$2}'")
    local vercmpstr="verrevcmp" .. " " .. curfwversion .. " " .. cfgfwversion
    local isnewver = luci.util.exec(vercmpstr)
    if tonumber(isnewver) > 0 then
        return false
    else
        return true
    end
end

function backup_restore_reset()
    local sys = require "luci.sys"
    local fs = require "luci.fs"

    luci.sys.addhistory("backuprecovery")
    local reset_avail = os.execute([[grep '"rootfs_data"' /proc/mtd >/dev/null 2>&1]]) == 0
    local restore_cmd = "tar -xzC/ >/dev/null 2>&1"
    local backup_cmd = "sysupgrade --create-backup /tmp/backup_pack 2>/dev/null"

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

    if (luci.http.formvalue("backup")) then
        local reader = ltn12_popen(backup_cmd)
        luci.http.header('Content-Disposition', 'attachment; filename="config.dat"')
        luci.http.prepare_content("application/x-targz")
        luci.ltn12.pump.all(reader, luci.http.write)
    elseif luci.http.formvalue("restore") then
        luci.util.exec("encryconfig decrypt /tmp/restore_encode /tmp/restore_decode")
        local fd = io.open("/tmp/restore_decode", r)
        local restore_error_message
        if fd ~= nil then
            local line = fd:read()
            fd:close()
            if line ~= nil then
                if not checkfwversion() then
                    restore_error_fwversion = {"restore_error"}
                    nixio.fs.unlink("/tmp/restore_encode")
                    nixio.fs.unlink("/tmp/restore_decode")
                    luci.template.render("backuprestore", {
                        restore_error_fwversion = restore_error_fwversion
                    })
                else
                    luci.util.exec("sed 1,10d /tmp/restore_decode >/tmp/restore_rm_header")
                    luci.util.exec("tar -xzC/ -f /tmp/restore_rm_header")
                    nixio.fs.unlink("/tmp/restore_encode")
                    nixio.fs.unlink("/tmp/restore_decode")
                    nixio.fs.unlink("/tmp/restore_rm_header")
                    local cur_lan_mac = luci.util.exec("uci get network.lan.macaddr")
                    local cur_wan_mac = luci.util.exec("uci get network.wan.macaddr")
                    local flash_lan_mac = luci.util.exec("eth_mac r lan")
                    local flash_wan_mac = luci.util.exec("eth_mac r wan")
                    if cur_lan_mac ~= flash_lan_mac then
                        luci.util.exec("uci set network.lan.macaddr=%s" % flash_lan_mac)
                    end
                    if cur_wan_mac ~= flash_wan_mac then
                        luci.util.exec("uci set network.wan.macaddr=%s" % flash_wan_mac)
                    end
                    luci.util.exec("uci commit")
                    local upload = luci.http.formvalue("restore")
                    if upload and #upload > 0 then
                        luci.template.render("backuprestore", {
                            restore_avail = 1
                        })
                        fork_exec("sleep 3; reboot")
                    end
                end
            else
                restore_error_message = {"restore_error"}
                nixio.fs.unlink("/tmp/restore_encode")
                nixio.fs.unlink("/tmp/restore_decode")
                luci.template.render("backuprestore", {
                    restore_error_message = restore_error_message
                })
            end
        else 
            nixio.fs.unlink("/tmp/restore_encode")
            nixio.fs.unlink("/tmp/restore_decode")
            restore_error_message = {"restore_error"}
            luci.template.render("backuprestore", {
                restore_error_message = restore_error_message
            })
        end
    elseif reset_avail and luci.http.formvalue("reset") then
        luci.template.render("backuprestore", {
            reset_process = 1
        })
        fork_exec("sleep 3; killall dropbear lighttpd miniupnpd; sleep 3; mtd -r erase rootfs_data")
    else 
        luci.template.render("backuprestore")
    end 


end

function fork_exec(command)
    local pid = nixio.fork()
    if pid > 0 then
        return 
    elseif pid == 0 then
        -- change to root dir
        nixio.chdir("/")

        --patch stdin, out, err to /dev/null
        local null = nixio.open("/dev/null", "w+")
        if null then
            nixio.dup(null, nixio.stderr)
            nixio.dup(null, nixio.stdout)
            nixio.dup(null, nixio.stdin)
            if null:fileno() > 2 then
                null:close()
            end
        end

        -- replace with target command
        nixio.exec("/bin/sh", "-c", command)
    end
end

function ltn12_popen(command)

    local fdi, fdo = nixio.pipe()
    local pid = nixio.fork()

    if pid >0 then
        fdo:close()
        local close
        return function()
            local buffer = fdi:read(2048)
            local wpid, stat = nixio.waitpid(pid, "nohang")
            if not close and wpid and stat == "extend" then
                close = true
            end

            if buffer and #buffer > 0 then
                return buffer
            elseif close then
                fdi:close()
                return nil
            end
        end
    elseif pid == 0 then
        nixio.dup(fdo, nixio.stdout)
        fdi:close()
        fdo:close()
        nixio.exec("/bin/sh", "-c", command)
    end
end

