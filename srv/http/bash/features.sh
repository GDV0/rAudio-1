#!/bin/bash

. /srv/http/bash/common.sh

# convert each line to each args
readarray -t args <<< "$1"

pushRefresh() {
	data=$( $dirbash/features-data.sh )
	pushstream refresh "$data"
}
pushRefreshNetworks() {
	data=$( $dirbash/networks-data.sh )
	pushstream refresh "$data"
}
featureSet() {
	systemctl restart $@
	systemctl -q is-active $@ && systemctl enable $@
	pushRefresh
}
localbrowserXset() {
	. $dirsystem/localbrowser.conf
	export DISPLAY=:0
	off=$(( $screenoff * 60 ))
	xset s off
	xset dpms $off $off $off
	if [[ $off == 0 ]]; then
		xset -dpms
	elif [[ -e $dirsystem/onwhileplay ]]; then
		grep -q '^state="play"' $dirshm/status && xset -dpms || xset +dpms
	else
		xset +dpms
	fi
}
spotifyReset() {
	pushstreamNotifyBlink 'Spotify Client' "$1" spotify
	rm -f $dirsystem/spotify $dirshm/spotify/*
	systemctl disable --now spotifyd
	pushRefresh
}

case ${args[0]} in

aplaydevices )
	aplay -L | grep -v '^\s\|^null' | head -c -1
	;;
autoplay|autoplaycd|lyricsembedded|streaming )
	feature=${args[0]}
	filefeature=$dirsystem/$feature
	[[ ${args[1]} == true ]] && touch $filefeature || rm -f $filefeature
	[[ $feature == streaming ]] && $dirbash/mpd-conf.sh
	pushRefresh
	;;
hostapddisable )
	systemctl disable --now hostapd
	ifconfig wlan0 0.0.0.0
	pushRefresh
	pushRefreshNetworks
	;;
hostapdget )
	hostapdip=$( awk -F',' '/router/ {print $2}' /etc/dnsmasq.conf )
	hostapdpwd=$( awk -F'=' '/^#*wpa_passphrase/ {print $2}' /etc/hostapd/hostapd.conf | sed 's/"/\\"/g' )
	echo '[ "'$hostapdip'","'$hostapdpwd'" ]'
	;;
hostapdset )
	if [[ ${#args[@]} > 1 ]]; then
		iprange=${args[1]}
		router=${args[2]}
		password=${args[3]}
		sed -i -e "s/^\(dhcp-range=\).*/\1$iprange/
" -e "s/^\(.*option:router,\).*/\1$router/
" -e "s/^\(.*option:dns-server,\).*/\1$router/
" /etc/dnsmasq.conf
		sed -i -e '/^#*wpa\|^#*rsn/ s/^#*//
' -e "s/\(wpa_passphrase=\).*/\1$password/
" /etc/hostapd/hostapd.conf
	else
		router=$( grep router /etc/dnsmasq.conf | cut -d, -f2 )
		sed -i -e '/^wpa\|^rsn/ s/^/#/' /etc/hostapd/hostapd.conf
	fi
	ifconfig wlan0 &> /dev/null || $dirbash/system.sh wlanset$'\n'true
	netctl stop-all
	ifconfig wlan0 $router
	featureSet hostapd
	pushRefreshNetworks
	;;
localbrowserdisable )
	ply-image /srv/http/assets/img/splash.png
	systemctl disable --now bootsplash localbrowser
	systemctl enable --now getty@tty1
	sed -i 's/\(console=\).*/\1tty1/' /boot/cmdline.txt
	rm -f $dirsystem/onwhileplay
	pushRefresh
	;;
