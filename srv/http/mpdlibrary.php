<?php
/*
find, list, ls, search, track, webradio

Album
	/srv/http/data/mpd/album: album-artist^-file
	/srv/http/data/mpd/albumbyartist: artist-album-file
			track list: mpc ls -f %*% $path
Artist
	mpc list artist > /srv/http/data/mpd/artist
		album list: mpc find -f %artist%^^%album% artist $artist
			track list: mpc find -f %*% album $album artist $artist
AlbumArtist
	mpc list albumartist > /srv/http/data/mpd/albumartist
		album list: mpc find -f %albumartist%^^%album% albumartist $albumartist
			track list: mpc find -f %*% album $album albumartist $albumartist
Composer
	mpc list composer > /srv/http/data/mpd/composer
		album list: mpc find -f %composer%^^%album% composer $composer
			track list: mpc find -f %*% album $album composer $composer
Conductor
	mpc list conductor > /srv/http/data/mpd/conductor
		album list: mpc find -f %conductor%^^%album% conductor $conductor
			track list: mpc find -f %*% album $album conductor $conductor
Genre
	mpc list genre > /srv/http/data/mpd/genre
		artist-album list: mpc find -f %artist%^^%album% genre $genre
			track list: mpc find -f %*% album $album artist $artist
Date
	mpc list date > /srv/http/data/mpd/date
		artist-album list: mpc find -f %artist%^^%album% date $date
			track list: mpc find -f %*% album $album artist $artist
File
	mpc ls -f %file% $path
			track list: mpc ls -f %*% $path
search
			track list: mpc search -f %*% any $keyword
*/
include '/srv/http/function.php';
include '/srv/http/bash/cmd-listsort.php';

$gmode     = $_POST[ 'gmode' ] ?? null;
$mode      = $_POST[ 'mode' ] ?? null;
$string    = $_POST[ 'string' ] ?? null;
$string    = escape( $string );
$formatall = [ 'album', 'albumartist', 'artist', 'composer', 'conductor', 'date', 'file', 'genre', 'time', 'title', 'track' ];
$f         = $_POST[ 'format' ] ?? $formatall;
$format    = '%'.implode( '%^^%', $f ).'%';
$html      = '<ul id="lib-list" class="list">';

