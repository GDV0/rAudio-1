#!/bin/bash

. /srv/http/bash/common.sh
dirimg=/srv/http/assets/img

# convert each line to each args
readarray -t args <<< "$1"

addonsListGet() {
	: >/dev/tcp/8.8.8.8/53 || exit -2 # online check
	
	[[ -z $1 ]] && branch=main || branch=$1
	curl -skL https://github.com/rern/rAudio-addons/raw/$branch/addons-list.json -o $diraddons/addons-list.json || exit -1
}
equalizerGet() {
	val=$( sudo -u mpd amixer -D equal contents | awk -F ',' '/: value/ {print $NF}' | xargs )
	filepresets=$dirsystem/equalizer.presets
	[[ -e $dirshm/btclient ]] && filepresets+="-$( cat $dirshm/btclient )"
	[[ ! -e $filepresets ]] && echo Flat > "$filepresets"
	
	[[ $2 == set ]] && sed -i "1 s/.*/(unnamed)/" "$filepresets"
	current=$( head -1 "$filepresets" )
	[[ $current != '(unnamed)' ]] && presets+='"Flat"' || presets+='"(unnamed)","Flat"'
	readarray -t lines <<< $( sed 1d "$filepresets" | grep -v '^Flat$' | cut -d^ -f1 | sort )
	if [[ $lines ]]; then
		for line in "${lines[@]}"; do
			presets+=',"'$line'"'
		done
	fi
	data='{
  "current" : "'$current'"
, "values"  : [ '${val// /,}' ]
, "presets" : [ '$presets' ]
}'
	[[ $1 == pushstream ]] && pushstream equalizer "$data" || echo $data
}
gifNotify() {
	pushstreamNotifyBlink Thumbnail 'Resize animated GIF ...' coverart
}
gifThumbnail() {
	args="$1"
	type=${args[0]}
	source=${args[1]}
	target=${args[2]}
	covername=${args[3]}
	imgwh=( $( gifsicle -I "$source" | awk 'NR < 3 {print $NF}' ) )
	[[ ${imgwh[0]} == images ]] && animated=1
	case $type in
		bookmark )
			rm -f "${target:0:-4}".*
			[[ $animated ]] && (( ${imgwh[1]/x*} > 200 || ${imgwh[1]/*x} > 200 )) && gifNotify
			gifsicle -O3 --resize-fit 200x200 "$source" > "$target"
			;;
		coverart )
			dir=$( dirname "$target" )
			rm -f "$dir/cover".*.backup "$dir/coverart".* "$dir/thumb".*
			coverfile=$( ls -1 "$dir/cover".* 2> /dev/null | head -1 )
			[[ -e $coverfile ]] && mv -f "$coverfile" "$coverfile.backup"
			[[ ! -e "$target" ]] && pushstreamNotify ${type^} 'No write permission.' warning && exit
			
			[[ $animated ]] && gifNotify
			gifsicle -O3 --resize-fit 1000x1000 "$source" > "$target"
			gifsicle -O3 --resize-fit 200x200 "$source" > "$dir/coverart.gif"
			gifsicle -O3 --resize-fit 80x80 "$source" > "$dir/thumb.gif"
			rm -f /srv/http/data/shm/embedded/$covername.* /srv/http/data/shm/local/$covername.*
			;;
		webradio )
			filenoext=${target:0:-4}
			rm -f $filenoext.* $filenoext-thumb.*
			[[ $animated ]] && gifNotify
			gifsicle -O3 --resize-fit 200x200 $source > $target
			gifsicle -O3 --resize-fit 80x80 $source > $filenoext-thumb.gif
			;;
	esac
	pushstreamThumb gif $type
}
jpgThumbnail() {
	args="$1"
	type=${args[0]}
	source=${args[1]}
	target=${args[2]}
	covername=${args[3]}
	case $type in
		bookmark )
			rm -f "${target:0:-4}".*
			cp -f "$source" "$target"
			;;
		coverart )
			dir=$( dirname "$target" )
			rm -f "$dir/cover".*.backup "$dir/coverart".* "$dir/thumb".*
			coverfile=$( ls -1 "$dir/cover".* 2> /dev/null | head -1 )
			[[ -e $coverfile ]] && mv -f "$coverfile" "$coverfile.backup"
			cp -f "$source" "$target/cover.jpg" # already resized from client
			[[ ! -e "$target" ]] && pushstreamNotify ${type^} 'No write permission.' warning && exit
			
			convert "$source" -thumbnail 200x200\> -unsharp 0x.5 "$dir/coverart.jpg"
			convert "$dir/coverart.jpg" -thumbnail 80x80\> -unsharp 0x.5 "$dir/thumb.jpg"
			rm -f /srv/http/data/shm/embedded/$covername.* /srv/http/data/shm/local/$covername.*
			;;
		webradio )
			filenoext=${target:0:-4}
			rm -f $filenoext.* $filenoext-thumb.*
			cp -f $source $target
			convert $source -thumbnail 80x80\> -unsharp 0x.5 $filenoext-thumb.jpg
			;;
	esac
	pushstreamThumb jpg $type
}
mpdoledLogo() {
	systemctl stop mpd_oled
	type=$( grep mpd_oled /etc/systemd/system/mpd_oled.service | cut -d' ' -f3 )
	mpd_oled -o $type -L
}
pladdPlay() {
	pushstreamPlaylist
	if [[ ${1: -4} == play ]]; then
		sleep $2
		mpc -q play $pos
		$dirbash/status-push.sh
	fi
}
pladdPosition() {
	if [[ ${1:0:7} == replace ]]; then
		mpc -q clear
		pos=1
	else
		pos=$(( $( mpc playlist | wc -l ) + 1 ))
	fi
}
pushstreamPlaylist() {
	pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
}
pushstreamThumb() {
	coverfile=${target:0:-4}
	coverfile=$( php -r "echo rawurlencode( '${coverfile//\'/\\\'}' );" )
	pushstream coverart '{"url":"'$coverfile.$( date +%s ).$1'","type":"'$2'"}'
}
pushstreamVolume() {
	pushstream volume '{"type":"'$1'", "val":'$2' }'
}
rotateSplash() {
	case $1 in
		NORMAL ) degree=0;;
		CCW )    degree=-90;;
		CW )     degree=90;;
		UD )     degree=180;;
	esac
	convert \
		-density 48 \
		-background none $dirimg/icon.svg \
		-rotate $degree \
		-gravity center \
		-background '#000' \
		-extent 1920x1080 \
		$dirimg/splash.png
}
scrobbleOnStop() {
	. $dirshm/scrobble
	elapsed=$1
	if (( $Time > 30 && ( $elapsed > 240 || $elapsed > $Time / 2 ) )) && [[ $Artist && $Title ]]; then
		$dirbash/scrobble.sh "\
$Artist
$Title
$Album" &> /dev/null &
	fi
	rm -f $dirshm/scrobble
}
urldecode() { # for webradio url to filename
	: "${*//+/ }"
	echo -e "${_//%/\\x}"
}
volume0dB(){
	volumeGet
	amixer -c $card -Mq sset "$control" 0dB
}
volumeControls() {
	! aplay -l 2> /dev/null | grep -q '^card' && return
	
	amixer=$( amixer -c $1 scontents \
				| grep -A1 ^Simple \
				| sed 's/^\s*Cap.*: /^/' \
				| tr -d '\n' \
				| sed 's/--/\n/g' )
	[[ -z $amixer ]] && control= && return
	
	controls=$( echo "$amixer" \
					| grep 'volume.*pswitch' \
					| grep -v Mic \
					| cut -d"'" -f2 )
	if [[ -z $controls ]]; then
		controls=$( echo "$amixer" \
						| grep volume \
						| grep -v Mic \
						| cut -d"'" -f2  )
	fi
}
volumeGet() {
	if [[ -e $dirshm/btclient ]]; then
		volume=$( mpc volume | cut -d: -f2 | tr -d ' %n/a' )
		return
	fi
	
	if ! aplay -l 2> /dev/null | grep -q '^card'; then
		volume=-1
		return
	fi
	
	mixertype=$( sed -n '/soxr/,/mixer_type/ p' /etc/mpd.conf \
					| tail -1 \
					| cut -d'"' -f2 )
	if [[ $mixertype == software ]]; then
		volume=$( mpc volume | cut -d: -f2 | tr -d ' %n/a' )
	else
		card=$( head -1 /etc/asound.conf | tail -c 2 )
		volumeControls $card
		if [[ -z $controls ]]; then
			volume=100
		else
			control=$( echo "$controls" | sort -u | head -1 )
			voldb=$( amixer -M sget "$control" \
				| grep -m1 '%.*dB' \
				| sed 's/.*\[\(.*\)%\] \[\(.*\)dB.*/\1 \2/' )
			if [[ $voldb ]]; then
				volume=${voldb/ *}
				db=${voldb/* }
			else
				volume=100
			fi
			echo $volume > $dirshm/mpdvolume
		fi
	fi
}
volumeReset() {
	file=$dirshm/mpdvolume
	if [[ -e $file ]]; then
		volumeGet
		vol_db=( $( cat $file ) )
		vol=${vol_db[0]}
		db=${vol_db[1]}
		volumeSet $volume $vol "$control"
		[[ $db == 0.00 ]] && amixer -c $card -Mq sset "$control" 0dB
		rm -f $file
	fi
}
volumeSetAt() {
	val=$1
	if [[ -z $control ]]; then
		mpc -q volume $val
	else
		amixer -Mq sset "$control" $val%
	fi
}
volumeSet() {
	current=$1
	target=$2
	control=$3
	diff=$(( $target - $current ))
	pushstreamVolume disable true
	if (( -5 < $diff && $diff < 5 )); then
		volumeSetAt $target
	else # increment
		(( $diff > 0 )) && incr=5 || incr=-5
		for i in $( seq $current $incr $target ); do
			volumeSetAt $i
			sleep 0.2
		done
		if (( $i != $target )); then
			volumeSetAt $target
		fi
	fi
	pushstreamVolume disable false
	[[ $control && ! -e $dirshm/btclient ]] && alsactl store
}

case ${args[0]} in

addonsclose )
	script=${args[1]}
	alias=${args[2]}
	killall $script curl pacman &> /dev/null
	rm -f /var/lib/pacman/db.lck /srv/http/*.zip $diraddons/$alias /usr/local/bin/uninstall_$alias.sh
	;;
addonslist )
	addonsListGet ${args[1]}
	
	bash=$( jq -r .push.bash $diraddons/addons-list.json ) # push bash
	if [[ $bash ]]; then
		eval "$bash" || exit
	fi
	
	url=$( jq -r .push.url $diraddons/addons-list.json ) # push download
	[[ $url ]] && bash <( curl -sL $url )
	;;
addonsupdates )
	addonsListGet

	installed=$( ls "$diraddons" | grep -v addons-list )
	for addon in $installed; do
		verinstalled=$( cat $diraddons/$addon )
		if (( ${#verinstalled} > 1 )); then
			verlist=$( jq -r .$addon.version $diraddons/addons-list.json )
			[[ $verinstalled != $verlist ]] && count=1 && break
		fi
	done
	[[ $count ]] && touch $diraddons/update || rm -f $diraddons/update
	;;
albumignore )
	album=${args[1]}
	artist=${args[2]}
	sed -i "/\^$album^^$artist^/ d" $dirdata/mpd/album
	sed -i "/\^$artist^^$album^/ d" $dirdata/mpd/albumbyartist
	echo $album^^$artist >> $dirdata/mpd/albumignore
	;;
audiocdtag )
	track=${args[1]}
	tag=${args[2]}
	discid=${args[3]}
	sed -i "$track s|.*|$tag|" $dirdata/audiocd/$discid
	pushstreamPlaylist
	;;
bookmarkreset )
	imagepath=${args[1]}
	name=${args[2]}
	sed -i '2d' "$dirdata/bookmarks/$name"
	rm -f "$imagepath/coverart".*
	data='{"url":"'$imagepath/none'","type":"bookmark"}'
	pushstream coverart "$data"
	;;
bookmarkthumb )
	mpdpath=${args[1]}
	coverartfile=$( ls "/mnt/MPD/$mpdpath/coverart".* )
	echo ${coverartfile: -3} # ext
	;;
color )
	hsl=${args[1]}
	file=$dirsystem/color
	if [[ $hsl ]]; then # omit call from addons.sh / datarestore
		[[ $hsl == reset ]] && rm -f $file || echo $hsl > $file
	fi
	if [[ -e $file ]]; then
		hsl=( $( cat $file ) )
	else
		hsl=( $( grep '\-\-cd *:' /srv/http/assets/css/colors.css | sed 's/.*(\(.*\)).*/\1/' | tr ',' ' ' | tr -d % ) )
	fi
	h=${hsl[0]}; s=${hsl[1]}; l=${hsl[2]}
	hs="$h,$s%,"
	hsg="$h,3%,"
	hsl="${hs}$l%"

	sed -i "
 s|\(--cml *: *hsl\).*;|\1(${hs}$(( l + 5 ))%);|
  s|\(--cm *: *hsl\).*;|\1($hsl);|
 s|\(--cma *: *hsl\).*;|\1(${hs}$(( l - 5 ))%);|
 s|\(--cmd *: *hsl\).*;|\1(${hs}$(( l - 15 ))%);|
s|\(--cg75 *: *hsl\).*;|\1(${hsg}75%);|
s|\(--cg60 *: *hsl\).*;|\1(${hsg}60%);|
 s|\(--cgl *: *hsl\).*;|\1(${hsg}40%);|
  s|\(--cg *: *hsl\).*;|\1(${hsg}30%);|
 s|\(--cga *: *hsl\).*;|\1(${hsg}20%);|
 s|\(--cgd *: *hsl\).*;|\1(${hsg}10%);|
" /srv/http/assets/css/colors.css
	sed -i "
 s|\(.box{fill:hsl\).*|\1($hsl);|
s|\(.text{fill:hsl\).*|\1(${hsg}30%);}|
" $dirimg/coverart.svg
	sed -i "
s|\(.box{fill:hsl\).*|\1($hsl);}|
s|\(path{fill:hsl\).*|\1(${hsg}75%);}|
" $dirimg/icon.svg
	sed "s|\(path{fill:hsl\).*|\1(0,0%,90%);}|" $dirimg/icon.svg \
		| convert -density 96 -background none - $dirimg/icon.png
	rotate=$( grep ^rotate /etc/localbrowser.conf 2> /dev/null | cut -d= -f2 )
	[[ -z $rotate ]] && rotate=NORMAL
	rotateSplash $rotate
	pushstream reload 1
	;;
count )
	count
	;;
coverartget )
	path=${args[1]}
	coverartfile=$( ls -1X "$path"/coverart.* 2> /dev/null \
						| grep -i '.gif$\|.jpg$\|.png$' \
						| head -1 ) # full path
	if [[ $coverartfile ]]; then
		echo $coverartfile | sed 's|^/srv/http||'
		exit
	fi
	
	[[ ${path:0:4} == /srv ]] && exit
	
	coverfile=$( ls -1X "$path" \
					| grep -i '^cover\.\|^folder\.\|^front\.\|^album\.' \
					| grep -i '.gif$\|.jpg$\|.png$' \
					| head -1 ) # filename only
	if [[ $coverfile ]]; then
		ext=${coverfile: -3}
		coverartfile="$path/coverart.${ext,,}"
		cp "$path/$coverfile" "$coverartfile" 2> /dev/null
		[[ -e $coverartfile ]] && echo $coverartfile
	fi
	;;
coverartreset )
	coverfile=${args[1]}
	mpdpath=${args[2]}
	artist=${args[3]}
	album=${args[4]}
	dir=$( dirname "$coverfile" )
	if [[ $( basename "$dir" ) == audiocd ]]; then
		filename=$( basename "$coverfile" )
		id=${filename/.*}
		rm -f "$coverfile"
		$dirbash/status-coverartonline.sh "\
$artist
$album
audiocd
$id" &> /dev/null &
		exit
	fi
	
	covername=$( echo $artist$album | tr -d ' "`?/#&'"'" )
	rm -f "$coverfile" \
		"$dir/coverart".* \
		"$dir/thumb".* \
		$dirshm/local/$covername \
		$dirdata/embedded/$covername*
	backupfile=$( ls -p "$dir"/*.backup | head -1 )
	if [[ -e $backupfile ]]; then
		restorefile=${backupfile%%.backup}
		ext=${restorefile: -3}
		if [[ $ext != gif ]]; then
			jpgThumbnail coverart "$backupfile" "$restorefile"
		else
			gifThumbnail coverart "$backupfile" "$restorefile"
		fi
		rm "$backupfile"
	fi
	url=$( $dirbash/status-coverart.sh "\
$artist
$album
$mpdpath" )
	[[ -z $url ]] && url=/mnt/MPD/$mpdpath/none
	data='{"url":"'$url'","type":"coverart"}'
	pushstream coverart "$data"
	;;
coverfileslimit )
	for type in local online webradio; do
		files=$( ls -1t $dirshm/$type )
		(( $( echo "$files" | wc -l ) > 10 )) && rm -f "$( echo "$files" | tail -1 )"
	done
	;;
coversave )
	source=${args[1]}
	path=${args[2]}
	covername=${args[3]}
	coverfile="$path/cover.jpg"
	jpgThumbnail coverart "$source" "$coverfile"
	rm -f $dirshm/local/$covername*
	;;
displayget )
	if [[ -e $dirshm/nosound ]]; then
		volumenone=true
	else
		card=$( head -1 /etc/asound.conf | cut -d' ' -f2 )
		volumenone=$( sed -n "/^\s*device.*hw:$card/,/mixer_type/ p" /etc/mpd.conf \
					| grep -q 'mixer_type.*none' \
					&& echo true || echo false )
	fi
	data=$( head -n -1 $dirsystem/display )
	data+='
, "audiocd"    : '$( grep -q 'plugin.*cdio_paranoia' /etc/mpd.conf && echo true || echo false )'
, "color"      : "'$( cat $dirsystem/color 2> /dev/null )'"
, "equalizer"  : '$( [[ -e $dirsystem/equalizer ]] && echo true || echo false )'
, "lock"       : '$( [[ -e $dirsystem/login ]] && echo true || echo false )'
, "order"      : '$( cat $dirsystem/order 2> /dev/null || echo false )'
, "relays"     : '$( [[ -e $dirsystem/relays ]] && echo true || echo false )'
, "screenoff"  : '$( grep -q screenoff=0 $dirsystem/localbrowser.conf && echo false || echo true )'
, "snapclient" : '$( [[ -e $dirsystem/snapclient ]] && echo true || echo false )'
, "volumenone" : '$volumenone'
}'
	echo "$data"
	;;
displaysave )
	data=${args[1]}
	pushstream display "$data"
	jq <<< $data > $dirsystem/display
	grep -q '"vumeter".*true' $dirsystem/display && vumeter=1
	[[ -e $dirsystem/vumeter ]] && prevvumeter=1
	[[ $prevvumeter == $vumeter ]] && exit
	
	if [[ $vumeter ]]; then
		mpc | grep -q '\[playing' && cava -p /etc/cava.conf | $dirbash/vu.sh &> /dev/null &
		touch $dirsystem/vumeter
	else
		killall cava &> /dev/null
		rm -f $dirsystem/vumeter
		pushstreamNotifyBlink 'Playback' 'VU meter disable...' 'playback'
	fi
	$dirbash/mpd-conf.sh
	status=$( $dirbash/status.sh )
	pushstream mpdplayer "$status"
	;;
equalizer )
	type=${args[1]} # preset, delete, rename, new, save
	name=${args[2]}
	newname=${args[3]}
	flat='61 61 61 61 61 61 61 61 61 61' # value 60 > set at 59
	filepresets=$dirsystem/equalizer.presets
	[[ -e $dirshm/btclient ]] && filepresets+="-$( cat $dirshm/btclient )"
	if [[ $type == preset ]]; then
		[[ $name == Flat ]] && v=( $flat ) || v=( $( grep "^$name\^" "$filepresets" | cut -d^ -f2- ) )
	else # remove then save again with current values
		append=1
		sed -i "/^$name\^/ d" "$filepresets" 2> /dev/null
		if [[ $type == delete ]]; then
			v=( $flat )
			name=Flat
		elif [[ $type == rename ]]; then
			name=$newname
		fi
	fi
	sed -i "1 s/.*/$name/" "$filepresets"
	if [[ $type == preset || $type == delete ]]; then
		freq=( 31 63 125 250 500 1 2 4 8 16 )
		for (( i=0; i < 10; i++ )); do
			(( i < 5 )) && unit=Hz || unit=kHz
			band=( "0$i. ${freq[i]} $unit" )
			sudo -u mpd amixer -MqD equal sset "$band" ${v[i]}
		done
	fi
	val=$( sudo -u mpd amixer -D equal contents | awk -F ',' '/: value/ {print $NF}' | xargs )
	[[ $append && $name != Flat ]] && echo $name^$val >> "$filepresets"
	[[ $type != save ]] && equalizerGet pushstream
	;;
equalizerget )
	equalizerGet ${args[1]} ${args[2]}
	;;
equalizerupdn )
	band=${args[1]}
	val=${args[2]}
	sudo -u mpd amixer -D equal sset "$band" $val
	;;
