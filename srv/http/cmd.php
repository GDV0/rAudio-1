<?php
$sudo         = '/usr/bin/sudo ';
$sudobin      = $sudo.'/usr/bin/';
$sudosettings = '/usr/bin/sudo /srv/http/bash/settings/';
$dirdata      = '/srv/http/data/';

switch( $_POST[ 'cmd' ] ) {

// multiple arguments passing to bash as array
//  - no each argument quote
//  - escape ["`] in mutiline once by php
//    js   -> php  - array
//    php  -> bash - array > multiline string ( escaped ["`] )
//    bash         - multiline string > arguments = array by line
//    bash -> php  - string / json literal
//    php  -> js   - string / array / json literal( response type 'json' )
//
case 'sh': // multiple commands / scripts: no pre-escaped characters - js > php > bash
	$sh     = $_POST[ 'sh' ];                                // php array = js array
	$script = '/srv/http/bash/'.array_shift( $sh ).' "'; // script    = 1st element
	$script.= escape( implode( "\n", $sh ) ).'"';        // arguments = array > escaped multiline string
	echo rtrim( shell_exec( $sudo.$script ) );           // bash arguments = multiline string > array by line
	break;
case 'bash': // single / one-line command - return string
	$cmd = $_POST[ 'bash' ];
	if ( $cmd[ 0 ] === '/' ) {
		$cmd = $sudo.$cmd;
	} else if ( $cmd[ 0 ] !== '{' ) {
		$cmd = $sudobin.$cmd;
	}
	echo shell_exec( $cmd );
	break;
case 'exec': // single / one-line command - return array of lines to js
	$cmd = $_POST[ 'exec' ];
	exec( $sudobin.$cmd, $output, $std );
	echo json_encode( $output );
	break;
	
case 'datarestore':
	if ( $_FILES[ 'file' ][ 'error' ] != UPLOAD_ERR_OK ) exit( '-1' );
	
	move_uploaded_file( $_FILES[ 'file' ][ 'tmp_name' ], $dirdata.'tmp/backup.gz' );
	exec( $sudosettings.'system.sh datarestore', $output, $result );
	if ( $result != 0 ) exit( '-2' );
	break;
case 'giftype':
	$tmpfile     = $_FILES[ 'file' ][ 'tmp_name' ];
	$animated = exec( $sudobin.'gifsicle -I '.$tmpfile.' | grep -q -m1 "image #1" && echo 1 || echo 0' );
	echo $animated;
	if ( $animated ) move_uploaded_file( $tmpfile, $dirdata.'shm/local/tmp.gif' );
	break;
case 'imagereplace':
	$imagefile = $_POST[ 'imagefile' ];
	$type      = $_POST[ 'type' ];
	if ( $type === 'coverart' && ! is_writable( dirname( $imagefile ) ) ) exit( '-1' );
	
	$bookmarkname = $_POST[ 'bookmarkname' ] ?? '';
	$imagedata    = $_POST[ 'imagedata' ];
	$jpg          = substr( $imagedata, 0, 4 ) === 'data'; // animated gif passed as already uploaded tmp/file
	if ( $jpg ) {
		$tmpfile = $dirdata.'shm/local/binary';
		$base64  = preg_replace( '/^.*,/', '', $imagedata ); // data:imgae/jpeg;base64,... > ...
		file_put_contents( $tmpfile, base64_decode( $base64 ) );
	} else {
		$tmpfile = $imagedata;
	}
	$sh          = [ $type, $tmpfile, $imagefile, $bookmarkname ];
	$script      = $sudo.'/srv/http/bash/cmd-coverartsave.sh "'.escape( implode( "\n", $sh ) ).'"';
	shell_exec( $script );
	break;
case 'login':
	$file = $dirdata.'system/login';
	if ( file_exists( $file )  && ! password_verify( $_POST[ 'password' ], file_get_contents( $file ) ) ) exit( '-1' );
	
	if ( isset( $_POST[ 'disable' ] ) ) {
		unlink( $file );
		exec( $sudosettings.'features.sh logindisable' );
		exit;
	}
	
	$pwdnew = $_POST[ 'pwdnew' ] ?? '';
	if ( $pwdnew ) {
		$hash = password_hash( $pwdnew, PASSWORD_BCRYPT, [ 'cost' => 12 ] );
		file_put_contents( $file, $hash );
		exec( $sudosettings.'features.sh login' );
	} else {
		session_start();
		$_SESSION[ 'login' ] = 1;
	}
	break;
case 'logout':
	session_start();
	session_destroy();
	break;
}

function escape( $string ) {
	return preg_replace( '/(["`])/', '\\\\\1', $string );
}
