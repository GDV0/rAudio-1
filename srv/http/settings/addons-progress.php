<?php
ignore_user_abort( TRUE ); // for 'connection_status()' to work

$addons = json_decode( file_get_contents( '/srv/http/data/addons/addons-list.json' ), true );
$time = time();

$opt = $_POST[ 'opt' ]; // [ alias, type, branch, opt1, opt2, ... ]
$alias = $opt[ 0 ];
$type = $opt[ 1 ];
$branch = $opt[ 2 ] ?? '';
$addon = $addons[ $alias ];
if ( $alias !== 'cove' ) {
	$heading = 'Addons Progress';
	$href = '/settings/addons.php';
	$title = preg_replace( '/\**$/', '', $addon[ 'title' ] );
} else {
	$heading = 'Cover Art Thumbnails';
	$href = '/';
	$title = 'Cover Art Thumbnails';
	$opt = array_slice( $opt, 3 );
}
$options = preg_replace( '/(["`])/', '\\\\\1', implode( "\n", $opt ) );
if ( isset( $addon[ 'option' ][ 'password' ] ) ) { // hide password
	$i = array_search( 'password', array_keys( $addon[ 'option' ] ) );
	$opt[ $i + 3 ] = '***';
}
$postinfo = $type." done.<br>See Addons Progress for result.";
$postinfo.= isset( $addon[ 'postinfo' ] ) ? '<br><br><i class="fa fa-info-circle"></i>'.$addon[ 'postinfo' ] : '';
$installurl = $addon[ 'installurl' ];
$installfile = basename( $installurl );
$uninstallfile = "/usr/local/bin/uninstall_$alias.sh";
if ( $branch && $branch !== $addon[ 'version' ] ) $installurl = str_replace( 'raw/main', 'raw/'.$branch, $installurl );
$blink = $_SERVER["REMOTE_ADDR"] === '127.0.0.1' ? '' : 'blink';
?>
<!DOCTYPE html>
<html>
<head>
	<title>addons</title>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="apple-mobile-web-app-status-bar-style" content="black">
	<meta name="msapplication-tap-highlight" content="no">
	<link rel="icon" href="/assets/img/icon.png">
	<link rel="stylesheet" href="/assets/css/colors.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/common.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/info.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/addons.<?=$time?>.css">
</head>
<body>

<div class="container progress">
	<heading><?=$heading?><i id="close" class="fa fa-times"></i></heading>
	<p id="wait">
		<wh><?=$title?></wh><br>
		<i class="fa fa-gear <?=$blink?>"></i>&nbsp; <?=$type?> ...
	</p>
	
<script src="/assets/js/plugin/jquery-3.6.0.min.js"></script>
<script src="/assets/js/info.<?=$time?>.js"></script>
<script>
$( '#loader' ).addClass( 'hide' );
var blink;
var $icon = $( '#wait i' );
if ( !$icon.hasClass( 'blink' ) ) {
	blink = setInterval( function() {
		$icon.addClass( 'clear' );
		setTimeout( function() {
			$icon.removeClass( 'clear' );
		}, 1000 );
	}, 1500 );
}
$( '#close' ).click( function() {
	$.post( '../cmd.php', {
		  cmd  : 'bash'
		, bash : 'curl -s -X POST http://127.0.0.1/pub?id=reload -d 1'
	}, function() {
		location.href = '<?=$href?>';
	} );
} );
var scroll = setInterval( function() {
	$( 'pre' ).scrollTop( $( 'pre' ).prop( 'scrollHeight' ) );
}, 500 );
// js for '<pre>' must be here before start stdout
// php 'flush' loop waits for all outputs before going to next lines
// but must 'setTimeout()' for '<pre>' to load to fix 'undefined'
</script>

	<pre>
<!-- ...................................................................................... -->
<?php
$getinstall = <<<cmd
curl -sfLO $installurl
if [[ $? != 0 ]]; then
	echo -e '\e[38;5;7m\e[48;5;1m ! \e[0m Install file download failed.'
	echo 'Please try again.'
	exit
fi
chmod 755 $installfile
cmd;
$uninstall = <<<cmd
/usr/bin/sudo $uninstallfile
cmd;

if ( $alias === 'cove' ) {
	$command = '/usr/bin/sudo /srv/http/bash/albumthumbnail.sh "'.$options.'"';
	$commandtxt = '/srv/http/bash/albumthumbnail.sh "'.$options.'"';
} else if ( $type === 'Uninstall' ) {
	$command = $uninstall;
	$commandtxt = "uninstall_$alias.sh";
} else if ( $type === 'Update' && !isset( $addon[ 'nouninstall' ] ) ) {
	$command = <<<cmd
$getinstall
$uninstall
/usr/bin/sudo ./$installfile "$options"
cmd;
	$commandtxt = <<<cmd
curl -sfLO $installurl
chmod 755 $installfile
uninstall_$alias.sh
./$installfile "$options"
cmd;
} else {
	$command = <<<cmd
$getinstall
/usr/bin/sudo ./$installfile "$options"
cmd;
	$commandtxt = <<<cmd
curl -sfLO $installurl
chmod 755 $installfile
./$installfile "$options"
cmd;
}

