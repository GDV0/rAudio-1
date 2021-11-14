#!/bin/bash

. /srv/http/bash/common.sh

for pid in $( pgrep mpd ); do
	ionice -c 0 -n 0 -p $pid &> /dev/null 
	renice -n -19 -p $pid &> /dev/null
done

mpc idleloop | while read changed; do
	case $changed in
		mixer ) # for upmpdcli
			if [[ -e $dirshm/player-upnp ]]; then
				echo 5 > $dirshm/vol
				( for (( i=0; i < 5; i++ )); do
					sleep 0.1
					s=$(( $( cat $dirshm/vol ) - 1 )) # debounce volume long-press on client
					(( $s == 4 )) && i=0
					if (( $s > 0 )); then
						echo $s > $dirshm/vol
					else
						rm -f $dirshm/vol
						pushstream volume '{"val":'$( $dirbash/cmd.sh volumeget )'}'
					fi
				done ) &> /dev/null &
			fi
			;;
		playlist )
			if [[ $( mpc | awk '/^volume:.*consume:/ {print $NF}' ) == on || $pldiff > 0 ]]; then
				( sleep 0.05 # consume mode: playlist+player at once - run player fisrt
					pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
				) &> /dev/null &
			fi
			;;
		player )
			if [[ ! -e $dirshm/radio && ! -e $dirshm/prevnextseek ]]; then
				killall cmd-pushstatus.sh &> /dev/null
				$dirbash/cmd-pushstatus.sh
			fi
			;;
		update )
			sleep 1
			if [[ -e $dirsystem/updating ]] && ! mpc | grep -q '^Updating'; then
				if [[ -e $dirshm/updatingusb ]]; then
					rm $dirshm/updatingusb
					echo USB > $dirsystem/updating
					mpc update USB
				else
					$dirbash/cmd-list.sh
				fi
			fi
			;;
	esac
done
