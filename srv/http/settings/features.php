<?php
$hostname = getHostName();
$ip = getHostByName( $hostname );

$head = [ 'title' => 'Renderers' ]; //////////////////////////////////
$body = [
	[
		  'label'    => 'AirPlay'
		, 'id'       => 'shairport-sync'
		, 'sublabel' => 'shairport-sync'
		, 'icon'     => 'airplay'
		, 'status'   => 'shairport-sync'
		, 'disabled' => 'AirPlay is currently active.'
		, 'help'     => <<< HTML
<a href="https://github.com/mikebrady/shairport-sync">Shairport-sync</a> - AirPlay rendering device.
HTML
		, 'exist'    => file_exists( '/usr/bin/shairport-sync' )
	]
	, [
		  'label'    => 'SnapClient'
		, 'sublabel' => 'snapclient'
		, 'id'       => 'snapclient'
		, 'icon'     => 'snapcast'
		, 'status'   => 'snapclient'
		, 'setting'  => true
		, 'disabled' => 'SnapServer is currently active/enabled.'
		, 'help'     => <<< HTML
<a href="https://github.com/badaix/snapcast">Snapcast</a> - Multiroom client-server audio player
Connect: &ensp;<i class="fa fa-networks"></i>Networks |&ensp;<i class="fa fa-snapcast"></i>
HTML
		, 'exist'    => file_exists( '/usr/bin/snapserver' )
	]
	, [
		  'label'    => 'Spotify'
		, 'id'       => 'spotifyd'
		, 'sublabel' => 'spotifyd'
		, 'icon'     => 'spotify'
		, 'status'   => 'spotifyd'
		, 'setting'  => true
		, 'disabled' => 'Spotify is currently active.'
		, 'help'     => <<< HTML
<a href="https://github.com/Spotifyd/spotifyd">Spotifyd</a> - Spotify Connect device.
 • Require Premium account. (No Spotify password saved on rAudio.)
 • Get <code>ID</code> and <code>Secret</code> from private app : <bll class="screenshot pointer">(Screenshots)</bll>
 &emsp; • <a href="https://developer.spotify.com/dashboard/applications" target="_blank">Spotify for Developers</a> > <code>LOGIN</code> with normal Spotify account
 &emsp; • <code>CREATE AN APP</code>
 &emsp; &emsp; - <wh>App name:</wh> <gr>(any)</gr>
 &emsp; &emsp; - <wh>App description:</wh> <gr>(any)</gr>
 &emsp; • <code>EDIT SETTINGS</code>
 &emsp; &emsp; - <WH>Redirect URIs:</WH> <span id="redirecturi"></span>
 &emsp; • <code>USERS AND ACCESS</code> > <code>ADD NEW USER</code>
 &emsp; &emsp; - <wh>Name:</wh> <gr>(any)</gr>
 &emsp; &emsp; - <wh>Spotify Account:</wh> (login email)
 &emsp; • rAudio <code>Spotify</code>
 &emsp; &emsp; - Paste <wh>Client ID</wh> and <wh>Client Secret</wh> from the app
HTML
		, 'exist'    => file_exists( '/usr/bin/spotifyd' )
	]
	, [
		  'label'    => 'UPnP'
		, 'id'       => 'upmpdcli'
		, 'sublabel' => 'upmpdcli'
		, 'icon'     => 'upnp'
		, 'status'   => 'upmpdcli'
		, 'setting'  => true
		, 'disabled' => 'UPnP is currently active.'
		, 'help'     => <<< HTML
<a href="https://www.lesbonscomptes.com/upmpdcli/">upmpdcli</a> - UPnP / DLNA rendering device.
HTML
		, 'exist'    => file_exists( '/usr/bin/upmpdcli' )
	]
];
htmlSection( $head, $body );
$head = [ 'title' => 'Streamers' ]; //////////////////////////////////
$body = [
	[
	  'label'    => 'For browsers'
	, 'id'       => 'streaming'
	, 'sublabel' => 'MPD httpd'
	, 'icon'     => 'webradio'
	, 'help'     => <<< HTML
<a href="https://wiki.archlinux.org/index.php/Music_Player_Daemon/Tips_and_tricks#HTTP_streaming">HTTP streaming</a> - Asynchronous streaming for browsers via <code>http://$ip:8000</code> (Latency - several seconds)
HTML
	]
	, [
		  'label'    => 'SnapServer'
		, 'id'       => 'snapserver'
		, 'sublabel' => 'snapserver'
		, 'icon'     => 'snapcast'
		, 'status'   => 'snapserver'
		, 'disabled' => 'SnapClient is currently enabled.'
		, 'help'     => <<< HTML
<a href="https://github.com/badaix/snapcast">Snapcast</a> - Multiroom client-server audio player. SnapServer - Clients can be either between RPis or with Snapcast capable devices.
Control clients:
 • <a href="https://github.com/badaix/snapweb">Snapweb</a> via <code>http://$ip:1780</code>
 • <a href="https://github.com/badaix/snapdroid">Snapdroid</a>
HTML
		, 'exist'    => file_exists( '/usr/bin/snapserver' )
	]
];
htmlSection( $head, $body );
$head = [ 'title' => 'Others' ]; //////////////////////////////////
$body = [
	[
		  'label'    => 'Access Point'
		, 'id'       => 'hostapd'
		, 'sublabel' => 'hostapd'
		, 'icon'     => 'accesspoint'
		, 'status'   => 'hostapd'
		, 'setting'  => true
		, 'disabled' => 'Wi-Fi is currently connected.'
		, 'help'     => <<< HTML
<a href="https://w1.fi/hostapd/">hostapd</a> - Connect with rAudio hotspot directly when no routers available.
This should be used only when necessary.
HTML
		, 'exist'    => file_exists( '/usr/bin/hostapd' )
	]
	, [
		  'label'   => 'AutoPlay'
		, 'id'      => 'autoplay'
		, 'icon'    => 'play'
		, 'setting' => true
		, 'help'    => <<< HTML
Start playing automatically on:
 • Bluetooth connected
 • Audio CD inserting
 • Power on / Reboot
HTML
	]
	, [
		  'label'    => 'Browser on RPi'
		, 'id'       => 'localbrowser'
		, 'sublabel' => 'chromium'
		, 'icon'     => 'chromium'
		, 'status'   => 'localbrowser'
		, 'setting'  => true
		, 'help'     => <<< HTML
<a href="https://github.com/chromium/chromium">Chromium</a> - Browser on RPi connected screen.
 • TFT 3.5" LCD: Rotate needs reboot.
 • Screen off: Blank screen - backlight still on (no energy saved)
 • HDMI display: Must be connected before boot.
HTML
		, 'exist'    => file_exists( '/usr/bin/chromium' )
	]
	, [
		  'label'    => 'File Sharing'
		, 'id'       => 'smb'
		, 'sublabel' => 'smb'
		, 'icon'     => 'networks'
		, 'status'   => 'smb'
		, 'setting'  => true
		, 'help'     => <<< HTML
<a href="https://www.samba.org">Samba</a> - Share files on network.
 • Set sources permissions for read+write - directory: <code>0777</code> file: <code>0555</code>
 • At address bar of Windows File Explorer: <code>\\\\$ip</code> or <code>\\\\$hostname</code>
HTML
		, 'exist'    => file_exists( '/usr/bin/smbd' )
	]
	, [
		  'label' => 'Lyrics in File'
		, 'id'    => 'lyricsembedded'
		, 'icon'  => 'lyrics'
		, 'help'  => <<< HTML
 • Get embedded lyrics from local files.
 • Search online if not available.
 • Should be disable if most lyrics are not embedded.
 • Online fetched lyrics are saved as separate files, not embedded.
HTML
	]
	, [
		  'label'    => 'Password Login'
		, 'id'       => 'login'
		, 'sublabel' => 'password_hash'
		, 'icon'     => 'lock'
		, 'setting'  => 'self'
		, 'help'     => <<< HTML
<a href="https://www.php.net/manual/en/function.password-hash.php">password_hash</a> - Force browser interface login with password using <code>PASSWORD_BCRYPT</code>.
Lock: &ensp;<i class="fa fa-features"></i>Features |&ensp;<i class="fa fa-lock"></i>
HTML
	]
	, [
		  'label'    => 'Scrobble'
		, 'id'       => 'scrobble'
		, 'icon'     => 'lastfm'
		, 'setting'  => true
		, 'help'     => <<< HTML
 • Send artist, title and album of played tracks to <a href="https://www.last.fm/">Last.fm</a> to save in user's database.
 • Require Last.fm account.
 • No Last.fm password saved on rAudio.
 • Option to include renderers - Exclude if already scrobbleed by sender devices.
 • SnapClient already scrobbled by SnapServer.
 • WebRadio must be manually scrobbled: Title > <i class="fa fa-lastfm"></i>Scrobble
HTML
	]
	, [
		  'label'   => 'Stop Timer'
		, 'id'      => 'stoptimer'
		, 'icon'    => 'stopwatch'
		, 'setting' => true
		, 'help'    => <<< HTML
Stop timer:
 • Lower volume to 0 (Mute).
 • Stop player.
 • Restore volume to previous level.
 • If set, power off.
HTML
	]
];
htmlSection( $head, $body );
