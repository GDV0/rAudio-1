#!/bin/bash

. /srv/http/bash/common.sh

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	data=$( $dirbash/player-data.sh )
	pushstream refresh "$data"
}
volumeBtGet() {
	voldb=$( amixer -MD bluealsa 2> /dev/null \
		| grep -m1 '%.*dB' \
		| sed 's/.*\[\(.*\)%\] \[\(.*\)dB.*/\1 \2/' )
}
restartMPD() {
	$dirbash/mpd-conf.sh
}
update() { # for /etc/conf.d/devmon - devmon@http.service
	if [[ -e $dirmpd/updating ]]; then
		$dirshm/updatingusb
	else
		echo USB > $dirmpd/updating
		mpc -q update USB
	fi
	sleep 1
	pushRefresh
	pushstream mpdupdate 1
}

case ${args[0]} in

audiooutput )
	aplayname=${args[1]}
	card=${args[2]}
	output=${args[3]}
	mixer=${args[4]}
	sed -i "s/.$/$card/" /etc/asound.conf
	restartMPD
	;;
autoupdate )
	if [[ ${args[1]} == true ]]; then
		sed -i '1 i\auto_update            "yes"' /etc/mpd.conf
	else
		sed -i '/^auto_update/ d' /etc/mpd.conf
	fi
	restartMPD
	;;
bufferdisable )
	sed -i '/^audio_buffer_size/ d' /etc/mpd.conf
	restartMPD
	;;
bufferset )
	buffer=${args[1]}
	sed -i '/^audio_buffer_size/ d' /etc/mpd.conf
	if (( $buffer == 4096 )); then
		rm -f $dirsystem/buffer.conf
	else
		sed -i '1 i\audio_buffer_size      "'$buffer'"' /etc/mpd.conf
		echo $buffer > $dirsystem/buffer.conf
	fi
	restartMPD
	;;
bufferoutputdisable )
	sed -i '/^max_output_buffer_size/ d' /etc/mpd.conf
	restartMPD
	;;
bufferoutputset )
	buffer=${args[1]}
	sed -i '/^max_output_buffer_size/ d' /etc/mpd.conf
	if (( $buffer == 8192 )); then
		rm -f $dirsystem/bufferoutput.conf
	else
		sed -i '1 i\max_output_buffer_size "'$buffer'"' /etc/mpd.conf
		echo $buffer > $dirsystem/bufferoutput.conf
	fi
	restartMPD
	;;
count )
	albumartist=$( mpc list albumartist | awk NF | wc -l )
	composer=$( mpc list composer | awk NF | wc -l )
	genre=$( mpc list genre | awk NF | wc -l )
	count="$count $( mpc stats | head -n3 | awk '{print $2,$4,$6}' )"

	data='
		  "album"       : '$( echo $count | cut -d' ' -f2 )'
		, "albumartist" : '$albumartist'
		, "artist"      : '$( echo $count | cut -d' ' -f1 )'
		, "composer"    : '$composer'
		, "coverart"    : '$( ls -1q $dirdata/coverarts | wc -l )'
		, "date"        : '$( mpc list date | awk NF | wc -l )'
		, "genre"       : '$genre'
		, "nas"         : '$( mpc ls NAS 2> /dev/null | wc -l )'
		, "sd"          : '$( mpc ls SD 2> /dev/null | wc -l )'
		, "song"        : '$( echo $count | cut -d' ' -f3 )'
		, "usb"         : '$( mpc ls USB 2> /dev/null | wc -l )'
		, "webradio"    : '$( ls -U $dirwebradios/* 2> /dev/null | wc -l )
	mpc | grep -q Updating && data+=', "updating_db":1'
	echo {$data}
	echo $albumartist $composer $genre > $dirsystem/mpddb
	;;
crossfadedisable )
	mpc -q crossfade 0
	pushRefresh
	;;
crossfadeset )
	crossfade=${args[1]}
	mpc -q crossfade $crossfade
	echo $crossfade > $dirsystem/crossfade.conf
	touch $dirsystem/crossfade
	pushRefresh
	;;
