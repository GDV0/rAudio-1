#!/bin/bash

# get hardware devices data with 'aplay' and amixer
# - aplay - get card index, sub-device index and aplayname
# - mixer device
#    - from file if manually set
#    - from 'amixer'
#        - if more than 1, filter with 'Digital\|Master' | get 1st one
# - mixer_type
#    - from file if manually set
#    - set as hardware if mixer device available
#    - if nothing, set as software
dirshm=/srv/http/data/shm
dirsystem=/srv/http/data/system

aplay=$( aplay -l 2> /dev/null | grep '^card' | grep -v Loopback )
if [[ -z $aplay ]]; then
	i=-1
	devices=false
	touch $dirshm/nosound
	return
fi

rm -f $dirshm/nosound
#aplay+=$'\ncard 1: sndrpiwsp [snd_rpi_wsp], device 0: WM5102 AiFi wm5102-aif1-0 []'

audioaplayname=$( cat $dirsystem/audio-aplayname 2> /dev/null )

readarray -t lines <<< "$aplay"
for line in "${lines[@]}"; do
	hw=$( echo $line | sed 's/card \(.*\):.*device \(.*\):.*/hw:\1,\2/' )
	card=${hw:3:1}
	device=${hw: -1}
	aplayname=$( echo $line \
					| awk -F'[][]' '{print $2}' \
					| sed 's/^snd_rpi_//; s/_/-/g' ) # some aplay -l: snd_rpi_xxx_yyy > xxx-yyy
	[[ $aplayname == wsp ]] && aplayname=rpi-cirrus-wm5102
	if [[ $aplayname == $audioaplayname ]]; then
		name=$( cat $dirsystem/audio-output )
	else
		name=$( echo $aplayname | sed 's/bcm2835/On-board/' )
	fi
	mixertype=$( cat "$dirsystem/mixertype-$aplayname" 2> /dev/null || echo hardware )
	controls=$( /srv/http/bash/cmd.sh volumecontrols$'\n'$card )
	if [[ -z $controls ]]; then
		mixerdevices=['"( not available )"']
		mixers=0
	else
		readarray -t controls <<< $( echo "$controls" | sort -u )
		mixerdevices=
		for control in "${controls[@]}"; do
			mixerdevices+=',"'$control'"'
		done
		mixerdevices=[${mixerdevices:1}]
		mixers=${#controls[@]}
	fi
	
	mixermanual=false
	hwmixerfile=$dirsystem/hwmixer-$aplayname
	if [[ -e $hwmixerfile ]]; then # manual
		mixermanual=true
		hwmixer=$( cat "$hwmixerfile" )
	elif [[ $aplayname == rpi-cirrus-wm5102 ]]; then
		mixers=4
		hwmixer='HPOUT2 Digital'
		mixerdevices='["HPOUT1 Digital","HPOUT2 Digital","SPDIF Out","Speaker Digital"]'
	else
		if [[ $mixers == 0 ]]; then
			[[ $mixertype == hardware ]] && mixertype=none
			hwmixer='( not available )'
		else
			hwmixer=${controls[0]}
		fi
	fi
	[[ -e "$dirsystem/dop-$aplayname" ]] && dop=1 || dop=0
	
	devices+=',{
		  "aplayname"    : "'$aplayname'"
		, "card"         : '$card'
		, "device"       : '$device'
		, "dop"          : '$dop'
		, "hw"           : "'$hw'"
		, "hwmixer"      : "'$hwmixer'"
		, "mixers"       : '$mixers'
		, "mixerdevices" : '$mixerdevices'
		, "mixermanual"  : '$mixermanual'
		, "mixertype"    : "'$mixertype'"
		, "name"         : "'$name'"
	}'
	Aaplayname+=( "$aplayname" )
	Acard+=( "$card" )
	Adevice+=( "$device" )
	Adop+=( "$dop" )
	Ahw+=( "$hw" )
	Ahwmixer+=( "$hwmixer" )
	Amixers+=( "$mixers" )
	Amixermanual+=( "$mixermanual" )
	Amixertype+=( "$mixertype" )
	Aname+=( "$name" )
done

if [[ -e /etc/asound.conf ]]; then
	i=$( head -1 /etc/asound.conf | cut -d' ' -f2 )
	(( $i > $card )) && i=$card
else
	i=0
fi

devices="[ ${devices:1} ]"
aplayname=${Aaplayname[i]}
output=${Aname[i]}
