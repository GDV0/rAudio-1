#!/bin/bash

# RPi as renderer - status.sh > this:
#    - retreive current status from dbus

dest=$( cat /srv/http/data/shm/bluetoothdest )
data=$( dbus-send \
			--system \
			--type=method_call \
			--print-reply \
			--dest=org.bluez $dest \
			org.freedesktop.DBus.Properties.GetAll \
			string:org.bluez.MediaPlayer1 \
			| grep -A1 'string.*Status\|string.*Title\|string.*Album\|string.*Artist\|string.*Duration\|string.*Position' \
			| sed 's/^\s*string "\|^\s*variant\s*string "\|^\s*variant\s*uint32 //; s/"$//' \
			| tr '\n' ^ \
			| sed 's/\^--\^/\n/g; s/\^$//' )
Artist=$( grep ^Artist <<< "$data" | cut -d^ -f2 )
Title=$( grep ^Title <<< "$data" | cut -d^ -f2 )
Album=$( grep ^Album <<< "$data" | cut -d^ -f2 )
Position=$( grep ^Position <<< "$data" | cut -d^ -f2 )
Duration=$( grep ^Duration <<< "$data" | cut -d^ -f2 )
Status=$( grep ^Status <<< "$data" | cut -d^ -f2 )
case $Status in
	paused )  state=pause;;
	playing ) state=play;;
	stopped ) state=stop;;
esac

name=$( echo $Artist$Album | tr -d ' "`?/#&'"'" )
onlinefile=$( ls /srv/http/data/shm/online/$name.* 2> /dev/null ) # jpg / png
if [[ -e $onlinefile ]]; then
	coverart=/data/shm/online/$name.$( date +%s ).${onlinefile/*.}
else
	/srv/http/bash/status-coverartonline.sh "$Artist"$'\n'"$Album" &> /dev/null &
fi
elapsed=$( [[ ! $Position ]] && echo false || awk "BEGIN { printf \"%.0f\n\", $Position / 1000 }" )
Time=$( [[ ! $Duration ]] && echo false || awk "BEGIN { printf \"%.0f\n\", $Duration / 1000 }" )
timestamp=$( date +%s%3N )

data='
, "Artist"    : "'$Artist'"
, "Title"     : "'$Title'"
, "Album"     : "'$Album'"
, "coverart"  : "'$coverart'"
, "elapsed"   : '$elapsed'
, "sampling"  : "Bluetooth"
, "state"     : "'$state'"
, "Time"      : '$Time'
, "timestamp" : '$timestamp

echo "$data"
