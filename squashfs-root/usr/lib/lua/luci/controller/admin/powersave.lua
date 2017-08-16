
module("luci.controller.admin.powersave", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/powersave") then
	return
    end 

    entry({"admin", "more_signal"}, cbi("powersave"), _("powersave"), 21)
end
