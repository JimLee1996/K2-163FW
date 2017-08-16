module ("luci.controller.safeset",package.seeall)

function index()
    entry({"admin", "more_safeset"}, template("safeset/safeset"), _("Safeset"), 70)
    entry({"admin", "more_safeset", "form_proc"}, call("form_safeset"), _("Safeset")).leaf = true
end

function form_safeset()
    local uci = require("luci.model.uci").cursor()
    local http = require("luci.http")
    local sys = require("luci.sys")
    local spi_enable = luci.http.formvalue("spi_en")
    local ddos_enable = luci.http.formvalue("ddos_en")
    local icmp_flood = luci.http.formvalue("icmp_flood_en")
    local udp_flood = luci.http.formvalue("udp_flood_en")
    local syn_flood = luci.http.formvalue("tcp_flood_en")
    local ping_disable = luci.http.formvalue("wan_ping_en")

    if not spi_enable or not ddos_enable then
        luci.http.redirect(luci.dispatcher.build_url("admin", "more_safeset"))
    end

    if not icmp_flood or not udp_flood or not syn_flood or not ping_disable then
        luci.http.redirect(luci.dispatcher.build_url("admin", "more_safeset"))
    end

    uci:set("safeset", "config", "spi_enable", spi_enable)
    uci:set("safeset", "config", "ddos_enable", ddos_enable)
    uci:set("safeset", "config", "ping_disable", ping_disable)

    if ddos_enable == "1" then
        uci:set("safeset", "config", "icmp_flood", icmp_flood)
        uci:set("safeset", "config", "udp_flood", udp_flood)
        uci:set("safeset", "config", "syn_flood", syn_flood)

        if icmp_flood == "1" then
            local icmpflood_rate = luci.http.formvalue("usIcmpFlood")
            if icmpflood_rate then
                uci:set("safeset", "config", "icmpflood_rate", icmpflood_rate)
            end
        end
        if udp_flood == "1" then
            local udpflood_rate = luci.http.formvalue("usUdpFlood")
            if udpflood_rate then
                uci:set("safeset", "config", "udpflood_rate", udpflood_rate)
            end
        end
        if syn_flood =="1" then
            local synflood_rate = luci.http.formvalue("usTcpSynFlood")
            if synflood_rate then
                uci:set("safeset", "config", "synflood_rate", synflood_rate)
            end
        end
    end

	luci.sys.addhistory("more_safeset")
    uci:save("safeset")
    uci:commit("safeset")
    luci.sys.call("/etc/init.d/safeset enable > /dev/null; /etc/init.d/safeset start > /dev/null")
    luci.http.redirect(luci.dispatcher.build_url("admin", "more_safeset"))
end
