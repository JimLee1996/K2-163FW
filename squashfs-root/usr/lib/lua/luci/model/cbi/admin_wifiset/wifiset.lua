--[[
    wireless basic configurarion.
    Created by sen.xie, 2015-09-19
]]--

require("luci.tools.webadmin")
require("luci.fs")
require("luci.config")
require("luci.sys")

local uci = require("luci.model.uci")

local m

m = Map("wireless", translate("phicomm wifiset"), "")
m:addmodule("wifiset")
m.idname = "wifiset"
-- 2.4G wireless configure --
---- set wifi enable/disable ----
s = m:section(TypedSection, "wifi-device", "")
s.anonymous = true
s.addremove = false 
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.band == "2.4G" then --band is 2.4G means this section is 2.4G device.
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

--interface ra0
s = m:section(TypedSection, "wifi-iface", "")
s.anonymous = true
s.addremove = false 
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.ifname == "ra0" then 
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

-- 2.4G  ra0 switch
radio_2g = s:option(ListValue, "disabled", translate("2.4G WiFi").."：")
radio_2g:value("0", translate("开"))
radio_2g:value("1", translate("关"))
radio_2g.widget = "radio"
radio_2g.orientation = "horizontal"
radio_2g.idname = "2g_radio"
radio_2g.centerclass = "no_margin_left"
radio_2g.secondtitle = true
radio_2g.orangeclass = true
radio_2g.dimmed_sync = true
radio_2g.dimmed_id = {"2g_ssid","2g_broadcast","2g_key","2g_mode", "2g_channel", "2g_bandwidth", "2g_noforward"}

---- SSID name config ----

ssid_2g = s:option(Value, "ssid", translate("2.4G")..translate("Wireless")..translate("名称").."：")
ssid_2g.datatype = "and(sperangelength(1,32),checkWirelessspechar)"
ssid_2g.rmempty = false
ssid_2g.show_flag = true
ssid_2g.idname = "2g_ssid"
ssid_2g.centerclass = "no_margin_left200"
--ssid_2g.sync_value = true
--ssid_2g.sync_id = "5g_ssid"

broadcast_2g = s:option(Flag, "hidden", translate("user unvisible"))
broadcast_2g.default = "0"
broadcast_2g.clear_float = true
broadcast_2g.idname = "2g_broadcast"
broadcast_2g.centerclass = "no_margin_left200"
--broadcast_2g.sync_value = true
--broadcast_2g.sync_id = "5g_broadcast"

---- key ----
key_2g = s:option(Value, "key", translate("2.4G")..translate("Wireless")..translate("Key").."：")
key_2g.datatype = "and(wpakey,checkWirelessspechar)"
key_2g.rmempty = true
key_2g.password = true
key_2g.idname = "2g_key"
key_2g.centerclass = "no_margin_left200"
--key_2g.sync_value = true
--key_2g.sync_id = "5g_key"
--key_2g.sync_depend_value = true
--key_2g.sync_depend_id = {"2g_ssid","5g_ssid"}
key_2g.rmempty = true
key_2g.forceempty = true

function key_2g.write(self, section, value)
    if value and #value > 0  then
        enc = "psk-mixed+tkip+ccmp"
    else
        value = ""
        enc = "none"
    end
    self.map:set(section, "key", value)
    self.map:set(section, "encryption", enc)
end

-- wifi mode
s = m:section(TypedSection, "wifi-device", "")
s.anonymous = true
s.addremove = false 
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.band == "2.4G" then --band is 2.4G means this section is 2.4G device.
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

mode_2g = s:option(ListValue, "wifimode", translate("Wireless")..translate("Mode").."：")
mode_2g:value("9", translate("11b/g/n 混合"))
mode_2g:value("0", translate("11b/g 混合"))
mode_2g:value("6", translate("仅 11n"))
mode_2g.widget = "select"
mode_2g.idname= "2g_mode"
mode_2g.centerclass = "no_margin_left200"
mode_2g.bandsel_bg=true

---- channel select ----

channel_2g = s:option(ListValue, "channel", translate("Channel").."：")
channel_2g:value("0", translate("auto"))
channel_2g:value("1", translate("Channel 1"))
channel_2g:value("2", translate("Channel 2"))
channel_2g:value("3", translate("Channel 3"))
channel_2g:value("4", translate("Channel 4"))
channel_2g:value("5", translate("Channel 5"))
channel_2g:value("6", translate("Channel 6"))
channel_2g:value("7", translate("Channel 7"))
channel_2g:value("8", translate("Channel 8"))
channel_2g:value("9", translate("Channel 9"))
channel_2g:value("10", translate("Channel 10"))
channel_2g:value("11", translate("Channel 11"))
channel_2g:value("12", translate("Channel 12"))
channel_2g:value("13", translate("Channel 13"))
channel_2g.widget = "select"
channel_2g.idname = "2g_channel"
channel_2g.centerclass = "no_margin_left200"
channel_2g.dependented = true