localbrowserset )
	newrotate=${args[1]}
	newzoom=${args[2]}
	newcursor=${args[3]}
	newscreenoff=${args[4]}
	newonwhileplay=${args[5]}
	if [[ -e $dirsystem/localbrowser.conf ]]; then
		. $dirsystem/localbrowser.conf
		[[ $rotate != $newrotate ]] && changedrotate=1          # [reboot] / [restart]
		[[ $zoom != $newzoom ]] && restart=1                    # [restart]
		[[ $cursor != $newcursor ]] && restart=1                # [restart]
		[[ $screenoff != $newscreenoff ]] && changedscreenoff=1 # xset dpms
		# onwhileplay                                           # flag file
	fi
	[[ $newonwhileplay == true ]] && touch $dirsystem/onwhileplay || rm -f $dirsystem/onwhileplay
	echo -n "\
rotate=$newrotate
zoom=$newzoom
screenoff=$newscreenoff
onwhileplay=$newonwhileplay
cursor=$newcursor
" > $dirsystem/localbrowser.conf
	if ! grep -q console=tty3 /boot/cmdline.txt; then
		sed -i 's/\(console=\).*/\1tty3 quiet loglevel=0 logo.nologo vt.global_cursor_default=0/' /boot/cmdline.txt
		systemctl disable --now getty@tty1
	fi

	if [[ $changedrotate ]]; then
		$dirbash/cmd.sh rotateSplash$'\n'$newrotate # after set new data in conf file
		if grep -q 'waveshare\|tft35a' /boot/config.txt; then
			case $newrotate in
				NORMAL ) degree=0;;
				CCW )    degree=270;;
				CW )     degree=90;;
				UD )     degree=180;;
			esac
			sed -i "/waveshare\|tft35a/ s/\(rotate=\).*/\1$degree/" /boot/config.txt
			cp -f /etc/X11/{lcd$degree,xorg.conf.d/99-calibration.conf}
			pushRefresh
			echo Rotate GPIO LCD screen >> $dirshm/reboot
			data='{"title":"Rotate GPIO LCD screen","text":"Reboot needed.","icon":"chromium","hold":5000}'
			pushstream notify "$data"
			exit
		fi
		
		restart=1
		rotateconf=/etc/X11/xorg.conf.d/99-raspi-rotate.conf
		case $newrotate in
			NORMAL ) rm -f $rotateconf;;
			CW )  matrix='0 1 0 -1 0 1 0 0 1';;
			CCW ) matrix='0 -1 1 1 0 0 0 0 1';;
			UD )  matrix='-1 0 1 0 -1 1 0 0 1';;
		esac
		[[ matrix ]] && sed "s/ROTATION_SETTING/$newrotate/; s/MATRIX_SETTING/$matrix/" /etc/X11/xinit/rotateconf > $rotateconf
	fi
	if [[ $restart ]] || ! systemctl -q is-active localbrowser; then
		systemctl restart bootsplash localbrowser
		systemctl -q is-active localbrowser && systemctl enable bootsplash localbrowser
	elif [[ $changedscreenoff ]]; then
		localbrowserXset $newscreenoff
		if [[ $screenoff == 0 || $newscreenoff == 0 ]]; then
			[[ $off == 0 ]] && tf=false || tf=true
			pushstream display '{"submenu":"screenoff","value":'$tf'}'
		fi
	fi
	pushRefresh
	;;
localbrowserxset )
	localbrowserXset ${args[1]}
	;;
logindisable )
	rm -f $dirsystem/login*
	sed -i '/^bind_to_address/ s/".*"/"0.0.0.0"/' /etc/mpd.conf
	systemctl restart mpd
	pushRefresh
	pushstream display '{"submenu":"lock","value":false}'
	;;
loginset )
	touch $dirsystem/login
	sed -i '/^bind_to_address/ s/".*"/"127.0.0.1"/' /etc/mpd.conf
	systemctl restart mpd
	pushRefresh
	pushstream display '{"submenu":"lock","value":true}'
	;;
screenofftoggle )
#	[[ $( /opt/vc/bin/vcgencmd display_power ) == display_power=1 ]] && toggle=0 || toggle=1
#	/opt/vc/bin/vcgencmd display_power $toggle # hdmi
	export DISPLAY=:0
	xset q | grep -q 'Monitor is Off' && xset dpms force on || xset dpms force off
	;;
scrobbledisable )
	rm -f $dirsystem/scrobble
	pushRefresh
	;;
