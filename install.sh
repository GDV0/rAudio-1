#!/bin/bash

alias=r1

. /srv/http/bash/addons.sh

# 20221123
grep -q calc /srv/http/bash/xinitrc && restartbrowser=1

mv /etc/udev/rules.d/ntfs{3,}.rules &> /dev/null
file=/etc/udev/rules.d/ntfs.rules
if [[ ! -e $file ]]; then
	cat << 'EOF' > $file
ACTION=="add", \
SUBSYSTEM=="block", \
ENV{ID_FS_TYPE}=="ntfs", \
ENV{ID_FS_TYPE}="ntfs3", \
RUN+="/srv/http/bash/settings/system.sh usbconnect"

ACTION=="remove", \
SUBSYSTEM=="block", \
ENV{ID_FS_TYPE}=="ntfs", \
ENV{ID_FS_TYPE}="ntfs3", \
RUN+="/srv/http/bash/settings/system.sh usbremove"
EOF
	udevadm control --reload-rules
	udevadm trigger
fi

# 20221122
sed -i '/shairport-sync/ d' /etc/pacman.conf
veropenssl=$( pacman -Q openssl | cut -d' ' -f2 | cut -c 1 )
vershairport=$( pacman -Q shairport-sync | cut -d' ' -f2 | cut -c 1 )
[[ $veropenssl == 3 && $vershairport != 4 ]]  && pacman -Sy --noconfirm shairport-sync

# 20221117
dirbash=/srv/http/bash
dirsettings=$dirbash/settings
dirdata=/srv/http/data
dirmpd=$dirdata/mpd
dirmpdconf=$dirdata/mpdconf
dirshm=$dirdata/shm
dirsystem=$dirdata/system

[[ -e $dirsystem/loginset ]] && mv -f $dirsystem/login{set,}

[[ ! -e $dirdata/mpdconf ]] && backup=1

sed -i '/interfaces/ d' /etc/samba/smb.conf
systemctl try-restart smb 

file=/etc/systemd/system/bluetooth.service.d/override.conf
if grep -q bluetooth$ $file; then
	sed -i 's/bluetooth$/&start/' $file
	systemctl daemon-reload
fi

if [[ -L $dirmpd  && ! -e /mnt/MPD/.mpdignore ]]; then
	echo "\
SD
USB" > /mnt/MPD/.mpdignore
fi

# 20221007
grep -q hard,intr /etc/fstab && sed -i '/hard,intr/soft/' /etc/fstab

[[ -e $dirsystem/hddspindown ]] && mv $dirsystem/{hddspindown,apm}

if [[ ! -e /boot/kernel.img ]]; then
	dir=/etc/systemd/system
	for file in $dir/spotifyd.service $dir/upmpdcli.service; do
		! grep -q CPUAffinity $file && sed -i -e '/Service/ a\CPUAffinity=3' -e '/ExecStartPost/ d' -e 's|/usr/bin/taskset -c 3 ||' $file
	done
	for file in $dir/bluealsa.service.d/override.conf $dir/bluetooth.service.d/override.conf; do
		! grep -q CPUAffinity $file && sed -i -e '/Service/ a\CPUAffinity=3' $file
	done
fi

dir=/srv/http/assets/img/guide
if [[ ! -e $dir/1.jpg ]]; then
	mkdir -p $dir
	if [[ -e /srv/http/assets/img/1.jpg ]]; then
		find /srv/http/assets/img -maxdepth 1 -type f -name '[0-9]*' -exec mv {} $dir \;
	else
		curl -skL https://github.com/rern/_assets/raw/master/guide/guide.tar.xz | bsdtar xf - -C $dir
	fi
fi

file=/etc/systemd/system/dab.service
if [[ -e /usr/bin/rtl_sdr && ! -e $file ]]; then
	echo "\
[Unit]
Description=DAB Radio metadata

[Service]
Type=simple
ExecStart=/srv/http/bash/status-dab.sh
" > $file
	systemctl daemon-reload
fi

#-------------------------------------------------------------------------------
installstart "$1"

getinstallzip

chmod +x $dirsettings/system.sh
$dirsettings/system.sh dirpermissions
[[ -e $dirsystem/color ]] && $dirbash/cmd.sh color

#installfinish
#-------------------------------------------------------------------------------

# 20221123
[[ $restartbrowser ]] && systemctl try-restart localbrowser

# 20221010
[[ -e /srv/http/shareddata ]] && echo -e "$info Shared Data must be disabled and setup again."

# 20221117
overrideconf=/etc/systemd/system/mpd.service.d/override.conf
grep -q systemd $overrideconf && installfinish && exit

echo -e "\n$bar Rearrange MPD Configuration...\n"

cat << EOF > $overrideconf
[Unit]
BindsTo=mpdidle.service

[Service]
CPUAffinity=3
ExecStart=
ExecStart=/usr/bin/mpd --systemd /srv/http/data/mpdconf/mpd.conf
EOF
[[ -e /boot/kernel.img ]] && sed -i '/CPUAffinity/ d' $overrideconf

mkdir -p $dirmpdconf

linkConf() {
	ln -s $dirmpdconf/{conf/,}$1.conf
}

[[ -e $dirsystem/custom-global ]] && mv $dirsystem/custom-global $dirmpdconf/conf/custom.conf
if [[ -e $dirsystem/soxr.conf ]]; then
	echo "\
resampler {
	plugin          \"soxr\"
$( < $dirsystem/soxr.conf )" > $dirmpdconf/conf/soxr-custom.conf
fi
grep -q 'mixer_type.*none' /etc/mpd.conf \
    && grep -q 'replaygain.*off' /etc/mpd.conf \
    && ! grep -q normalization /etc/mpd.conf \
    && novolume=1
if [[ ! $novolume ]]; then
	if grep -q quality.*custom /etc/mpd.conf; then
		linkConf soxr-custom
		echo custom > $dirsystem/soxr
	else
		linkConf soxr
		echo 'very high' > $dirsystem/soxr
	fi
fi

grep -q auto_update /etc/mpd.conf && linkConf autoupdate
if grep -q audio_buffer /etc/mpd.conf; then
	echo 'audio_buffer_size  "'$( < $dirsystem/buffer.conf )'"' > $dirmpdconf/conf/buffer.conf
	linkConf buffer
fi
if grep -q output_buffer /etc/mpd.conf; then
	echo 'max_output_buffer_size  "'$( < $dirsystem/bufferoutput.conf )'"' > $dirmpdconf/conf/outputbuffer.conf
	linkConf outputbuffer
fi
grep -q volume_normalization /etc/mpd.conf && linkConf normalization
if ! grep -q replaygain.*off /etc/mpd.conf; then
	echo 'replaygain  "'$( < $dirsystem/replaygain.conf )'"' > $dirmpdconf/conf/replaygain.conf
	linkConf replaygain
fi

[[ -e $dirshm/audiocd ]] && linkConf cdio
[[ -e $dirsystem/custom && -e $dirmpdconf/conf/custom.conf ]] && linkConf custom
grep -q plugin.*ffmpeg /etc/mpd.conf && linkConf ffmpeg
grep -q type.*httpd /etc/mpd.conf && linkConf httpd
systemctl -q is-active snapserver && linkConf snapserver

rm -f $dirsystem/{buffer,bufferoutput,replaygain,soxr}.conf $dirsystem/{crossfade,streaming}

systemctl daemon-reload

$dirsettings/player-conf.sh

installfinish

echo -e "$info Backup of Data and Settings: Backup again to include new configuration"
