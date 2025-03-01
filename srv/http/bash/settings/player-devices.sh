#!/bin/bash

# get hardware devices data with 'aplay' and amixer
# - aplay - get card index, sub-device index and aplayname
# - mixer device
#    - from file if manually set
#    - from 'amixer'
#        - if more than 1, filter with 'Digital|Master' | get 1st one
# - mixer_type
#    - from file if manually set
#    - set as hardware if mixer device available
#    - if nothing, set as software

### included by player-conf.sh, player-data.sh

aplay=$( aplay -l 2> /dev/null | grep '^card' )
if [[ ! $aplay ]]; then
	[[ -e $dirshm/btreceiver ]] && i=0 || i=-1
	devices=false
	touch $dirshm/nosound
	pushstream display '{"volumenone":true}'
	return
fi

getControls() {
	amixer=$( amixer -c $1 scontents )
	[[ ! $amixer ]] && controls= && return
	
	amixer=$( grep -A1 ^Simple <<< $amixer \
				| sed 's/^\s*Cap.*: /^/' \
				| tr -d '\n' \
				| sed 's/--/\n/g' \
				| grep -v "'Mic'" )
	controls=$( grep -E 'volume.*pswitch|Master.*volume' <<< $amixer )
	[[ ! $controls ]] && controls=$( grep volume <<< $amixer )
	[[ $controls ]] && controls=$( cut -d"'" -f2 <<< $controls )
}

rm -f $dirshm/nosound
#aplay+=$'\ncard 1: sndrpiwsp [snd_rpi_wsp], device 0: WM5102 AiFi wm5102-aif1-0 []'

[[ -e $dirsystem/audio-aplayname ]] && audioaplayname=$( < $dirsystem/audio-aplayname )

cards=$( cut -d: -f1 <<< $aplay \
			| sort -u \
			| sed 's/card //' )
for card in $cards; do
	line=$( sed -n "/^card $card/ p" <<< $aplay )
	hw=$( sed -E 's/card (.*):.*device (.*):.*/hw:\1,\2/' <<< $line )
	card=${hw:3:1}
	device=${hw: -1}
	aplayname=$( sed -E 's/.*\[(.*)],.*/\1/; s/^snd_rpi_//; s/_/-/g' <<< $line ) # some aplay -l: snd_rpi_xxx_yyy > xxx-yyy
	if [[ $aplayname == Loopback ]]; then
		device=; hw=; hwmixer=; mixers=; mixerdevices=; mixermanual=; mixertype=; name=;
		devices+=',{
  "aplayname"    : "'$aplayname'"
, "card"         : '$card'
}'
	else
		[[ $aplayname == wsp || $aplayname == RPi-Cirrus ]] && aplayname=rpi-cirrus-wm5102
		if [[ $aplayname == $audioaplayname ]]; then
			name=$( < $dirsystem/audio-output )
		else
			name=${aplayname/bcm2835/On-board}
		fi
		[[ -e "$dirsystem/mixertype-$aplayname" ]] && mixertype=$( < "$dirsystem/mixertype-$aplayname" ) || mixertype=hardware
		getControls $card
		if [[ ! $controls ]]; then
			mixerdevices=['"( not available )"']
			mixers=0
		else
			readarray -t controls <<< $( sort -u <<< $controls )
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
			hwmixer=$( < "$hwmixerfile" )
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
		devices+=',{
  "aplayname"    : "'$aplayname'"
, "card"         : '$card'
, "device"       : '$device'
, "hw"           : "'$hw'"
, "hwmixer"      : "'$hwmixer'"
, "mixers"       : '$mixers'
, "mixerdevices" : '$mixerdevices'
, "mixermanual"  : '$mixermanual'
, "mixertype"    : "'$mixertype'"
, "name"         : "'$name'"
}'
	fi
	Aaplayname[card]=$aplayname
	Acard[card]=$card
	Adevice[card]=$device
	Ahw[card]=$hw
	Ahwmixer[card]=$hwmixer
	Amixers[card]=$mixers
	Amixermanual[card]=$mixermanual
	Amixertype[card]=$mixertype
	Aname[card]=$name
done

if [[ $usbdac == add ]]; then
	mv $dirsystem/asoundcard{,.backup} &> /dev/null
	echo $card > $dirsystem/asoundcard
elif [[ $usbdac == remove && -e $dirsystem/asoundcard.backup ]]; then
	mv $dirsystem/asoundcard{.backup,} &> /dev/null
elif [[ -e $dirsystem/asoundcard ]]; then
	asoundcard=$( < $dirsystem/asoundcard )
	! grep -v Loopback <<< $aplay | grep -q -m1 "^card $asoundcard" && echo ${Acard[0]} > $dirsystem/asoundcard
else
	echo ${Acard[0]} > $dirsystem/asoundcard
fi
i=$( < $dirsystem/asoundcard )

echo Ahwmixer[i] > $dirshm/amixercontrol

getControls $i
if [[ $controls ]]; then
	sort -u <<< $controls | head -1 > $dirshm/amixercontrol
else
	rm -f $dirshm/amixercontrol
fi

devices="[ ${devices:1} ]"
aplayname=${Aaplayname[i]}
output=${Aname[i]}