scrobbleset )
	conf=( ${args[@]:1:5} )
	username=${args[6]}
	password=${args[7]}
	dirscrobble=$dirsystem/scrobble.conf
	mkdir -p $dirscrobble
	keys=( airplay bluetooth spotify upnp notify )
	for(( i=0; i < 5; i++ )); do
		fileconf=$dirscrobble/${keys[ i ]}
		[[ ${conf[ i ]} == true ]] && touch $fileconf || rm -f $fileconf
	done
	if [[ ! $password ]]; then
		if [[ -e $dirscrobble/key && $username == $( cat $dirscrobble/user ) ]]; then
			touch $dirsystem/scrobble
			pushRefresh
		fi
		exit
	fi
	
	keys=( $( grep 'apikeylastfm\|sharedsecret' /srv/http/assets/js/main.js | cut -d"'" -f2 ) )
	apikey=${keys[0]}
	sharedsecret=${keys[1]}
	apisig=$( echo -n "api_key${apikey}methodauth.getMobileSessionpassword${password}username${username}$sharedsecret" \
				| iconv -t utf8 \
				| md5sum \
				| cut -c1-32 )
	reponse=$( curl -sX POST \
		--data "api_key=$apikey" \
		--data "method=auth.getMobileSession" \
		--data-urlencode "password=$password" \
		--data-urlencode "username=$username" \
		--data "api_sig=$apisig" \
		--data "format=json" \
		http://ws.audioscrobbler.com/2.0 )
	[[ $reponse =~ error ]] && echo $reponse && exit
	
	echo $username > $dirscrobble/user
	echo $reponse | sed 's/.*key":"//; s/".*//' > $dirscrobble/key
	touch touch $dirsystem/scrobble
	pushRefresh
	;;
shairport-sync | spotifyd | upmpdcli )
	service=${args[0]}
	enable=${args[1]}
	if [[ $enable == true ]]; then
		systemctl enable --now $service
	else
		systemctl disable --now $service
	fi
	pushRefresh
	if [[ $service == shairport-sync ]]; then
		for pid in $( pgrep shairport-sync ); do
			ionice -c 0 -n 0 -p $pid &> /dev/null 
			renice -n -19 -p $pid &> /dev/null
		done
	fi
	;;
smbdisable )
	systemctl disable --now smb
	pushRefresh
	;;
smbset )
	smbconf=/etc/samba/smb.conf
	sed -i '/read only = no/ d' $smbconf
	[[ ${args[1]} == true ]] && sed -i '/path = .*SD/ a\	read only = no' $smbconf
	[[ ${args[2]} == true ]] && sed -i '/path = .*USB/ a\	read only = no' $smbconf
	featureSet smb
	;;
snapclientdisable )
	rm $dirsystem/snapclient
	pushRefresh
	pushstream display '{"submenu":"sanpclient","value":false}'
	;;
snapclientset )
	latency=${args[1]}
	sed -i '/OPTS=/ s/".*"/"--latency='$latency'"/' /etc/default/snapclient
	touch $dirsystem/snapclient
	systemctl try-restart snapclient
	pushRefresh
	pushstream display '{"submenu":"sanpclient","value":true}'
	;;
snapserver )
	if [[ ${args[1]} == true ]]; then
		systemctl enable --now snapserver
	else
		systemctl disable --now snapserver
	fi
	$dirbash/mpd-conf.sh
	pushRefresh
	;;
spotifyddisable )
	systemctl disable --now spotifyd
	pushRefresh
	;;
spotifytoken )
	code=${args[1]}
	[[ ! $code ]] && rm -f $dirsystem/spotify && exit
	
	. $dirsystem/spotify
	spotifyredirect=$( grep ^spotifyredirect $dirbash/features-data.sh | cut -d= -f2 )
	tokens=$( curl -X POST https://accounts.spotify.com/api/token \
				-H "Authorization: Basic $base64client" \
				-H 'Content-Type: application/x-www-form-urlencoded' \
				-d "code=$code" \
				-d grant_type=authorization_code \
				--data-urlencode "redirect_uri=https://rern.github.io/raudio/spotify" )
	if grep -q error <<< "$tokens"; then
		spotifyReset "Error: $( echo $token | jq -r .error )"
		exit
	fi
	
	tokens=( $( echo $tokens | jq -r .refresh_token,.access_token ) )
	echo "refreshtoken=${tokens[0]}" >> $dirsystem/spotify
	echo ${tokens[1]} > $dirshm/spotify/token
	echo $(( $( date +%s ) + 3550 )) > $dirshm/spotify/expire
	featureSet spotifyd
	;;
spotifytokenreset )
	spotifyReset 'Reset ...'
	;;
stoptimerdisable )
	killall stoptimer.sh &> /dev/null
	rm -f $dirshm/stoptimer
	pushRefresh
	;;
stoptimerset )
	min=${args[1]}
	poweroff=${args[2]}
	[[ $poweroff == true ]] && off=poweroff
	kill -9 $( pgrep stoptimer ) &> /dev/null
	rm -f $dirshm/stoptimer
	if [[ $min != false ]]; then
		$dirbash/stoptimer.sh $min $off &> /dev/null &
		echo "[ $min, $poweroff ]" > $dirshm/stoptimer
	fi
	pushRefresh
	;;
upmpdclidisable )
	systemctl disable --now upmpdcli
	pushRefresh
	;;
upmpdcliset )
	[[ ${args[1]} == true ]] && val=1 || val=0
	sed -i "s/\(ownqueue = \)./\1$val/" /etc/upmpdcli.conf
	featureSet upmpdcli
	;;
	
esac