switch( $_POST[ 'query' ] ) {

case 'find':
	$format = str_replace( '%artist%', '[%artist%|%albumartist%]', $format );
	if ( is_array( $mode ) ) {
		exec( 'mpc -f %file% find '.$mode[ 0 ].' "'.$string[ 0 ].'" '.$mode[ 1 ].' "'.$string[ 1 ].'" 2> /dev/null'." \
				| awk -F'/[^/]*$' 'NF && !/^\^/ && !a[$0]++ {print $1}' | sort -u"
			, $dirs );
		if ( count( $dirs ) > 1 ) {
			htmlDirectory( $dirs );
			break;
			
		} else {
			$file = $dirs[ 0 ];
			if ( substr( $file, -14, 4 ) !== '.cue' ) {
				exec( 'mpc find -f "'.$format.'" '.$mode[ 0 ].' "'.$string[ 0 ].'" '.$mode[ 1 ].' "'.$string[ 1 ].'" 2> /dev/null'." \
						| awk 'NF && !a[$0]++'"
					, $lists );
				if ( ! count( $lists ) ) { // find with albumartist
					exec( 'mpc find -f "'.$format.'" '.$mode[ 0 ].' "'.$string[ 0 ].'" albumartist "'.$string[ 1 ].'" 2> /dev/null'." \
							| awk 'NF && !a[$0]++'"
						, $lists );
				}
			} else { // $file = '/path/to/file.cue/track0001'
				$format = '%'.implode( '%^^%', $f ).'%';
				exec( 'mpc -f "'.$format.'" playlist "'.dirname( $file ).'"'
					, $lists );
			}
		}
	} else {
		exec( 'mpc find -f "'.$format.'" '.$mode.' "'.$string.'" 2> /dev/null'." \
				| awk 'NF && !a[$0]++'"
			, $lists );
	}
	if ( count( $f ) > 2 ) {
		htmlTrack( $lists, $f );
	} else { // modes - album, artist, albumartist, composer, conductor, genre: 2 fields format
		htmlFind( $lists, $f );
	}
	break;
case 'home':
	$modes    = [ 'Album', 'Artist', 'Album Artist', 'Composer', 'Conductor', 'Date', 'Genre', 'Latest'
				, 'NAS', 'SD', 'USB', 'Playlists', 'Web Radio', 'DAB Radio' ];
	$htmlmode = '';
	foreach( $modes as $mode ) {
		$lipath   = str_replace( ' ', '', $mode );
		$modeLC   = strtolower( $lipath );
		$htmlmode.= <<< EOF
<div class="lib-mode">
	<div id="mode-$modeLC" class="mode" data-mode="$modeLC">
	<a class="lipath">$modeLC</a>
	<i class="fa fa-$modeLC"></i><gr></gr><a class="label">$mode</a>
	</div>
</div>
EOF;
	}
	// bookmarks
	$dir   = '/srv/http/data/bookmarks';
	$files = array_slice( scandir( $dir ), 2 ); // remove ., ..
	if ( count( $files ) ) {
		foreach( $files as $name ) {
			$data     = file( $dir.'/'.str_replace( '|', '/', $name ), FILE_IGNORE_NEW_LINES );
			$bkpath   = $data[ 0 ];
			$coverart = $data[ 1 ] ?? '';
			if ( $coverart ) {
				$icon = '<img class="bkcoverart" src="'.rawurlencode( $coverart ).'^^^" data-label="'.$name.'">';
			} else {
				$icon = '<i class="fa fa-bookmark bookmark bl"></i><a class="label">'.$name.'</a>';
			}
			$htmlmode.= <<< EOF
<div class="lib-mode bookmark">
	<div class="mode mode-bookmark" data-mode="bookmark"><a class="lipath">$bkpath</a>$icon</div>
</div>
EOF;
		}
	}
	echo $htmlmode;
	break;
case 'list':
	$filemode = '/srv/http/data/mpd/'.$mode;
	if ( $mode === 'album' && exec( 'grep "albumbyartist.*true" /srv/http/data/system/display' ) ) $filemode.= 'byartist';
	$lists    = file( $filemode, FILE_IGNORE_NEW_LINES );
	htmlList( $lists );
	break;
case 'ls':
	if ( $mode !== 'album' ) {
		exec( 'mpc ls "'.$string.'"'
			, $mpcls );
		foreach( $mpcls as $mpdpath ) {
			if ( is_dir( '/mnt/MPD/'.$mpdpath ) ) {
				$subdirs = 1;
				break;
			}
		}
	}
	if ( isset( $subdirs ) ) {
		exec( 'mpc ls -f %file% "'.$string.'" 2> /dev/null'
			, $lists );
		$count = count( $lists );
		if ( ! $count ) exit( '-1' );
		
		htmlDirectory( $lists );
	} else {
		$f      = $formatall; // set format for directory with files only - track list
		$format = '%'.implode( '%^^%', $f ).'%';
		// parse if cue|m3u,|pls files (sort -u: mpc ls list *.cue twice)
		exec( 'mpc ls "'.$string.'" | grep -E ".cue$|.m3u$|.m3u8$|.pls$" | sort -u'
			, $plfiles );
		if ( count( $plfiles ) ) {
			asort( $plfiles );
			$path  = explode( '.', $plfiles[ 0 ] );
			$ext   = end( $path );
			$lists = [];
			foreach( $plfiles as $file ) {
				$type = $ext === 'cue' ? 'ls' : 'playlist';
				exec( 'mpc -f "'.$format.'" '.$type.' "'.$file.'"'
					, $lists ); // exec appends to existing array
			}
			htmlTrack( $lists, $f, $ext, $file );
		} else {
			exec( 'mpc ls -f "'.$format.'" "'.$string.'" 2> /dev/null'
				, $lists );
			if ( strpos( $lists[ 0 ],  '.wav^^' ) ) { // MPD not sort *.wav
				$lists = '';
				exec( 'mpc ls -f "%track%__'.$format.'" "'.$string.'" 2> /dev/null | sort -h | sed "s/^.*__//"'
					, $lists );
			}
			htmlTrack( $lists, $f, $mode !== 'album' ? 'file' : '' );
		}
	}
	break;
case 'radio':
	$dir     = '/srv/http/data/'.$gmode.'/';
	$subdirs = [];
	$files   = [];
	$indexes = [];
	if ( $mode === 'search' ) {
		$searchmode = 1;
		exec( "grep -ril --exclude-dir=img '".$string."' ".$dir." | sed 's|^".$dir."||'"
			, $files );
	} else {
		$searchmode = 0;
		$dir.= $string;
		exec( 'ls -1 "'.$dir.'" | grep -E -v "^img|\.jpg$|\.gif$"'
			, $lists );
		if ( ! count( $lists ) ) exit();
		
		foreach( $lists as $list ) {
			if ( is_dir( $dir.'/'.$list ) ) {
				$subdirs[] = $list;
			} else {
				$files[] = $list;
			}
		}
	}
	htmlRadio( $subdirs, $files, $dir );
	break;
case 'search':
	exec( 'mpc search -f "'.$format.'" any "'.$string.'" \
			| awk NF'
		, $lists );
	htmlTrack( $lists, $f, 'search', $string );
	break;
case 'track': // for tag editor
	$file  = escape( $_POST[ 'file' ] );
	if ( is_dir( '/mnt/MPD/'.$file ) ) {
		$wav = exec( 'mpc ls "'.$file.'" | grep -m1 "\.wav$"' ); // MPD not read albumartist in *.wav
		if ( $wav ) {
			$albumartist = exec( 'kid3-cli -c "get albumartist" "'.$wav.'"' );
			if ( $albumartist ) $format = str_replace( '%albumartist%', $albumartist, $format );
		}
		exec( 'mpc ls -f "'.$format.'" "'.$file.'"'
			, $lists );
		// format: [ 'album', 'albumartist', 'artist', 'composer', 'conductor', 'genre', 'date' ]
		foreach( $lists as $list ) {
			$each = explode( '^^', $list );
			$artist[]    = $each[ 2 ];
			$composer[]  = $each[ 3 ];
			$conductor[] = $each[ 4 ];
			$genre[]     = $each[ 5 ];
			$date[]      = $each[ 6 ];
			$array[]     = $each;
		}
		$array = $array[ 0 ];
		if ( count( array_unique( $artist ) )    > 1 ) $array[ 2 ] = '*';
		if ( count( array_unique( $composer ) )  > 1 ) $array[ 3 ] = '*';
		if ( count( array_unique( $conductor ) ) > 1 ) $array[ 4 ] = '*';
		if ( count( array_unique( $genre ) )     > 1 ) $array[ 5 ] = '*';
		if ( count( array_unique( $date ) )      > 1 ) $array[ 6 ] = '*';
	} else {
		// MPD not read albumartist in *.wav
		if ( substr( $file, -3 ) === 'wav' ) {
			$albumartist = exec( 'kid3-cli -c "get albumartist" "/mnt/MPD/'.$file.'"' );
			if ( $albumartist ) $format = str_replace( '%albumartist%', $albumartist, $format );
		}
		$lists = exec( 'mpc ls -f "'.$format.'" "'.$file.'"' );
		$array = explode( '^^', $lists );
	}
	echo json_encode( $array );
	break;
}

