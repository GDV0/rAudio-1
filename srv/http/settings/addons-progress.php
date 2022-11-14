<?php
ignore_user_abort( TRUE ); // for 'connection_status()' to work

$sudobash = '/usr/bin/sudo /srv/http/bash/';
$addons   = json_decode( file_get_contents( '/srv/http/data/addons/addons-list.json' ), true );
$opt      = $_POST[ 'opt' ] ?? [ 'r1', 'Debug', 'debug' ]; // [ alias, type, branch, opt1, opt2, ... ]
$alias    = $opt[ 0 ];
$type     = $opt[ 1 ];
$branch   = $opt[ 2 ] ?? '';
$addon    = $addons[ $alias ];
if ( $alias !== 'cove' ) {
	$icon  = '<i class="page-icon fa fa-jigsaw"></i>';
	$title = 'ADDONS PROGRESS';
	$href  = '/settings.php?p=addons';
	$name  = preg_replace( '/\**$/', '', $addon[ 'title' ] );
} else {
	$icon  = '<i class="page-icon iconcover"></i>';
	$title = 'Cover Art Thumbnails';
	$href  = '/';
	$name  = 'Cover Art Thumbnails';
	$opt   = array_slice( $opt, 3 );
}
$options = preg_replace( '/(["`])/', '\\\\\1', implode( "\n", $opt ) );
if ( isset( $addon[ 'option' ][ 'password' ] ) ) { // hide password
	$i             = array_search( 'password', array_keys( $addon[ 'option' ] ) );
	$opt[ $i + 3 ] = '***';
}
$postinfo      = $type." done.";
$postinfo     .= isset( $addon[ 'postinfo' ] ) ? '<br><br><i class="fa fa-info-circle"></i>'.$addon[ 'postinfo' ] : '';
$installurl    = $addon[ 'installurl' ];
$installfile   = basename( $installurl );
$uninstallfile = "/usr/local/bin/uninstall_$alias.sh";
if ( $branch && $branch !== $addon[ 'version' ] ) $installurl = str_replace( 'raw/main', 'raw/'.$branch, $installurl );
?>
<br>
<p id="addontitle"><i class="gr fa fa-gear<?=( $localhost ? '' : ' blink' )?>"></i>&ensp;<?=$name?> <gr>•</gr> <?=$type?> ...</p>
	
<script src="/assets/js/plugin/jquery-3.6.1.min.js"></script>
<script src="/assets/js/common.js?v=<?=$time?>"></script>
<script>
document.title = 'Addons';
$( '.help-head' ).remove();
$( '.container' ).removeClass( 'hide' );
loaderHide();
$( '.close' ).click( function() {
	location.href = '<?=$href?>';
} );
var scroll = setInterval( () => {
	var $progress = $( '#progress' );
	$progress.scrollTop( $progress.prop( 'scrollHeight' ) );
}, 500 );
// js for '<pre>' must be here before start stdout
// php 'flush' loop waits for all outputs before going to next lines
// but must 'setTimeout()' for '<pre>' to load to fix 'undefined'
</script>

<pre id="progress">
<?php
// ......................................................................................
$getinstall = <<< EOF
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
EOF;

if ( $alias === 'cove' ) {
	$command    = $sudobash.'albumthumbnail.sh "'.$options.'"';
	$commandtxt = '/srv/http/bash/albumthumbnail.sh "'.$options.'"';
} else if ( $type === 'Uninstall' ) {
	$command    = $uninstall;
	$commandtxt = "uninstall_$alias.sh";
} else if ( $type === 'Update' && ! isset( $addon[ 'nouninstall' ] ) ) {
	$command    = <<< EOF
$getinstall
$uninstall
/usr/bin/sudo ./$installfile "$options"
EOF;
	$commandtxt = <<< EOF
curl -sfLO $installurl
chmod 755 $installfile
uninstall_$alias.sh
./$installfile "$options"
EOF;
} else {
	$command    = <<< EOF
$getinstall
/usr/bin/sudo ./$installfile "$options"
EOF;
	$commandtxt = <<< EOF
curl -sfLO $installurl
chmod 755 $installfile
./$installfile "$options"
EOF;
}
echo $commandtxt.'<br>';

if ( $type !== 'Debug' ) {
// >.......................................................................................................
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
$skip       = ['warning:', 'permissions differ', 'filesystem:', 'uninstall:', 'y/n' ];
$skippacman = [ 'downloading core.db', 'downloading extra.db', 'downloading alarm.db', 'downloading aur.db' ];
$fillbuffer = '<p class="flushdot">'.str_repeat( '.', 40960 ).'</p>';
ob_implicit_flush( true ); // start flush: bypass buffer - output to screen
ob_end_flush();            // force flush: current buffer (run after flush started)

echo $fillbuffer;          // fill buffer to force start output
if ( $type === 'Uninstall' ) sleep( 1 );
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$popencmd = popen( "$command 2>&1", 'r' ); // start bash
while ( ! feof( $popencmd ) ) {            // get stdout until eof
	$std = fgets( $popencmd );             // get each line
	$std = preg_replace(                   // convert to html
		array_keys( $replace ),
		array_values( $replace ),
		$std
	);
	foreach( $skip as $find ) {            // skip line
		if ( stripos( $std, $find ) !== false ) continue 2;
	}
	foreach( $skippacman as $findp ) {     // skip pacman line after output once
		if ( stripos( $std, $findp ) !== false ) $skip[] = $findp; // add skip string to $skip array
	}
	echo $std;                             // output to screen
	echo $fillbuffer;                      // fill buffer after each line
	
	// abort on browser back/close
	if ( connection_status() !== 0 || connection_aborted() === 1 ) {
		pclose( $popencmd );
		exec( $sudobash.'addons.sh abort '.$installfile.' '.$alias );
		exit;
	}
}
sleep( 1 );
pclose( $popencmd );
// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// <........................................................................................................
}
?>
</pre>

<script>
setTimeout( () => { clearInterval( scroll ) }, 1000 );
$( '#addontitle i' ).removeClass( 'blink' );
info( {
	  icon    : 'jigsaw'
	, title   : '<?=$name?>'
	, message : '<?=$postinfo?>'
} );
</script>

</body>
</html>
<!-- ...................................................................................... -->