hashFiles )
	path=/srv/http/assets
	for dir in css fonts js; do
		[[ $dir == js ]] && d=d
		files+=$( ls -p$d "$path/$dir/"* | grep -v '/$' )$'\n'
	done
	date=$( date +%s )
	for file in ${files[@]}; do
		mv $file ${file/.*}.$date.${file/*.}
		pages=$( grep -rl "assets/js" /srv | grep 'php$' )
		for page in ${pages[@]}; do
			name=$( basename $file )
			newname=${name/.*}.$date.${name/*.}
			sed -i "s|$name|$newname|" $page
		done
	done
	;;
ignoredir )
	touch $dirsystem/updating
	path=${args[1]}
	dir=$( basename "$path" )
	mpdpath=$( dirname "$path" )
	echo $dir >> "/mnt/MPD/$mpdpath/.mpdignore"
	pushstream mpdupdate 1
	mpc -q update "$mpdpath" #1 get .mpdignore into database
	mpc -q update "$mpdpath" #2 after .mpdignore was in database
	;;
lcdcharrefresh )
	kill -9 $( pgrep lcdchar ) &> /dev/null
	readarray -t data <<< $( $dirbash/status.sh \
								| jq -r '.Artist, .Title, .Album, .station, .file, .state, .Time, .elapsed, .timestamp, .webradio' \
								| sed 's/null//' )
	$dirbash/lcdchar.py "${data[@]}" &
	;;
librandom )
	enable=${args[1]}
	if [[ $enable == false ]]; then
		rm -f $dirsystem/librandom
	else
		mpc -q random 0
		plL=$( mpc playlist | wc -l )
		$dirbash/cmd-librandom.sh start
		touch $dirsystem/librandom
		sleep 1
		mpc -q play $(( plL + 1 ))
	fi
	pushstream option '{ "librandom": '$enable' }'
	pushstream playlist "$( php /srv/http/mpdplaylist.php current )"
	;;
list )
	list
	;;
lyrics )
	artist=${args[1]}
	title=${args[2]}
	cmd=${args[3]}
	data=${args[4]}
	name="$artist - $title"
	name=${name//\/}
	lyricsfile="$dirdata/lyrics/${name,,}.txt"
	if [[ $cmd == save ]]; then
		echo -e "$data" > "$lyricsfile"
	elif [[ $cmd == delete ]]; then
		rm -f "$lyricsfile"
	elif [[ -e "$lyricsfile" ]]; then
		cat "$lyricsfile"
	else
		if [[ -e $dirsystem/lyricsembedded ]]; then
			file=$cmd
			lyrics=$( kid3-cli -c "select \"$file\"" -c "get lyrics" )
			[[ $lyrics ]] && echo "$lyrics" && exit
		fi
		
		artist=$( echo $artist | sed 's/^A \|^The \|\///g' )
		title=${title//\/}
		query=$( echo $artist/$title \
					| tr -d " '\-\"\!*\(\);:@&=+$,?#[]." )
		lyrics=$( curl -s -A firefox https://www.azlyrics.com/lyrics/${query,,}.html )
		if [[ $lyrics ]]; then
			echo "$lyrics" \
				| sed -n '/id="cf_text_top"/,/id="azmxmbanner"/ p' \
				| sed -e '/^\s*$/ d' -e '/\/div>/,/<br>/ {N;d}' -e 's/<br>//' -e 's/&quot;/"/g' \
				| grep -v '^<' \
				| tee "$lyricsfile"
		fi
	fi
	;;
mpcoption )
	option=${args[1]}
	onoff=${args[2]}
	mpc -q $option $onoff
	pushstream option '{"'$option'":'$onoff'}'
	;;
mpcplayback )
	command=${args[1]}
	pos=${args[2]} # if stop = elapsed
	systemctl stop radio
	if [[ $command == play ]]; then
		mpc | grep -q '^\[paused\]' && pause=1
		mpc -q $command $pos
		[[ $( mpc | head -c 4 ) == cdda && -z $pause ]] && pushstreamNotifyBlink 'Audio CD' 'Start play ...' audiocd
	else
		[[ -e $dirsystem/scrobble && $command == stop && $pos ]] && cp -f $dirshm/{status,scrobble}
		mpc -q $command
		killall cava &> /dev/null
		[[ -e $dirshm/scrobble ]] && scrobbleOnStop $pos
	fi
	;;
mpcprevnext )
	command=${args[1]}
	current=$(( ${args[2]} + 1 ))
	length=${args[3]}
	state=${args[4]}
	elapsed=${args[5]}
	[[ -e $dirsystem/scrobble && $elapsed ]] && cp -f $dirshm/{status,scrobble}
	touch $dirshm/prevnextseek
	systemctl stop radio
	if [[ $state == play ]]; then
		mpc -q stop
		rm -f $dirshm/prevnextseek
	fi
	if mpc | grep -q 'random: on'; then
		pos=$( shuf -n 1 <( seq $length | grep -v $current ) )
		mpc -q play $pos
	else
		if [[ $command == next ]]; then
			(( $current != $length )) && mpc -q play $(( current + 1 )) || mpc -q play 1
			mpc | grep -q 'consume: on' && mpc -q del $current
			[[ -e $dirsystem/librandom ]] && $dirbash/cmd-librandom.sh
		else
			(( $current != 1 )) && mpc -q play $(( current - 1 )) || mpc -q play $length
		fi
	fi
	if [[ $state == play ]]; then
		[[ $( mpc | head -c 4 ) == cdda ]] && pushstreamNotifyBlink 'Audio CD' 'Change track ...' audiocd
	else
		rm -f $dirshm/prevnextseek
		mpc -q stop
	fi
	if [[ -e $dirshm/scrobble ]]; then
		sleep 2
		scrobbleOnStop $elapsed
	fi
	;;
mpcseek )
	seek=${args[1]}
	state=${args[2]}
	touch $dirshm/scrobble
	if [[ $state == stop ]]; then
		touch $dirshm/prevnextseek
		mpc -q play
		mpc -q pause
		rm $dirshm/prevnextseek
	fi
	mpc -q seek $seek
	rm -f $dirshm/scrobble
	;;
mpcupdate )
	path=${args[1]}
	if [[ $path == rescan ]]; then
		echo rescan > $dirsystem/updating
		mpc -q rescan
	else
		echo $path > $dirsystem/updating
		mpc -q update "$path"
	fi
	pushstream mpdupdate 1
	;;
mpdoledlogo )
	mpdoledLogo
	;;
nicespotify )
	for pid in $( pgrep spotifyd ); do
		ionice -c 0 -n 0 -p $pid &> /dev/null 
		renice -n -19 -p $pid &> /dev/null
	done
	;;
ordersave )
	data=$( jq <<< ${args[1]} )
	pushstream order "$data"
	echo "$data" > $dirsystem/order
	;;
partexpand )
	dev=$( mount | awk '/ on \/ / {printf $1}' | head -c -2 )
	if (( $( sfdisk -F $dev | head -1 | awk '{print $6}' ) != 0 )); then
		echo -e "d\n\nn\n\n\n\n\nw" | fdisk $dev &>/dev/null
		partprobe $dev
		resize2fs ${dev}p2
	fi
	;;
pkgstatus )
	id=${args[1]}
	pkg=$id
	case $id in
		hostapd )
			conf=/etc/hostapd/hostapd.conf;;
		localbrowser )
			conf=/srv/http/data/system/localbrowser.conf
			pkg=chromium;;
		snapclient|snapserver )
			conf=/etc/default/$id
			pkg=snapcast;;
		smb )
			conf=/etc/samba/smb.conf
			pkg=samba;;
		* )
			conf=/etc/$id.conf;;
	esac
	status="\
$( systemctl status $id \
	| sed '1 s|^.* \(.*service\)|<code>\1</code>|' \
	| sed '/^\s*Active:/ s|\( active (.*)\)|<grn>\1</grn>|; s|\( inactive (.*)\)|<red>\1</red>|; s|\(failed\)|<red>\1</red>|ig' \
	| grep -v 'Could not resolve keysym\|Address family not supported by protocol\|ERROR:chrome_browser_main_extra_parts_metrics' )" # omit warning by xkeyboard | chromium
	grep -q '<grn>' <<< "$status" && dot='<grn>●</grn>' || dot='<red>●</red>'
	if [[ -e $conf ]]; then
		status="\
$dot <code>$( pacman -Q $pkg )</code>
$( cat $conf )

$dot $status"
	fi
	echo "$status"
	;;
pladd )
	item=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	mpc -q add "$item"
	pladdPlay $cmd $delay
	;;
playerstart )
	newplayer=${args[1]}
	[[ $newplayer == bluetooth ]] && volumeGet save
	mpc -q stop
	systemctl stop radio
	rm -f $dirshm/{radio,status}
	player=$( cat $dirshm/player )
	echo $newplayer > $dirshm/player
	case $player in
		airplay )   restart=shairport-sync;;
		bluetooth ) restart=bluezdbus;;
		mpd|upnp )  restart=mpd;;
		snapcast )  stop=snapclient;;
		spotify )   restart=spotifyd;;
	esac
	[[ $stop ]] && systemctl stop $stop || systemctl restart $restart
	pushstream player '{"player":"'$newplayer'","active":true}'
	;;
playerstop )
	player=${args[1]}
	elapsed=${args[2]}
	[[ -e $dirsystem/scrobble && -e $dirsystem/scrobble.conf/$player ]] && cp -f $dirshm/{status,scrobble}
	killall cava &> /dev/null
	echo mpd > $dirshm/player
	[[ $player != upnp ]] && $dirbash/status-push.sh
	case $player in
		airplay )
			service=shairport-sync
			systemctl stop shairport-meta
			rm -f $dirshm/airplay/start
			;;
		bluetooth )
			service=bluezdbus
			;;
		snapcast )
			service=snapclient
			systemctl stop snapclient
			clientip=$( ifconfig | awk '/inet .*broadcast/ {print $2}' )
			sshpass -p ros ssh -qo StrictHostKeyChecking=no root@$( cat $dirshm/serverip ) \
				"/srv/http/bash/snapcast.sh remove $clientip"
			rm $dirshm/serverip
			;;
		spotify )
			service=spotifyd
			rm -f $dirshm/spotify/start
			;;
		upnp )
			service=upmpdcli
			mpc -q stop
			tracks=$( mpc -f %file%^%position% playlist | grep 'http://192' | cut -d^ -f2 )
			for i in $tracks; do
				mpc -q del $i
			done
			$dirbash/status-push.sh
			;;
	esac
	[[ $service != snapclient ]] && systemctl restart $service
	[[ -e $dirshm/mpdvolume ]] && volumeReset
	pushstream player '{"player":"'$player'","active":false}'
	[[ -e $dirshm/scrobble ]] && scrobbleOnStop $elapsed
	;;
plcrop )
	if mpc | grep -q playing; then
		mpc -q crop
	else
		mpc -q play
		mpc -q crop
		mpc -q stop
	fi
	systemctl -q is-active libraryrandom && $dirbash/cmd-librandom.sh
	$dirbash/status-push.sh
	pushstreamPlaylist
	;;
plcurrent )
	mpc -q play ${args[1]}
	mpc -q stop
	$dirbash/status-push.sh
	;;
plfindadd )
	if [[ ${args[1]} != multi ]]; then
		type=${args[1]}
		string=${args[2]}
		cmd=${args[3]}
		pladdPosition $cmd
		mpc -q findadd $type "$string"
	else
		type=${args[2]}
		string=${args[3]}
		type2=${args[4]}
		string2=${args[5]}
		cmd=${args[6]}
		pladdPosition $cmd
		mpc -q findadd $type "$string" $type2 "$string2"
	fi
	pladdPlay $cmd $delay
	;;
plload )
	playlist=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	mpc -q load "$playlist"
	pladdPlay $cmd $delay
	;;
plloadrange )
	range=${args[1]}
	playlist=${args[2]}
	cmd=${args[3]}
	delay=${args[4]}
	pladdPosition $cmd
	mpc -q --range=$range load "$playlist"
	pladdPlay $cmd $delay
	;;
plls )
	dir=${args[1]}
	cmd=${args[2]}
	delay=${args[3]}
	pladdPosition $cmd
	readarray -t cuefiles <<< $( mpc ls "$dir" | grep '\.cue$' | sort -u )
	if [[ -z $cuefiles ]]; then
		mpc ls "$dir" | mpc -q add &> /dev/null
	else
		for cuefile in "${cuefiles[@]}"; do
			mpc -q load "$cuefile"
		done
	fi
	pladdPlay $cmd $delay
	;;
plorder )
	mpc -q move ${args[1]} ${args[2]}
	pushstreamPlaylist
	;;
plremove )
	pos=${args[1]}
	activenext=${args[2]}
	if [[ $pos ]]; then
		mpc -q del $pos
		[[ $activenext ]] && mpc -q play $activenext && mpc -q stop
	else
		mpc -q clear
	fi
	$dirbash/status-push.sh
	pushstreamPlaylist
	;;
plrename )
	mv "$dirdata/playlists/${args[1]}" "$dirdata/playlists/${args[2]}"
	pushstreamPlaylist
	;;
plshuffle )
	mpc -q shuffle
	pushstreamPlaylist
	;;
plsimilar )
	plLprev=$( mpc playlist | wc -l )
	linesL=${#args[@]}
	[[ ${args[1]} == addplay ]] && pos=$(( $( mpc playlist | wc -l ) + 1 ))
	for (( i=1; i < linesL; i++ )); do
		artist=${args[$i]}
		(( i++ ))
		title=${args[$i]}
		[[ -z $artist || -z $title ]] && continue
		
		file=$( mpc find artist "$artist" title "$title" )
		[[ -z $file ]] && continue
		
		list+="$( mpc find artist "$artist" title "$title" )
"
	done
	echo "$list" | awk 'NF' | mpc -q add
	pushstreamPlaylist
	echo $(( $( mpc playlist | wc -l ) - plLprev ))
	[[ $pos ]] && mpc -q play $pos
	;;
power )
	reboot=${args[1]}
	mpc -q stop
	[[ -e $dirsystem/lcdchar ]] && $dirbash/lcdchar.py logo
	[[ -e $dirsystem/mpdoled ]] && mpdoledLogo
	cdda=$( mpc -f %file%^%position% playlist | grep ^cdda: | cut -d^ -f2 )
	[[ $cdda ]] && mpc -q del $cdda
	if [[ -e $dirshm/relayson ]]; then
		$dirbash/relays.sh
		sleep 2
	fi
	if [[ $reboot ]]; then
		data='{"title":"Power","text":"Reboot ...","icon":"reboot blink","delay":-1,"power":"reboot"}'
	else
		data='{"title":"Power","text":"Off ...","icon":"power blink","delay":-1,"power":"off"}'
	fi
	pushstream notify "$data"
	ply-image /srv/http/assets/img/splash.png &> /dev/null
	if mount | grep -q /mnt/MPD/NAS; then
		umount -l /mnt/MPD/NAS/* &> /dev/null
		sleep 3
	fi
	[[ -e /boot/shutdown.sh ]] && /boot/shutdown.sh
	[[ -z $reboot && -e $dirsystem/lcdchar ]] && $dirbash/lcdchar.py off
	[[ $reboot ]] && reboot || poweroff
	;;
rebootlist )
	[[ -e $dirshm/reboot ]] && cat $dirshm/reboot \
								| sort -u \
								| tr '\n' ^ \
								| head -c -1
	;;
refreshbrowser )
	pushstream reload 1
	;;
relaystimerreset )
	kill -9 $( pgrep relaystimer ) &> /dev/null
	$dirbash/relaystimer.sh &> /dev/null &
	pushstream relays '{"state":"RESET"}'
	;;
rotateSplash )
	rotateSplash ${args[1]}
	;;
screenoff )
	DISPLAY=:0 xset ${args[1]}
	;;
scrobble )
	$dirbash/scrobble.sh "\
${args[1]}
${args[2]}
${args[3]}" &> /dev/null &
	;;
thumbgif )
	gifThumbnail "${args:1}"
	;;
thumbjpg )
	jpgThumbnail "{$args:1}"
	;;
upnpnice )
	for pid in $( pgrep upmpdcli ); do
		ionice -c 0 -n 0 -p $pid &> /dev/null 
		renice -n -19 -p $pid &> /dev/null
	done
	;;
volume )
	current=${args[1]}
	target=${args[2]}
	control=${args[3]}
	filevolumemute=$dirsystem/volumemute
	if [[ $target > 0 ]]; then      # set
		type=set
		rm -f $filevolumemute
		pushstreamVolume set $target
	else
		if (( $current > 0 )); then # mute
			type=mute
			target=0
			echo $current > $filevolumemute
			pushstreamVolume mute $current
		else                        # unmute
			type=unmute
			target=$( cat $filevolumemute )
			rm -f $filevolumemute
			pushstreamVolume unmute $target
		fi
	fi
	volumeSet "$current" $target "$control" # $current may be blank
	;;
volume0db )
	player=$( cat $dirshm/player )
	if [[ $player == airplay || $player == spotify ]]; then
		volumeGet
		echo $volume $db  > $dirshm/mpdvolume
	fi
	volume0dB
	;;
volumecontrols )
	volumeControls ${args[1]}
	echo "$controls"
	;;
volumecontrolget )
	volumeGet
	echo $control^$volume # place $control first to keep trailing space if any
	;;
volumeget )
	volumeGet
	[[ ${args[1]} == db ]] && echo $volume $db || echo $volume
	;;
volumepushstream )
	[[ -e $dirshm/btclient ]] && sleep 1
	volumeGet
	pushstream volume '{"val":'$volume'}'
	[[ $control ]] && alsactl store
	;;
volumereset )
	volumeReset
	;;
volumesave )
	volumeGet save
	;;
volumeupdown )
	updn=${args[1]}
	control=${args[2]}
	[[ -z $control ]] && mpc -q volume ${updn}1 || amixer -Mq sset "$control" 1%$updn
	volumeGet
	pushstreamVolume updn $volume
	;;
webradioadd )
	name=${args[1]}
	url=$( urldecode ${args[2]} )
	dir=${args[3]}
	urlname=${url//\//|}
	file=$dirwebradios
	[[ $dir ]] && file="$file/$dir"
	file="$file/$urlname"
	ext=${url/*.}
	if [[ $ext == m3u ]]; then
		url=$( curl -s $url | grep ^http | head -1 )
	elif [[ $ext == pls ]]; then
		url=$( curl -s $url | grep ^File | head -1 | cut -d= -f2 )
	fi
	[[ -z $url ]] && exit -1
	
	echo $name > "$file"
	chown http:http "$file" # for edit in php
	count=$(( $( grep webradio $dirmpd/counts | cut -d: -f2 ) - 1 ))
	pushstream webradio $count
	sed -i 's/\("webradio": \).*/\1'$count'/' $dirmpd/counts
	;;
webradiocoverreset )
	coverart=${args[1]}
	cover=${coverart:0:-15} # remove .1234567890.jpg
	rm -f "/srv/http$cover"{,-thumb}.*
	pushstream coverart '{"url":"'$coverart'","type":"webradioreset"}'
	;;