//-------------------------------------------------------------------------------------
function escape( $string ) { // for passing bash arguments
	return preg_replace( '/(["`])/', '\\\\\1', $string );
}
function htmlDirectory( $lists ) {
	global $gmode;
	global $html;
	foreach( $lists as $list ) {
		$dir        = basename( $list );
		$each       = ( object )[];
		$each->path = $list;
		$each->dir  = $dir;
		$each->sort = stripSort( $dir );
		$array[]    = $each;
	}
	usort( $array, function( $a, $b ) {
		return strnatcasecmp( $a->sort, $b->sort );
	} );
	foreach( $array as $each ) {
		$path      = $each->path;
		$index     = strtoupper( mb_substr( $each->sort, 0, 1, 'UTF-8' ) );
		$indexes[] = $index;
		if ( is_dir( '/mnt/MPD/'.$path ) ) {
			$mode     = strtolower( explode( '/', $path )[ 0 ] );
			$thumbsrc = rawurlencode( '/mnt/MPD/'.$path.'/thumb.jpg' );
			$htmlicon = '<img class="lazyload iconthumb lib-icon" data-src="'.$thumbsrc.'^^^" data-target="#menu-folder">';
		} else {
			$mode     = $gmode;
			$htmlicon = '<i class="lib-icon fa fa-music" data-target="#menu-file"></i>';
		}
		$html.= <<< EOF
<li data-mode="$mode" data-index="$index">$htmlicon
<a class="lipath">$path</a>
<span class="single">$each->dir</span>
</li>
EOF;
	}
	$indexbar = indexbar( array_keys( array_flip( $indexes ) ) );
	$html    .= <<< EOF
	<p></p>
</ul>
<div id="lib-index" class="index index0">$indexbar[0]</div>
<div id="lib-index1" class="index index1">$indexbar[1]</div>
EOF;
	echo $html;
}
function htmlFind( $lists, $f ) { // non-file 'find' command
	if ( ! count( $lists ) ) exit( '-1' );
	
	global $mode;
	global $gmode;
	global $html;
	$fL = count( $f );
	foreach( $lists as $list ) {
		if ( $list === '' ) continue;
		
		$list = explode( '^^', $list ); // album^^artist 
		$each = ( object )[];
		for ( $i = 0; $i < $fL; $i++ ) {
			$key        = $f[ $i ];
			$each->$key = $list[ $i ];
			$each->sort = stripSort( $list[ 0 ] ).stripSort( $list[ 1 ] );
		}
		if ( isset( $list[ $fL ] ) ) $each->path = $list[ $fL ];
		$array[] = $each;
	}
	usort( $array, function( $a, $b ) {
		return strnatcasecmp( $a->sort, $b->sort );
	} );
	foreach( $array as $each ) {
		if ( count( $f ) > 1 ) {
			$date_genre = in_array( $gmode, [ 'date', 'genre' ] );
			$key0       = $date_genre ? $f[ 1 ] : $f[ 0 ];
			$key1       = $date_genre ? $f[ 0 ] : $f[ 1 ];
			$val0       = $each->$key0;
			$val1       = $each->$key1;
			$name       = $date_genre ? $val1.'<gr> • </gr>'.$val0 : $val0.'<gr> • </gr>'.$val1;
		} else {
			$key0       = $f[ 0 ];
			$val0       = $each->$key0;
			$val1       = '';
			$name       = $val0;
		}
		if ( ! $val0 && ! $val1 ) continue;
		
		$index     = strtoupper( mb_substr( $each->sort, 0, 1, 'UTF-8' ) );
		$indexes[] = $index;
		if ( property_exists( $each, 'path' ) ) { // cue //////////////////////////
			$path     = $each->path;
			$datamode = $mode;
		} else {
			$path     = $val1;
			$datamode = 'album';
		} // cue //////////////////////////////////////////////////////////////////
		$html     .= <<< EOF
<li data-mode="$datamode" data-index="$index">
	<a class="liname">$val0</a>
	<i class="fa fa-album lib-icon" data-target="#menu-album"></i><span class="single">$name</span>
</li>
EOF;
	}
	$indexbar = indexbar( array_keys( array_flip( $indexes ) ) );
	$html    .= <<< EOF
	<p></p>
</ul>
<div id="lib-index" class="index index0">$indexbar[0]</div>
<div id="lib-index1" class="index index1">$indexbar[1]</div>
EOF;
	echo $html;
}
function htmlList( $lists ) { // non-file 'list' command
	if ( ! count( $lists ) ) exit( '-1' );
	
	global $mode;
	global $gmode;
	global $html;
	if ( $mode === 'latest' ) $mode = 'album';
	if ( $mode !== 'album' ) {
		foreach( $lists as $list ) {
			$data      = explode( '^^', $list );
			$index     = strtoupper( $data[ 0 ] );
			$indexes[] = $index;
			$name      = $data[ 1 ];
			$html     .= <<< EOF
<li data-mode="$mode" data-index="$index">
	<a class="lipath">$name</a>
	<i class="fa fa-$gmode lib-icon" data-target="#menu-$mode"></i><span class="single">$name</span>
</li>
EOF;
		}
	} else {
		foreach( $lists as $list ) {
			$data      = explode( '^^', $list );
			$index     = strtoupper( $data[ 0 ] );
			$indexes[] = $index;
			$path      = $data[ 3 ];
			if ( substr( $path, -4 ) === '.cue' ) $path = dirname( $path );
			$coverfile = rawurlencode( '/mnt/MPD/'.$path.'/coverart.jpg' ); // replaced with icon on load error(faster than existing check)
			$space     = $data[ 2 ] ?: '&nbsp;';
			$html     .= <<< EOF
<div class="coverart" data-index="$index">
	<a class="lipath">$path</a>
	<div><img class="lazyload" data-src="$coverfile^^^"></div>
	<span class="coverart1">$data[1]</span>
	<gr class="coverart2">$space</gr>
</div>
EOF;
		}
	}
	$indexbar = indexbar( array_keys( array_flip( $indexes ) ) ); // faster than array_unique
	$html    .= <<< EOF
	<p></p>
</ul>
<div id="lib-index" class="index index0">$indexbar[0]</div>
<div id="lib-index1" class="index index1">$indexbar[1]</div>
EOF;
	echo $html;
}
function htmlRadio( $subdirs, $files, $dir ) {
	global $mode;
	global $gmode;
	global $html;
	if ( count( $subdirs ) ) {
		foreach( $subdirs as $subdir ) {
			$each         = ( object )[];
			$each->subdir = $subdir;
			$each->sort   = stripSort( $subdir );
			$array[]      = $each;
		}
		usort( $array, function( $a, $b ) {
			return strnatcasecmp( $a->sort, $b->sort );
		} );
		$path = str_replace( '/srv/http/data/'.$gmode.'/', '', $dir );  // /srv/http/data/webradio/path/to > path/to 
		if ( $path ) $path.= '/';
		foreach( $array as $each ) {
			$subdir = $each->subdir;
			if ( count( $files ) ) {
				$html     .= '<li class="dir">';
			} else {
				$index     = strtoupper( mb_substr( $each->sort, 0, 1, 'UTF-8' ) );
				$indexes[] = $index;
				$html     .= '<li class="dir" data-index="'.$index.'">';
			}
			$thumbsrc = rawurlencode( "/data/$gmode/$subdir/thumb.jpg" );
			$html    .= <<< EOF
	<img class="lazyload iconthumb lib-icon" data-src="$thumbsrc^^^" data-target="#menu-wrdir">
	<a class="lipath">$path$subdir</a>
	<span class="single">$subdir</span>
</li>
EOF;
		}
	}
	if ( count( $files ) ) {
		unset( $array );
		foreach( $files as $file ) {
			$each          = ( object )[];
			$data          = file( "$dir/$file", FILE_IGNORE_NEW_LINES );
			$name          = $data[ 0 ];
			$each->charset = $data[ 2 ] ?? '';
			$each->name    = $name;
			$each->url     = str_replace( '|', '/', $file );
			$each->sort    = stripSort( $name );
			$array[]       = $each;
		}
		usort( $array, function( $a, $b ) {
			return strnatcasecmp( $a->sort, $b->sort );
		} );
		foreach( $array as $each ) {
			$index       = strtoupper( mb_substr( $each->sort, 0, 1, 'UTF-8' ) );
			$indexes[]   = $index;
			$datacharset = $each->charset ? ' data-charset="'.$each->charset.'"' : '';
			$url         = $each->url;
			$urlname     = str_replace( '/', '|', $url );
			$thumbsrc    = '/data/'.$gmode.'/img/'.rawurlencode( $urlname ).'-thumb.jpg';
			$liname      = $each->name;
			$name        = $searchmode ? preg_replace( "/($string)/i", '<bl>$1</bl>', $liname ) : $liname;
			$html       .= <<< EOF
<li class="file"$datacharset data-index="$index">
	<img class="lazyload iconthumb lib-icon" data-src="$thumbsrc^^^" data-target="#menu-webradio">
	<a class="lipath">$url</a>
	<a class="liname">$liname</a>
EOF;
			if ( $gmode === 'webradio' ) {
				$html.= '<div class="li1">'.$name.'</div><div class="li2">'.$url.'</div>';
			} else {
				$html.= '<span class="single">'.$name.'</span>';
			}
			$html.= '</li>';
		}
	}
	$html.= '<p></p></ul>';
	if ( $mode !== 'search' ) {
		$indexbar = indexbar( array_keys( array_flip( $indexes ) ) );
		$html.= <<< EOF
<div id="lib-index" class="index index0">$indexbar[0]</div>
<div id="lib-index1" class="index index1">$indexbar[1]</div>
EOF;
	}
	echo $html;
}
function htmlTrack( $lists, $f, $filemode = '', $string = '', $dirs = '' ) { // track list - no sort ($string: cuefile or search)
	if ( ! count( $lists ) ) exit( '-1' );
	
	global $mode;
	global $gmode;
	global $html;
	$fL = count( $f );
	foreach( $lists as $list ) {
		if ( $list === '' ) continue;
		
		$list = explode( '^^', $list );
		$each = ( object )[];
		for ( $i = 0; $i < $fL; $i++ ) {
			$key        = $f[ $i ];
			$each->$key = $list[ $i ];
		}
		$array[] = $each;
	}
	$each0      = $array[ 0 ];
	$file0      = $each0->file;
	$ext        = pathinfo( $file0, PATHINFO_EXTENSION );
	
	$hidecover  = exec( 'grep "hidecover.*true" /srv/http/data/system/display' );
	$searchmode = $filemode === 'search';
	$cuefile    = preg_replace( "/\.[^.]+$/", '.cue', $file0 );
	if ( file_exists( '/mnt/MPD/'.$cuefile ) ) {
		$cue       = true;
		$cuename   = pathinfo( $cuefile, PATHINFO_BASENAME );
		$musicfile = exec( 'mpc ls "'.dirname( $cuefile ).'" | grep -v ".cue$" | head -1' );
		$ext       = pathinfo( $musicfile, PATHINFO_EXTENSION );
	} else {
		$cue = false;
	}
	if ( ! $hidecover && ! $searchmode ) {
		if ( $ext !== 'wav' ) {
			$albumartist = $each0->albumartist;
		} else { // fix - mpd cannot read albumartist from *.wav
			$albumartist = exec( 'kid3-cli -c "get albumartist" "/mnt/MPD/'.$file0.'"' );
		}
		$album  = $each0->album;
		$artist = $albumartist ?: '';
		$icon   = 'albumartist';
		if ( ! $artist ) {
			$artist = $each0->artist;
			$icon = 'artist';
		}
		$hidealbum     = $album && $gmode !== 'album' ? '' : ' hide';
		$hideartist    = $artist && $gmode !== 'artist' && $gmode !== 'albumartist' ? '' : ' hide';
		$hidecomposer  = $each0->composer && $gmode !== 'composer' ? '' : ' hide';
		$hideconductor = $each0->conductor && $gmode !== 'conductor' ? '' : ' hide';
		$hidegenre     = $each0->genre && $gmode !== 'genre' ? '' : ' hide';
		$hidedate      = $each0->date && $gmode !== 'date' ? '' : ' hide';
		$mpdpath       = $dirs ? dirname( $dirs[ 0 ] ) : dirname( $file0 );
		$plfile        = exec( 'mpc ls "'.$mpdpath.'" 2> /dev/null | grep -E ".m3u$|.m3u8$|.pls$"' );
		if ( $cue || $plfile ) {
			$plicon = '&emsp;<i class="fa fa-file-playlist"></i><gr>'
					 .( $cue ? 'cue' : pathinfo( $plfile, PATHINFO_EXTENSION ) ).'</gr>';
		} else {
			$plicon = '';
		}
		$hhmmss        = array_column( $array, 'time' );
		$seconds       = 0;
		foreach( $hhmmss as $hms ) $seconds += HMS2second( $hms ); // hh:mm:ss > seconds
		$totaltime     = second2HMS( $seconds );
		$args          = escape( implode( "\n", [ $artist, $album, $mpdpath ] ) );
		$coverart      = exec( '/usr/bin/sudo /srv/http/bash/status-coverart.sh "'.$args.'"' );
		$br            = ! $hidegenre || !$hidedate ? '<br>' : '';
		$mpdpath       = str_replace( '\"', '"', $mpdpath );
		$count         = count( $array );
		$ext           = strtoupper( $ext ).$plicon;
		$html         .= <<< EOF
<li data-mode="$gmode" class="licover">
	<a class="lipath">$mpdpath</a>
	<div class="licoverimg"><img id="liimg" src="$coverart^^^"></div>
	<div class="liinfo $gmode">
	<div class="lialbum$hidealbum">$album</div>
	<div class="liartist$hideartist"><i class="fa fa-$icon"></i>$artist</div>
	<div class="licomposer$hidecomposer"><i class="fa fa-composer"></i>$each0->composer</div>
	<div class="liconductor$hideconductor"><i class="fa fa-conductor"></i>$each0->conductor</div>
	<span class="ligenre$hidegenre"><i class="fa fa-genre"></i>$each0->genre&emsp;</span>
	<span class="lidate$hidedate"><i class="fa fa-date"></i>$each0->date</span>
	$br
	<div class="liinfopath"><i class="fa fa-folder"></i>$mpdpath</div>
	<i class="fa fa-music lib-icon" data-target="#menu-folder"></i>$count<gr> • </gr>$totaltime<gr> • </gr>$ext
	</div>
</li>
EOF;
	}
	$i = 0;
	foreach( $array as $each ) {
		if ( ! $each->time ) continue;
		
		$path   = $each->file;
		$album  = $each->album;
		$artist = $each->artist;
		$title  = $each->title;
		if ( $searchmode ) {
			$name      = $artist.' - '.$album;
			$title     = preg_replace( "/($string)/i", '<bll>$1</bll>', $title );
			$trackname = preg_replace( "/($string)/i", '<bll>$1</bll>', $name );
		} else {
			$trackname = $cue ? $cuename.'/' : '';
			$trackname.= basename( $path );
		}
		if ( ! $title ) $title = pathinfo( $each->file, PATHINFO_FILENAME );
		$li0    = ( $i || $searchmode || $hidecover ) ? '' : ' class="track1"';
		$i++;
		$html  .= <<< EOF
<li data-mode="$gmode" $li0>
	<a class="lipath">$path</a>
	<i class="fa fa-music lib-icon" data-target="#menu-file"></i><div class="li1">$title<span class="time">$each->time</span></div>
	<div class="li2">$i • $trackname</div>
</li>
EOF;
	}
	echo $html.'<p></p></ul>';
}
