#!/bin/bash

. /srv/http/bash/common.sh

systemctl stop mpd
rm -f $dirsystem/{relays,soundprofile,updating,listing,buffer,bufferoutput,crossfade,custom,replaygain,soxr}

# lcd
file=/etc/modules-load.d/raspberrypi.conf
[[ -e $file ]] && sed -i '/i2c-bcm2708\|i2c-dev/ d' $file
#file=/usr/share/X11/xorg.conf.d/99-fbturbo.conf
#[[ -e $file ]] && sed -i 's/fb1/fb0/' $file

if [[ $1 ]]; then # from create-ros.sh
	version=$1
	revision=$2
else                 # restore
	mv $diraddons /tmp
	rm -rf $dirdata
	partuuidROOT=$( grep ext4 /etc/fstab | cut -d' ' -f1 )
	cmdline="root=$partuuidROOT rw rootwait selinux=0 plymouth.enable=0 smsc95xx.turbo_mode=N \
dwc_otg.lpm_enable=0 elevator=noop ipv6.disable=1 fsck.repair=yes"
	revision=$( awk '/Revision/ {print $NF}' /proc/cpuinfo )
	revision=${revision: -3:2}
	[[ $revision =~ ^(04|08|0d|0e|11)$ ]] && cmdline+=' isolcpus=3'
	if systemctl is-enabled localbrowser &> /dev/null; then
		config+=' console=tty3 quiet loglevel=0 logo.nologo vt.global_cursor_default=0'
	else
		config+=' console=tty1'
	fi
	echo $cmdline > /boot/cmdline.txt
	config="\
gpu_mem=32
initramfs initramfs-linux.img followkernel
max_usb_current=1
disable_splash=1
disable_overscan=1
dtparam=audio=on"
	[[ -e /boot/kernel8.img || $revision =~ ^(08|0c|0d|0e|11)$ ]] && config+="
dtparam=krnbt=on"
	[[ $revision =~ ^(09|0c)$ ]] && config+="
force_turbo=1
hdmi_drive=2
over_voltage=2"
	echo "$config" > /boot/config.txt
fi
# data directories
mkdir -p $dirdata/{addons,audiocd,bookmarks,lyrics,mpd,playlists,system,tmp,webradios,webradiosimg} /mnt/MPD/{NAS,SD,USB}
ln -sf /dev/shm $dirdata
# addons - new/restore
if [[ $version ]]; then # from create-ros.sh
	echo $version > $dirsystem/version
	echo $revision > $diraddons/r$version
else
	mv /tmp/addons $dirdata
fi
# display
cat << EOF > $dirsystem/display
{
	"album": true,
	"albumbyartist": false,
	"albumartist": true,
	"artist": true,
	"composer": true,
	"conductor": true,
	"date": true,
	"genre": true,
	"nas": true,
	"sd": true,
	"usb": true,
	"webradio": true,
	"backonleft": false,
	"count": true,
	"fixedcover": true,
	"hidecover": false,
	"label": true,
	"playbackswitch": true,
	"plclear": true,
	"tapaddplay": false,
	"tapreplaceplay": false,
	"bars": true,
	"barsalways": false,
	"buttons": true,
	"cover": true,
	"covervu": false,
	"noswipe": false,
	"radioelapsed": false,
	"noswipe": false,
	"time": true,
	"volume": true,
	"vumeter": false
}
EOF
# localbrowser
if [[ -e /usr/bin/chromium ]]; then
	rm -rf /root/.config/chromium
	echo "\
rotate=NORMAL
zoom=100
screenoff=0
onwhileplay=false
cursor=false" > $dirsystem/localbrowser.conf
fi
echo mpd > $dirshm/player
# relays
cat << EOF > $dirsystem/relays.conf
pin='[ 11,13,15,16 ]'
name='[ "DAC","PreAmp","Amp","Subwoofer" ]'
onorder='[ "DAC","PreAmp","Amp","Subwoofer" ]'
offorder='[ "Subwoofer","Amp","PreAmp", "DAC" ]'
on=( 11 13 15 16 )
ond=( 2 2 2 )
off=( 16 15 13 11 )
offd=( 2 2 2 )
timer=5
EOF
# system
echo rAudio > $dirsystem/hostname
hostnamectl set-hostname rAudio
sed -i 's/#NTP=.*/NTP=pool.ntp.org/' /etc/systemd/timesyncd.conf
sed -i 's/".*"/"00"/' /etc/conf.d/wireless-regdom
timedatectl set-timezone UTC
echo UTC > $dirsystem/timezone

# mpd
sed -i -e '/^auto_update\|^audio_buffer_size\| #custom$/ d
' -e '/quality/,/}/ d
' -e '/soxr/ a\
	quality        "very high"\
}
' /etc/mpd.conf

usermod -a -G root http # add user http to group root to allow /dev/gpiomem access

# webradio default
curl -L https://github.com/rern/rAudio-addons/raw/main/webradio/radioparadise.tar.xz | bsdtar xvf - -C /
[[ ! -e $dirdata/mpd/counts ]] && echo '{"webradio":'$( ls -1q $dirdata/webradios | wc -l )'}' > $dirdata/mpd/counts

# services
systemctl -q disable --now bluetooth hostapd shairport-sync smb snapserver spotifyd upmpdcli

# set permissions and ownership
chown -R http:http /srv/http
chown -R mpd:audio $dirmpd /mnt/MPD
chmod 755 /srv/http/* $dirbash/* /srv/http/settings/*
chmod 777 $dirdata/tmp

# symlink /mnt for coverart files
ln -sf /mnt /srv/http/

[[ $version ]] && exit

systemctl start mpd

curl -s -X POST http://127.0.0.1/pub?id=restore -d '{"restore":"reload"}' &> /dev/null
