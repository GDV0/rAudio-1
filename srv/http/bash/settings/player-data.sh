#!/bin/bash

. /srv/http/bash/common.sh
. player-devices.sh

active=$( mpc &> /dev/null && echo true )
if [[ -e $dirsystem/soxr.conf ]]; then
	soxrconf="[ $( grep -E -v 'quality|}' $dirsystem/soxr.conf | cut -d'"' -f2 | xargs | tr ' ' , ) ]"
else
	soxrconf='[ 20, 50, 91.3, 100, 0, 0 ]'
fi
state=$( grep ^state $dirshm/status 2> /dev/null | cut -d'"' -f2 )
[[ ! $state ]] && state=stop

data='
  "page"             : "player"
, "devices"          : '$devices'
, "active"           : '$active'
, "asoundcard"       : '$i'
, "audioaplayname"   : "'$aplayname'"
, "audiooutput"      : "'$output'"
, "autoupdate"       : '$( grep -q '^auto_update.*yes' /etc/mpd.conf && echo true )'
, "btaplayname"      : "'$( cat $dirshm/btreceiver 2> /dev/null )'"
, "buffer"           : '$( grep -q '^audio_buffer_size' /etc/mpd.conf && echo true )'
, "bufferconf"       : '$( cat $dirsystem/buffer.conf 2> /dev/null || echo 4096 )'
, "bufferoutput"     : '$( grep -q '^max_output_buffer_size' /etc/mpd.conf && echo true )'
, "bufferoutputconf" : '$( cat $dirsystem/bufferoutput.conf 2> /dev/null || echo 8192 )'
, "camilladsp"       : '$( exists $dirsystem/camilladsp )'
, "counts"           : '$( cat $dirmpd/counts 2> /dev/null )'
, "crossfade"        : '$( [[ $active == true && $( mpc crossfade | cut -d' ' -f2 ) != 0 ]] && echo true )'
, "crossfadeconf"    : '$( cat $dirsystem/crossfade.conf 2> /dev/null || echo 1 )'
, "custom"           : '$( exists $dirsystem/custom )'
, "dabradio"         : '$( isactive rtsp-simple-server )'
, "equalizer"        : '$( exists $dirsystem/equalizer )'
, "ffmpeg"           : '$( grep -q 'plugin.*ffmpeg' /etc/mpd.conf && echo true )'
, "lists"            : ['$( exists $dirmpd/albumignore )','$( exists $dirmpd/pdignorelist )','$( exists $dirmpd/nonutf8 )']
, "normalization"    : '$( grep -q 'volume_normalization.*yes' /etc/mpd.conf && echo true )'
, "player"           : "'$( cat $dirshm/player )'"
, "replaygain"       : '$( ! grep -q '^replaygain.*off' /etc/mpd.conf && echo true )'
, "replaygainconf"   : "'$( cat $dirsystem/replaygain.conf 2> /dev/null || echo auto )'"
, "soxr"             : '$( sed -n '/^resampler/,/}/ p' /etc/mpd.conf | grep -q 'quality.*custom' && echo true )'
, "soxrconf"         : '$soxrconf'
, "state"            : "'$state'"
, "version"          : "'$( pacman -Q mpd 2> /dev/null |  cut -d' ' -f2 )'"'

data2json "$data" $1