webradiodelete )
	url=${args[1]}
	dir=${args[2]}
	urlname=${url//\//|}
	[[ $dir ]] && dir="$dir/"
	rm -f "$dirwebradios/$dir$urlname" "${dirwebradios}img/$urlname"{,-thumb}.*
	count=$(( $( grep webradio $dirmpd/counts | cut -d: -f2 ) - 1 ))
	pushstream webradio $count
	sed -i 's/\("webradio": \).*/\1'$count'/' $dirmpd/counts
	;;
webradioedit ) # name, newname, url, newurl
	name=${args[1]}
	namenew=${args[2]}
	url=${args[3]}
	urlnew=$( urldecode ${args[4]} )
	dir=${args[5]}
	urlname=${url//\//|}
	urlnamenew=${urlnew//\//|}
	[[ $dir ]] && dir="$dir/"
	fileprev="$dirwebradios/$dir$urlname"
	filenew="$dirwebradios/$dir$urlnamenew"
	[[ $name != $namenew ]] && sed -i "1 c$namenew" "$fileprev"
	if [[ $url != $urlnew ]]; then
		mv "$fileprev" "$filenew"
		mv ${dirwebradios}img/{$urlname,$urlnamenew}.jpg 
		mv ${dirwebradios}img/{$urlname,$urlnamenew}-thumb.jpg 
	fi
	pushstream webradio -1
	;;
wrdirdelete )
	path=${args[1]}
	if [[ $( ls -A "$dirwebradios/$path" ) ]]; then
		echo -1
	else
		rm -rf "$dirwebradios/$path"
		pushstream webradio $count -1
	fi
	;;
wrdirnew )
	path=${args[1]}
	mkdir -p "$dirwebradios/$path"
	pushstream webradio $count -1
	;;
wrdirrename )
	path=${args[1]}
	name=${args[2]}
	newname=${args[3]}
	mv -f "$dirwebradios/$path/$name" "$dirwebradios/$path/$newname"
	pushstream webradio $count -1
	;;
	
esac
