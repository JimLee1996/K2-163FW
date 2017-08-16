#!/bin/sh
append DRIVERS "mt7620"

. /lib/wifi/ralink_common.sh

prepare_mt7620() {
	prepare_ralink_wifi mt7620
}

scan_mt7620() {
	scan_ralink_wifi mt7620 mt7620
}


disable_mt7620() {
	disable_ralink_wifi mt7620
}

enable_mt7620() {
	enable_ralink_wifi mt7620 mt7620
}

detect_mt7620() {
#	detect_ralink_wifi mt7620 mt7620
#	ssid=PHICOMM_`eth_mac r wan | cut -c 12- | sed 's/://g'`
	ssid=@PHICOMM_`eth_mac r wan | cut -c 16-`
	ssid2=@PHICOMM_Guest
	cd /sys/module/
	[ -d $module ] || return
	[ -e /etc/config/wireless ] && return
         cat <<EOF
config wifi-device      mt7620
        option type     mt7620
        option vendor   ralink
        option band     2.4G
	option channel  0
	option autoch   2
	option autoch_skip   "12;13"
        option region   1
        option aregion  4
        option country  CN
        option wifimode 9
        option bw       2
        option ht_bsscoexist 1
        option noforwardbtnbssid 1
        option disabled 0

config wifi-iface
        option device   mt7620
        option ifname   ra0
        option network  lan
        option mode     ap
        option ssid     $ssid
        option encryption none
        option hidden    0
        option disabled  0

config wifi-iface
        option device   mt7620
        option ifname   ra1
        option network  lan
        option mode     ap
        option ssid     $ssid2
        option encryption none
        option disabled 1

config wifi-passwordsame
        option samepassword 0

EOF


}


