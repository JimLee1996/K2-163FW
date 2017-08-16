#!/bin/sh
append DRIVERS "mt7612e"

. /lib/wifi/ralink_common.sh

prepare_mt7612e() {
	prepare_ralink_wifi mt7612e
}

scan_mt7612e() {
	scan_ralink_wifi mt7612e mt76x2e
}

disable_mt7612e() {
	disable_ralink_wifi mt7612e
}

enable_mt7612e() {
	enable_ralink_wifi mt7612e mt76x2e
}

detect_mt7612e() {
#	detect_ralink_wifi mt7612e mt76x2e
#	ssid=PHICOMM_`eth_mac r wan | cut -c 12- | sed 's/://g'`
	ssid=@PHICOMM_`eth_mac r wan | cut -c 16-`_5G
	cd /sys/module/
	[ -d $module ] || return
	[ -e /etc/config/wireless ] && return
	 cat <<EOF
config wifi-device      mt7612e
        option type     mt7612e
        option vendor   ralink
        option band     5G
        option channel  0
        option autoch   2
        option region   1
        option aregion  0
        option country  CN
        option wifimode 14
        option bw       1
        option ht_bsscoexist 1
        option disabled 0

config wifi-iface
        option device   mt7612e
        option ifname   rai0
        option network  lan
        option mode     ap
        option ssid     $ssid
        option encryption none
        option hidden   0
        option disabled 0

EOF

}


