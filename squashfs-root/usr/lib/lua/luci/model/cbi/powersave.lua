
local m, s, o

m = Map("powersave", translate("Signal Conditioning"))
m:addmodule("more_signal")
    
s = m:section(NamedSection, "powersave", "power")
s.addremove = false
s.anonymous = true

o = s:option(ListValue, "enable", translate("Signal Conditioning")..translate("Mode").."：")
o:value("0", translate("一键穿墙模式"))
o:value("1", translate("绿色节能模式"))
o.widget = "radio"
o.advance_second_title = true
o.orientation = "horizontal"


return m
