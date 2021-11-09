#!/bin/bash

# spotifyd.conf > this:
#    - spotifyd 'onevent' hook
# env var:
# $PLAYER_EVENT: change/endoftrack/load/pause/play/preload/start/stop/volumeset
# $TRACK_ID
# $PLAY_REQUEST_ID
# $POSITION_MS
# $DURATION_MS
# $VOLUME

# currently not available on spotifyd
[[ $PLAYER_EVENT == volumeset ]] && /srv/http/bbash/cmd.sh volumepushstream && exit

dirbash=/srv/http/bash
dirshm=/srv/http/data/shm
dirsystem=/srv/http/data/system
dirspotify=$dirshm/spotify

# var fileKEY=$dirspotify/KEY
for key in elapsed expire start state status token; do
	printf -v file$key '%s' $dirspotify/$key
done

pushstream() {
	curl -s -X POST http://127.0.0.1/pub?id=$1 -d "$2"
}

##### start
[[ $PLAYER_EVENT == start && ! -e $dirshm/player-spotify ]] && $dirbash/cmd.sh playerstart$'\n'spotify
if [[ -e $fileexpire && $( cat $fileexpire ) > $( date +%s ) ]]; then
	token=$( cat $filetoken )
else
	. $dirsystem/spotify # base64client, refreshtoken
	token=$( curl -s -X POST https://accounts.spotify.com/api/token \
				-H "Authorization: Basic $base64client" \
				-d grant_type=refresh_token \
				-d refresh_token=$refreshtoken \
				| grep access_token \
				| cut -d'"' -f4 )
	if [[ -z $token ]]; then
		pushstream notify '{"title":"Spotify","text":"Access token renewal failed.","icon":"spotify"}'
		exit
	fi
	
	echo $token > $filetoken
	echo $(( $( date +%s ) + 3550 )) > $fileexpire # 10s before 3600s
fi
readarray -t status <<< $( curl -s -X GET https://api.spotify.com/v1/me/player/currently-playing \
							-H "Authorization: Bearer $token" \
							| jq '.item.album.name,
								.item.album.artists[0].name,
								.item.album.images[0].url,
								.is_playing,
								.item.duration_ms,
								.item.name,
								.progress_ms,
								.timestamp' ) # not -r to keep escaped characters
[[ ${status[3]} == true ]] && state=play || state=pause
cat << EOF > $filestatus
, "Album"    : ${status[0]}
, "Artist"   : ${status[1]}
, "coverart" : ${status[2]}
, "file"     : ""
, "sampling" : "48 kHz 320 kbit/s &bull; Spotify"
, "state"    : "$state"
, "Time"     : $(( ( ${status[4]} + 500 ) / 1000 ))
, "Title"    : ${status[5]}
EOF
progress=${status[6]}
timestamp=${status[7]}
diff=$(( $( date +%s%3N ) - timestamp ))
cat << EOF > $filestate
elapsed=$(( ( progress + 500 ) / 1000 ))
start=$(( ( timestamp + diff - progress + 500 ) / 1000 ))
state=$state
EOF

$dirbash/cmd-pushstatus.sh