customdisable )
	sed -i '/ #custom$/ d' /etc/mpd.conf
	rm -f $dirsystem/custom
	restartMPD
	;;
customget )
	global=$( cat $dirsystem/custom-global 2> /dev/null )
	output=$( cat "$dirsystem/custom-output-${args[1]}" 2> /dev/null )
	echo "\
$global
^^
$output"
	;;
customset )
	file=$dirsystem/custom
	global=${args[1]}
	output=${args[2]}
	aplayname=${args[3]}
	[[ $global ]] && echo -e "$global" > $file-global || rm -f $file-global
	if [[ $output ]]; then
		echo -e "$output" > "$file-output-$aplayname"
	else
		rm -f "$file-output-$aplayname"
	fi
	[[ $global || $output ]] && touch $file
	restartMPD
	if ! systemctl -q is-active mpd; then
		sed -i '/ #custom$/ d' /etc/mpd.conf
		rm -f $dirsystem/custom
		restartMPD
		echo -1
	fi
	;;
devices )
	devices+=$'<bll># aplay -l | grep ^card</bll>\n'$( aplay -l | grep ^card )
	devices+=$'\n\n<bll># amixer scontrols</bll>\n'
	card=$( cat $dirshm/asoundcard )
	aplayname=$( aplay -l | grep "^card $card" | awk -F'[][]' '{print $2}' )
	if [[ $aplayname != snd_rpi_wsp ]]; then
		devices+=$( amixer -c $card scontrols )
	else
		devices+="\
Simple mixer control 'HPOUT1 Digital',0
Simple mixer control 'HPOUT2 Digital',0
Simple mixer control 'SPDIF Out',0
Simple mixer control 'Speaker Digital',0"
	fi
	[[ -e $dirshm/btclient ]] && devices+=$'\n\n<bll># bluealsa-aplay -L</bll>\n'$( bluealsa-aplay -L )
	devices+=$'\n\n<bll># cat /etc/asound.conf</bll>\n'$( cat /etc/asound.conf )
	echo "$devices"
	;;
dop )
	dop=${args[1]}
	aplayname=${args[2]}
	if [[ $dop == true ]]; then
		touch "$dirsystem/dop-$aplayname"
	else
		rm -f "$dirsystem/dop-$aplayname"
	fi
	restartMPD
	;;
equalizer )
	if [[ ${args[1]} == true ]]; then
		touch $dirsystem/equalizer
	else
		$dirbash/cmd.sh "equalizer
preset
Flat"
		rm -f $dirsystem/equalizer
	fi
	pushstream display '{"submenu":"equalizer","value":'${args[1]}'}'
	restartMPD
	;;
ffmpeg )
	if [[ ${args[1]} == true ]]; then
		sed -i '/ffmpeg/ {n; s/".*"/"yes"/}' /etc/mpd.conf
	else
		sed -i '/ffmpeg/ {n; s/".*"/"no"/}' /etc/mpd.conf
	fi
	restartMPD
	;;
filetype )
	type=$( mpd -V | grep '\[ffmpeg' | sed 's/.*ffmpeg. //; s/ rtp.*//' | tr ' ' '\n' | sort )
	for i in {a..z}; do
		line=$( grep ^$i <<<"$type" | tr '\n' ' ' )
		[[ $line ]] && list+=${line:0:-1}'<br>'
	done
	echo "${list:0:-4}"
	;;
hwmixer )
	aplayname=${args[1]}
	hwmixer=${args[2]}
	echo $hwmixer > "$dirsystem/hwmixer-$aplayname"
	sed -i '/mixer_control_name = / s/".*"/"'$hwmixer'"/' /etc/shairport-sync.conf
	systemctl try-restart shairport-sync shairport-meta
	restartMPD
	;;
