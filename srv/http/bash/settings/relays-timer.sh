#!/bin/bash

. /srv/http/bash/common.sh

timerfile=$dirshm/relaystimer
timer=$( < $timerfile )
i=$timer
while sleep 60; do
	playing=
	if  aplay -l | grep -q -m1 Loopback; then
		grep -q -m1 '^state.*play' $dirshm/status && playing=1
	elif grep -q -m1 RUNNING /proc/asound/card*/pcm*p/sub*/status; then # state: RUNNING
		playing=1
	fi
	if [[ $playing ]]; then
		[[ $i != $timer ]] && echo $timer > $timerfile
	else
		i=$( < $timerfile )
		(( $i == 1 )) && $dirsettings/relays.sh && exit
		
		(( i-- ))
		echo $i > $timerfile
		(( $i > 1 )) && continue
		
		pushstream relays '{"state":"IDLE","timer":'$timer'}'
	fi
done
