--[[
    Copyright (C) 2016. Shanghai Feixun Communication Co.,Ltd.

    DISCREPTION   : LuCI - Lua Configuration Interface - lanSet support
    AUTHOR        : zhiwen.xu <zhiwen.xu@phicomm.com.cn>
    CREATED DATE  : 2016-04-26
    MODIFIED DATE : 
]]--

module("luci.controller.admin.wps", package.seeall)

function index()
  
    local page
    entry({"admin", "more_wps"}, template("wl_wps"), _("wpsset"),64)
--  entry({"admin", "more_wps","wpspincode_2g"}, call("getwpspincode_2g"), _("wpssetpincode"),nil)
--  entry({"admin", "more_wps","wpspincode_5g"}, call("getwpspincode_5g"), _("wpssetpincode"),nil)
    entry({"admin", "more_wps","wps_enable"}, call("wpsenable_setting"), _("wps_enable"),nil)
--  entry({"admin", "more_wps","wps_pinconnect"}, call("wps_pinhandle"), _("wps_pinconnect"),nil)
    entry({"admin", "more_wps","wps_pbcconnect"}, call("wps_pbchandle"), _("wps_pbcconnect"),nil)
    entry({"admin", "more_wps","wps_uciclose"}, call("uciclosewps"), _("wps_uciclose"),nil)
    entry({"admin", "more_wps","wps_enable_hidenssid"}, call("wps_hidessid_handle"), _("wps_enable_hidenssid"),nil)
end
function uciclosewps()
    local uci_t = (require "luci.model.uci").cursor()	
    uci_t:set("wps_config","wps_para", "wps_enable", "0")
    uci_t:save("wps_config")
    uci_t:commit("wps_config")
end
function wps_hidessid_handle()
    local hidemain_2g_ssid = luci.http.formvalue("hidemain_2g_ssid")
    local hidemain_5g_ssid = luci.http.formvalue("hidemain_5g_ssid")
    local wifi_2g_disable = luci.http.formvalue("wifi_2g_disable")
    local wifi_5g_disable = luci.http.formvalue("wifi_5g_disable")
    local uci_t = (require "luci.model.uci").cursor()
    local phicomm_lua = require "phic"

    if hidemain_2g_ssid == "1" and wifi_2g_disable == "0" then
        phicomm_lua.set_wifi_iface_config("ra0", "hidden", "0")
        luci.sys.call("iwpriv ra0 set HideSSID=0")
        uci_t:set("wps_config","wps_para", "wps_enable", "1")
        uci_t:save("wps_config")
        uci_t:commit("wps_config")
--      luci.sys.call("iwpriv ra0 set WscConfMode=0")
--      luci.sys.call("iwpriv ra0 set WscStop=1")
--      io.popen("wps_manage ra0 register on")
    end
    if hidemain_5g_ssid == "1" and wifi_5g_disable == "0" then
        phicomm_lua.set_wifi_iface_config("rai0", "hidden", "0")
        luci.sys.call("iwpriv rai0 set HideSSID=0")
        uci_t:set("wps_config","wps_para", "wps_enable","1")
        uci_t:save("wps_config")
        uci_t:commit("wps_config")
--      luci.sys.call("iwpriv rai0 set WscConfMode=0")
--      luci.sys.call("iwpriv rai0 set WscStop=1")
--      io.popen("wps_manage rai0 register on")
    end

    luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))
end
--[[
function getwpspincode_2g() 
	             
	luci.sys.call("iwpriv ra0 set WscGenPinCode")
        local iw = luci.sys.wifi.getiwinfo("ra0")
        --local pincode = iw.wscPINcode
        local pincode = string.format("%08d",iw.wscPINcode)
        local uci_t = (require "luci.model.uci").cursor()
        uci_t:set("wps_config","wps_para", "pincode_2g", pincode)
        uci_t:save("wps_config")
        uci_t:commit("wps_config")
        io.popen("pid1=`pidof wpspinproc ra0`;kill -9 $pid1 >/dev/null 2>&1")
        luci.sys.call("iwpriv ra0 set WscConfMode=0")
        io.popen("wps_manage ra0 register on")    
           
        luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))
end

function getwpspincode_5g() 
	              
	luci.sys.call("iwpriv rai0 set WscGenPinCode")
        local iw1 = luci.sys.wifi.getiwinfo("rai0")
        --local pincode = iw1.wscPINcode
        local pincode = string.format("%08d",iw1.wscPINcode)
        local uci_t = (require "luci.model.uci").cursor()
        uci_t:set("wps_config","wps_para", "pincode_5g", pincode)
        uci_t:save("wps_config")
        uci_t:commit("wps_config")
        io.popen("pid1=`pidof wpspinproc rai0`;kill -9 $pid1 >/dev/null 2>&1")
        luci.sys.call("iwpriv rai0 set WscConfMode=0")
        io.popen("wps_manage rai0 register on")   
        luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))	