mixertype )
	mixertype=${args[1]}
	aplayname=${args[2]}
	hwmixer=${args[3]}
	if [[ $hwmixer ]]; then # set 0dB
		mpc -q stop
		if [[ $mixertype == hardware ]];then
			vol=$( mpc volume | cut -d: -f2 | tr -d ' %' )
			amixer -Mq sset "$hwmixer" $vol%
		else
			amixer -Mq sset "$hwmixer" 0dB
		fi
	fi
	if [[ $mixertype == hardware ]]; then
		rm -f "$dirsystem/mixertype-$aplayname"
	else
		echo $mixertype > "$dirsystem/mixertype-$aplayname"
	fi
	restartMPD
	curl -s -X POST http://127.0.0.1/pub?id=display -d '{ "volumenone": '$( [[ $mixertype == none ]] && echo true || echo false )' }'
	;;
mpdignorelist )
	file=$dirmpd/mpdignorelist
	readarray -t files < $file
	list="\
<bll># find /mnt/MPD -name .mpdignore</bll>


"
	for file in "${files[@]}"; do
		list+="\
$file
$( cat "$file" | sed 's|^| <grn>●</grn> |' )
"
	done
	echo "$list"
	;;
normalization )
	if [[ ${args[1]} == true ]]; then
		sed -i '/^user/ a\volume_normalization   "yes"' /etc/mpd.conf
	else
		sed -i '/^volume_normalization/ d' /etc/mpd.conf
	fi
	restartMPD
	;;
novolume )
	aplayname=${args[1]}
	card=${args[2]}
	hwmixer=${args[3]}
	sed -i -e '/volume_normalization/ d
	' -e '/^replaygain/ s/".*"/"off"/
	' /etc/mpd.conf
	mpc -q crossfade 0
	amixer -Mq sset "$hwmixer" 0dB
	echo none > "$dirsystem/mixertype-$aplayname"
	rm -f $dirsystem/{camilladsp,crossfade,equalizer,replaygain,normalization}
	restartMPD
	curl -s -X POST http://127.0.0.1/pub?id=display -d '{ "volumenone": true }'
	;;
replaygaindisable )
	sed -i '/^replaygain/ s/".*"/"off"/' /etc/mpd.conf
	restartMPD
	;;
replaygainset )
	replaygain=${args[1]}
	sed -i '/^replaygain/ s/".*"/"'$replaygain'"/' /etc/mpd.conf
	echo $replaygain > $dirsystem/replaygain.conf
	restartMPD
	;;
restart )
	restartMPD
	;;
soxrdisable )
	sed -i -e '/quality/,/}/ d
' -e '/soxr/ a\
	quality        "very high"\
}
' /etc/mpd.conf
	restartMPD
	;;
soxrset )
	echo '	quality        "custom"
	precision      "'${args[1]}'"
	phase_response "'${args[2]}'"
	passband_end   "'${args[3]}'"
	stopband_begin "'${args[4]}'"
	attenuation    "'${args[5]}'"
	flags          "'${args[6]}'"
}' > $dirsystem/soxr.conf
	sed -i -e '/quality/,/}/ d
' -e "/soxr/ r $dirsystem/soxr.conf
" /etc/mpd.conf
	restartMPD
	;;
volume0db )
	amixer -c ${args[1]} -Mq sset "${args[2]}" 0dB
	level=$( $dirbash/cmd.sh volumeget )
	pushstream volume '{"val":'$level',"db":"0.00"}'
	;;
volumebt0db )
	amixer -D bluealsa -q sset "${args[1]}" 0dB 2> /dev/null
	volumeBtGet
	pushstream volumebt '{"val":'${voldb/ *}',"db":"0.00"}'
	;;
volumebtget )
	volumeBtGet
	echo $voldb
	;;
volumebtsave )
	echo ${args[1]} > "$dirsystem/btvolume-${args[2]}"
	volumeBtGet
	pushstream volumebt '{"val":'${voldb/ *}',"db":"'${voldb/* }'"}'
	;;
volumeget )
	$dirbash/cmd.sh volumeget$'\n'${args[1]}
	;;
	
esac
