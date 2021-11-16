#!/bin/bash

. /srv/http/bash/common.sh

connectedCheck() {
	for (( i=0; i < $1; i++ )); do
		ifconfig | grep -q 'inet.*broadcast' && connected=1 && break
		sleep $2
	done
}

revision=$( awk '/Revision/ {print $NF}' /proc/cpuinfo )
[[ ${revision: -3:2} =~ ^(08|0c|0d|0e|11)$ ]] && onboardwireless=1

# pre-configure --------------------------------------------------------------
if [[ -e /boot/expand ]]; then # run once
	rm /boot/expand
	partition=$( mount | grep ' on / ' | cut -d' ' -f1 )
	dev=${partition:0:-2}
	[[ $dev == /dev/sd ]] && dev=${partition:0:-1}
	if (( $( sfdisk -F $dev | awk 'NR==1{print $6}' ) != 0 )); then
		echo -e "d\n\nn\n\n\n\n\nw" | fdisk $dev &>/dev/null
		partprobe $dev
		resize2fs $partition
	fi
	# no on-board wireless - remove bluetooth
	[[ -z $onboardwireless ]] && sed -i '/dtparam=krnbt=on/ d' /boot/config.txt
fi

if [[ -e /boot/backup.gz ]]; then
	mv /boot/backup.gz $dirdata/tmp
	$dirbash/system.sh datarestore
	reboot=1
fi
lcd=$( ls /boot/lcd* 2> /dev/null )
if [[ -n $lcd ]]; then
	model=${lcd/*lcd}
	[[ -z $model ]] && model=tft35a
	rm /boot/lcd*
	$dirbash/system.sh lcdset$'\n'$model
	systemctl enable localbrowser
	reboot=1
fi

if [[ -e /boot/wifi ]]; then
	readarray -t profiles <<< $( ls -p /etc/netctl | grep -v / )
	ssid=$( grep '^ESSID' /boot/wifi | cut -d'"' -f2 )
	sed -i -e '/^#\|^$/ d' -e 's/\r//' /boot/wifi
	mv /boot/wifi "/etc/netctl/$ssid"
	ifconfig wlan0 down
	netctl switch-to "$ssid"
	netctl enable "$ssid"
fi
# ----------------------------------------------------------------------------
echo mpd > $dirshm/player
mkdir $dirshm/{airplay,spotify,local,online,webradio}
$dirbash/mpd-conf.sh # mpd.service started by this script

# ( no profile && no hostapd ) || usb wifi > disable onboard
readarray -t profiles <<< $( ls -p /etc/netctl | grep -v / )
systemctl -q is-enabled hostapd && hostapd=1
(( $( rfkill | grep wlan | wc -l ) > 1 )) && usbwifi=1
if [[ -z $profiles && -z $hostapd ]] || [[ -n $usbwifi ]]; then
	rmmod brcmfmac &> /dev/null
fi
if [[ -z $onboardwireless ]]; then # usb bluetooth
	rfkill | grep -q bluetooth && systemctl enable --now bluetooth || systemctl disable --now bluetooth
fi

# wait 5s max for lan connection
connectedCheck 5 1
# if lan not connected, wait 30s max for wi-fi connection
[[ -z $connected && -n $profiles && -z $hostapd ]] && connectedCheck 30 3

[[ -n $connected  ]] && readarray -t nas <<< $( ls -d1 /mnt/MPD/NAS/*/ 2> /dev/null | sed 's/.$//' )
if [[ -n $nas ]]; then
	for mountpoint in "${nas[@]}"; do # ping target before mount
		ip=$( grep "${mountpoint// /\\\\040}" /etc/fstab \
				| cut -d' ' -f1 \
				| sed 's|^//||; s|:*/.*$||' )
		for i in {1..10}; do
			if ping -4 -c 1 -w 1 $ip &> /dev/null; then
				mount "$mountpoint" && break
			else
				(( i == 10 )) && pushstreamNotifyBlink NAS "NAS @$ip cannot be reached." nas
				sleep 2
			fi
		done
	done
fi

[[ -e /boot/startup.sh ]] && /boot/startup.sh

# after all sources connected
if [[ ! -e $dirmpd/mpd.db || $( mpc stats | awk '/Songs/ {print $NF}' ) -eq 0 ]]; then
	echo rescan > $dirsystem/updating
	mpc -q rescan
elif [[ -e $dirsystem/updating ]]; then
	path=$( cat $dirsystem/updating )
	[[ $path == rescan ]] && mpc -q rescan || mpc -q update "$path"
elif [[ -e $dirsystem/listing || ! -e $dirmpd/counts ]]; then
	$dirbash/cmd-list.sh &> dev/null &
fi

if [[ -e $dirsystem/lcdchar ]]; then
	$dirbash/lcdcharinit.py
	$dirbash/lcdchar.py
fi
[[ -e $dirsystem/mpdoled ]] && $dirbash/cmd.sh mpdoledlogo

[[ -e $dirsystem/soundprofile ]] && $dirbash/system.sh soundprofile

[[ -e $dirsystem/autoplay ]] && mpc play || $dirbash/cmd-pushstatus.sh

if [[ -n $connected ]]; then
	rfkill | grep -q wlan && iw wlan0 set power_save off
	if : >/dev/tcp/8.8.8.8/53; then
		$dirbash/cmd.sh addonsupdates
		if ! ifconfig | grep -A1 ^eth | grep -q 'inet.*broadcast'; then # not by eth
			server=$( grep '^NTP' /etc/systemd/timesyncd.conf | cut -d= -f2 )
			ntpdate $server # fix wlan time sync
		fi
	fi
else
	if [[ ! -e $dirsystem/wlannoap ]]; then
		modprobe brcmfmac &> /dev/null 
		systemctl -q is-enabled hostapd || $dirbash/features.sh hostapdset
		systemctl -q disable hostapd
	fi
fi