end
]]--
function wpsenable_setting() 
	
        local wps_enable = luci.http.formvalue("wps_enable")
        local uci_t = (require "luci.model.uci").cursor()
        luci.sys.addhistory("more_wps")
        if wps_enable == "1" then
            uci_t:set("wps_config","wps_para", "wps_enable", wps_enable)
            uci_t:save("wps_config")
	    uci_t:commit("wps_config")
            luci.sys.call("iwpriv ra0 set WscConfMode=0")
            luci.sys.call("iwpriv rai0 set WscConfMode=0")
            luci.sys.call("iwpriv ra0 set WscStop=1")
            luci.sys.call("iwpriv rai0 set WscStop=1")
--          io.popen("wps_manage ra0 register on")    
--          io.popen("wps_manage rai0 register on")       
        elseif wps_enable == "0" then
            uci_t:set("wps_config","wps_para", "wps_enable", wps_enable)
            uci_t:save("wps_config")
	    uci_t:commit("wps_config")
            io.popen("pid1=`pidof wpspbc`;kill -9 $pid1 >/dev/null 2>&1")
--          io.popen("pid2=`pidof wpspin`;kill -9 $pid2 >/dev/null 2>&1")
--          io.popen("pid3=`pidof wpspinproc`;kill -9 $pid3 >/dev/null 2>&1")
            luci.sys.call("iwpriv ra0 set WscConfMode=0")
            luci.sys.call("iwpriv rai0 set WscConfMode=0")
            luci.sys.call("iwpriv ra0 set WscStop=1")
            luci.sys.call("iwpriv rai0 set WscStop=1")
        end
	luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))
end
--[[
function wps_pinhandle() 
         local pin_code = luci.http.formvalue("pincode")
         local pin_freq = luci.http.formvalue("pin_freq")
         local uci_t = (require "luci.model.uci").cursor()

         if pin_freq == "0" then
            uci_t:set("wps_config","wps_para", "pincode", tostring(pincode))
            uci_t:save("wps_config")
	    uci_t:commit("wps_config")
            io.popen("pid1=`pidof wpspbc`;kill -9 $pid1 >/dev/null 2>&1")
            io.popen("pid2=`pidof wpspin`;kill -9 $pid2 >/dev/null 2>&1") 
            io.popen("pid3=`pidof wpspinproc`;kill -9 $pid3 >/dev/null 2>&1") 
            luci.sys.call("iwpriv ra0 set WscStop=1")   
            luci.sys.call("iwpriv ra0 set WscConfMode=0")
            io.popen("wps_manage ra0 %s" % pin_code)
        elseif pin_freq == "1" then
            uci_t:set("wps_config","wps_para", "pincode", tostring(pincode))
            uci_t:save("wps_config")
	    uci_t:commit("wps_config")
            io.popen("pid1=`pidof wpspbc`;kill -9 $pid1 >/dev/null 2>&1")
            io.popen("pid2=`pidof wpspin`;kill -9 $pid2 >/dev/null 2>&1")
            io.popen("pid3=`pidof wpspinproc`;kill -9 $pid3 >/dev/null 2>&1")
            luci.sys.call("iwpriv rai0 set WscStop=1") 
            luci.sys.call("iwpriv rai0 set WscConfMode=0")
            io.popen("wps_manage rai0 %s" % pin_code)
        end
	luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))	
end
]]--
function wps_pbchandle() 
	
         local pbc_freq = luci.http.formvalue("pbc_freq")
         local uci_t = (require "luci.model.uci").cursor()
         if pbc_freq == "0" then
            io.popen("pid1=`pidof wpspbc`;kill -9 $pid1 >/dev/null 2>&1")
--          io.popen("pid2=`pidof wpspin`;kill -9 $pid2 >/dev/null 2>&1") 
--          io.popen("pid2=`pidof wpspinproc`;kill -9 $pid2 >/dev/null 2>&1")
	    luci.sys.call("iwpriv ra0 set WscStop=1")  
            luci.sys.call("iwpriv ra0 set WscConfMode=0")
            io.popen("wps_manage ra0")
           
        elseif pbc_freq == "1" then
            io.popen("pid1=`pidof wpspbc`;kill -9 $pid1 >/dev/null 2>&1")
--          io.popen("pid2=`pidof wpspin`;kill -9 $pid2 >/dev/null 2>&1")
--          io.popen("pid2=`pidof wpspinproc`;kill -9 $pid2 >/dev/null 2>&1")
            luci.sys.call("iwpriv rai0 set WscStop=1") 
            luci.sys.call("iwpriv rai0 set WscConfMode=0")
            io.popen("wps_manage rai0")
        end
	luci.http.redirect(luci.dispatcher.build_url("admin","more_wps"))
end

