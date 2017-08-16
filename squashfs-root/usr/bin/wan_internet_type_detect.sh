#!/bin/sh

. /usr/share/libubox/jshn.sh
. /lib/functions.sh

config_load luci
config_get_bool firststart main firststart 0
local wan_link
local wan_link_json
local client_num
local flag=true

if [ $firststart -eq 1 ]; then
	while $flag
	do
		client_num=$((`cat /proc/net/statsPerIp | wc -l` - 1))
		wan_link_json=`ubus call rth.inet get_wan_link`
		json_load "$wan_link_json"
		json_get_var wan_link wan_link
		if [ "$wan_link" = "up" -a $client_num -gt 0 ];then
			/sbin/autonetwork
			flag=false
		else
			sleep 2
		fi
	done
fi