// convert bash stdout to html
$replace = [
	'/.\[38;5;8m.\[48;5;8m/' => '<a class="cbgr">',     // bar - gray
	'/.\[38;5;7m.\[48;5;7m/' => '<a class="cbw">',      // bar - white
	'/.\[38;5;6m.\[48;5;6m/' => '<a class="cbc">',      // bar - cyan
	'/.\[38;5;5m.\[48;5;5m/' => '<a class="cbm">',      // bar - magenta
	'/.\[38;5;4m.\[48;5;4m/' => '<a class="cbb">',      // bar - blue
	'/.\[38;5;3m.\[48;5;3m/' => '<a class="cby">',      // bar - yellow
	'/.\[38;5;2m.\[48;5;2m/' => '<a class="cbg">',      // bar - green
	'/.\[38;5;1m.\[48;5;1m/' => '<a class="cbr">',      // bar - red
	'/.\[38;5;8m.\[48;5;0m/' => '<a class="cgr">',      // tcolor - gray
	'/.\[38;5;6m.\[48;5;0m/' => '<a class="cc">',       // tcolor - cyan
	'/.\[38;5;5m.\[48;5;0m/' => '<a class="cm">',       // tcolor - magenta
	'/.\[38;5;4m.\[48;5;0m/' => '<a class="cb">',       // tcolor - blue
	'/.\[38;5;3m.\[48;5;0m/' => '<a class="cy">',       // tcolor - yellow
	'/.\[38;5;2m.\[48;5;0m/' => '<a class="cg">',       // tcolor - green
	'/.\[38;5;1m.\[48;5;0m/' => '<a class="cr">',       // tcolor - red
	'/.\[38;5;0m.\[48;5;3m/' => '<a class="ckby">',     // info, yesno
	'/.\[38;5;7m.\[48;5;1m/' => '<a class="cwbr">',     // warn
	'/=(=+)=/'               => '<hr>',                 // double line
	'/-(-+)-/'               => '<hr class="hrlight">', // line
	'/.\[38;5;6m/'           => '<a class="cc">',       // lcolor
	'/.\[0m/'                => '</a>',                 // reset color
];
$skip = ['warning:', 'permissions differ', 'filesystem:', 'uninstall:', 'y/n' ];
$skippacman = [ 'downloading core.db', 'downloading extra.db', 'downloading alarm.db', 'downloading aur.db' ];
$fillbuffer = '<p class="flushdot">'.str_repeat( '.', 40960 ).'</p>';
ob_implicit_flush( true ); // start flush: bypass buffer - output to screen
ob_end_flush();            // force flush: current buffer (run after flush started)

echo $fillbuffer;          // fill buffer to force start output
echo $commandtxt.'<br>';
if ( $type === 'Uninstall' ) sleep( 1 );

$popencmd = popen( "$command 2>&1", 'r' );              // start bash
while ( !feof( $popencmd ) ) {                          // each line
	$std = fread( $popencmd, 4096 );                    // read

	$std = preg_replace(                                // convert to html
		array_keys( $replace ),
		array_values( $replace ),
		$std
	);
	foreach( $skip as $find ) {                         // skip line
		if ( stripos( $std, $find ) !== false ) continue 2;
	}
	foreach( $skippacman as $findp ) {                  // skip pacman line after output once
		if ( stripos( $std, $findp ) !== false ) $skip[] = $findp; // add skip string to $skip array
	}
	echo $std;                                          // stdout to screen
	echo $fillbuffer;                                   // fill buffer to force output line by line
	
	// abort on browser back/close
	if ( connection_status() !== 0 || connection_aborted() === 1 ) {
		$sudo = '/usr/bin/sudo /usr/bin';
		exec( "$sudo/killall $( basename $installfile ) wget pacman &" );
		exec( "$sudo/rm /var/lib/pacman/db.lck /srv/http/*.zip /usr/local/bin/uninstall_$alias.sh /srv/http/data/addons/$alias &" );
		pclose( $popencmd );
		exit;
	}
}
sleep( 1 );
pclose( $popencmd );
?>
<!-- ...................................................................................... -->
	</pre>
</div>

<script>
clearInterval( blink );
clearInterval( scroll );
$( 'pre' ).scrollTop( $( 'pre' ).prop( 'scrollHeight' ) );
$( '#wait' ).remove();
info( {
	  icon    : 'jigsaw'
	, title   : '<?=$title?>'
	, message : '<?=$postinfo?>'
} );
</script>

</body>
</html>
<!-- ...................................................................................... -->