bandwidth_2g = s:option(ListValue, "bw", translate("Band Width") .. "：")
bandwidth_2g:value("0", translate("20MHz"))
bandwidth_2g:value("2", translate("20/40MHz"))
bandwidth_2g:value("1", translate("40MHz"))
bandwidth_2g.default = "2"
bandwidth_2g.centerclass = "no_margin_left200"
bandwidth_2g.idname = "2g_bandwidth"
bandwidth_2g.widget = "radio"
bandwidth_2g.orientation = "horizontal"
bandwidth_2g.bandsel_bg=true

bandwidth_2g.write = function(self, section, value)
    self.map.uci:set("wireless", section, "bw", value)
    if value == "2" then
        self.map.uci:set("wireless", section, "ht_bsscoexist", "1")
    else
        self.map.uci:set("wireless", section, "ht_bsscoexist", "0")
    end
end

noforward_2g = s:option(Flag, "noforward", translate("Wireless")..translate("AP-Isolation"))
noforward_2g.idname = "2g_noforward"
noforward_2g.default = "0"
noforward_2g.show_help = true
noforward_2g.centerclass = "margin_left_40per"

help = s:option(HelpCommand, "help")
help.help_desc = translate("AP Isolation help")
-- 5G wireless configure --
---- set wifi enable/disable ----
s = m:section(TypedSection, "wifi-device", "")
s.anonymous = true
s.addremove = false 
s.cbi_line = true
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.band == "5G" then --band is 2.4G means this section is 2.4G device.
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

---- SSID name config ----
s = m:section(TypedSection, "wifi-iface", "")
s.anonymous = true
s.addremove = false 
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.ifname == "rai0" then 
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

radio_5g = s:option(ListValue, "disabled", translate("5G WiFi").."：")
radio_5g:value("0", translate("开"))
radio_5g:value("1", translate("关"))
radio_5g.widget = "radio"
radio_5g.orientation = "horizontal"
radio_5g.idname = "5g_radio"
radio_5g.centerclass = "no_margin_left"
radio_5g.orangeclass = true
radio_5g.secondtitle = true
radio_5g.dimmed_sync = true
radio_5g.dimmed_id = {"5g_ssid","5g_broadcast","5g_key","5g_mode", "5g_channel", "5g_bandwidth","5g_noforward"}

ssid_5g = s:option(Value, "ssid", translate("5G")..translate("Wireless")..translate("名称").."：")
ssid_5g.datatype = "and(sperangelength(1,32),checkWirelessspechar)"
ssid_5g.rmempty = false
ssid_5g.show_flag = true
ssid_5g.idname = "5g_ssid"
ssid_5g.centerclass = "no_margin_left200"

broadcast_5g = s:option(Flag, "hidden", translate("user unvisible"))
broadcast_5g.default = "0"
broadcast_5g.clear_float = true
broadcast_5g.idname = "5g_broadcast"
broadcast_5g.centerclass = "no_margin_left200"

---- key ----
key_5g = s:option(Value, "key", translate("5G")..translate("Wireless")..translate("Key").."：")
key_5g.datatype = "and(wpakey,checkWirelessspechar)"
key_5g.rmempty = true
key_5g.password = true
key_5g.idname = "5g_key"
key_5g.centerclass = "no_margin_left200"
key_5g.forceempty = true

function key_5g.write(self, section, value)
    if value and #value > 0  then
        enc = "psk-mixed+tkip+ccmp"
    else
        value = ""
        enc = "none"
    end
    self.map:set(section, "key", value)
    self.map:set(section, "encryption", enc)
end

-- wifi mode
s = m:section(TypedSection, "wifi-device", "")
s.anonymous = true
s.addremove = false 
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.band == "5G" then --band is 2.4G means this section is 2.4G device.
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

mode_5g = s:option(ListValue, "wifimode", translate("Wireless")..translate("Mode").."：")
mode_5g:value("14", translate("11a/n/ac 混合")) 
mode_5g:value("15", translate("11n/ac 混合")) 
mode_5g.widget = "select"
mode_5g.idname = "5g_mode"
mode_5g.centerclass = "no_margin_left200"

---- channel select ----

channel_5g = s:option(ListValue, "channel", translate("Channel").."：")
channel_5g:value("0", translate("auto"))
channel_5g:value("36", translate("Channel 36"))
channel_5g:value("40", translate("Channel 40"))
channel_5g:value("44", translate("Channel 44"))
channel_5g:value("48", translate("Channel 48"))
channel_5g:value("52", translate("Channel 52"))
channel_5g:value("56", translate("Channel 56"))
channel_5g:value("60", translate("Channel 60"))
channel_5g:value("64", translate("Channel 64"))
channel_5g:value("149", translate("Channel 149"))
channel_5g:value("153", translate("Channel 153"))
channel_5g:value("157", translate("Channel 157"))
channel_5g:value("161", translate("Channel 161"))
channel_5g:value("165", translate("Channel 165"))
channel_5g.widget = "select"
channel_5g.idname = "5g_channel"
channel_5g.centerclass = "no_margin_left200"
channel_5g.dependented = true

bandwidth_5g = s:option(ListValue, "bw", translate("Band Width") .. "：")
bandwidth_5g:value("0", translate("20MHz"))
bandwidth_5g:value("1", translate("20/40MHz"))
bandwidth_5g:value("2", translate("80MHz"))
bandwidth_5g.default = "1"
bandwidth_5g.idname = "5g_bandwidth"
bandwidth_5g.centerclass = "no_margin_left200"
bandwidth_5g.widget = "radio"
bandwidth_5g.orientation = "horizontal"
bandwidth_5g.write = function(self, section, value)
    self.map.uci:set("wireless", section, "bw", value)
    if value == "1" then
        self.map.uci:set("wireless", section, "ht_bsscoexist", "1")
    else
        self.map.uci:set("wireless", section, "ht_bsscoexist", "0")
    end
end

noforward_5g = s:option(Flag, "noforward", translate("Wireless")..translate("AP-Isolation"))
noforward_5g.idname = "5g_noforward"
noforward_5g.default = "0"
noforward_5g.centerclass = "margin_left_40per"
noforward_5g.show_help = true

help = s:option(HelpCommand, "help")
help.help_desc = translate("AP Isolation help")

s = m:section(TypedSection, "wifi-iface", "")
s.anonymous = true
s.addremove = false 
s.cbi_line = true
function s.cfgsections(self)
    local sections = {}
    self.map.uci:foreach(self.map.config, self.sectiontype,
        function (section)
            if self:checkscope(section[".name"]) and section.ifname == "ra1" then 
                table.insert(sections, section[".name"])
            end
        end)

    return sections
end

guest_wlan = s:option(ListValue, "disabled", translate("Guest Network").."：")
guest_wlan:value("0", translate("开"))
guest_wlan:value("1", translate("关"))
guest_wlan.widget = "radio"
guest_wlan.orientation = "horizontal"
guest_wlan.centerclass = "no_margin_left"
guest_wlan.idname = "guest_radio"
guest_wlan.secondtitle = true
guest_wlan.orangeclass = true
guest_wlan.dimmed_sync = true
guest_wlan.dimmed_id = {"guest_ssid","guest_broadcast","guest_key"}


guest_ssid = s:option(Value, "ssid", translate("Guest Network")..translate("名称").."：")
guest_ssid.datatype = "and(sperangelength(1,32),checkWirelessspechar)"
guest_ssid.rmempty = false
guest_ssid.centerclass = "no_margin_left200"
guest_ssid.show_flag = true
guest_ssid.idname = "guest_ssid"

broadcast_guest = s:option(Flag, "hidden", translate("user unvisible"))
broadcast_guest.default = "0"
broadcast_guest.clear_float = true
broadcast_guest.idname = "guest_broadcast"
broadcast_guest.centerclass = "no_margin_left200"

guest_key = s:option(Value, "key", translate("Wireless")..translate("Key").."：")
guest_key.datatype = "and(wpakey,checkWirelessspechar)"
guest_key.rmempty = true
guest_key.password = true
guest_key.centerclass = "no_margin_left200"
guest_key.forceempty = true
guest_key.idname = "guest_key"

function guest_key.write(self, section, value)
    if value and #value > 0  then
        enc = "psk-mixed+tkip+ccmp"
    else
        value = ""
        enc = "none"
    end
    self.map:set(section, "key", value)
    self.map:set(section, "encryption", enc)
end

return m
