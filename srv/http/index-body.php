<?php
$svg = preg_grep( '/<rect|<path/', file( '/srv/http/assets/img/icon.svg' ) );
$logo = '<svg viewBox="0 0 180 180">'.implode( '', $svg ).'</svg>';

if ( $login && !$_SESSION[ 'login' ] ) { ?>
<style>
	#divlogin rect { fill: var( --cm ); }
	#divlogin path { fill: var( --cg75 ); }
</style>
<div id="divlogin">
	<?=$logo?><br>
	<input type="password" id="pwd"><i class="fa fa-eye"></i>
	<a id="login" class="btn btn-primary">Login</a>
</div>
<script src="assets/js/plugin/jquery-3.6.0.min.js"></script>
<script src="assets/js/info.<?=$time?>.js"></script>
<script>
$( '#pwd' ).focus();
$( '#divlogin i' ).click( function() {
	$this = $( this );
	$pwd = $( '#pwd' );
	if ( $pwd.prop( 'type' ) === 'text' ) {
		$this.removeClass( 'bl' );
		$pwd.prop( 'type', 'password' );
	} else {
		$this.addClass( 'bl' );
		$pwd.prop( 'type', 'text' );
	}
} );
$( '#login' ).click( function() {
	var pwd = $( '#pwd' ).val().replace( /(["&()\\])/g, '\$1' );
	$.post( 'cmd.php', { cmd: 'login', password: pwd }, function( data ) {
		if ( data != -1 ) {
			location.reload();
		} else {
			info( {
				  icon    : 'lock'
				, title   : 'Login'
				, message : 'Wrong password'
			} );
		}
	} );
} );
$( '#pwd' ).keypress( function( e ) {
	if ( e.which == 13 ) $( '#login' ).click();
});
</script>

</body>
</html>
<?php
	exit;
}
$dirdata = '/srv/http/data/';
$dirsystem = '/srv/http/data/system/';
$color = file_exists( $dirsystem.'color' );
// counts
$filecounts = $dirdata.'mpd/counts';
$counts = file_exists( $filecounts ) ? json_decode( file_get_contents( $filecounts ) ) : '';
// library home blocks
$modes = [ 'SD', 'USB', 'NAS', 'WebRadio', 'Album', 'Artist', 'AlbumArtist', 'Composer', 'Conductor', 'Date', 'Genre', 'Playlists', 'Latest' ];
$modehtml = '';
foreach( $modes as $mode ) {
    $modeLC = strtolower( $mode );
	$modehtml.= '
		<div class="lib-mode">
			<div id="mode-'.$modeLC.'" class="mode" data-mode="'.$modeLC.'">
				<a class="lipath">'.$mode.'</a>
				<i class="fa fa-'.$modeLC.'"></i>
				'.( $counts && $counts->$modeLC ? '<gr>'.number_format( $counts->$modeLC ).'</gr>' : '<gr></gr>' ).'
				<a class="label">'.$mode.'</a>
			</div>
		</div>
	';
}
// bookmarks
$dir = $dirdata.'bookmarks';
$files = array_slice( scandir( $dir ), 2 ); // remove ., ..
if ( count( $files ) ) {
	foreach( $files as $name ) {
		$data = file( $dir.'/'.$name, FILE_IGNORE_NEW_LINES );
		$bkpath = $data[ 0 ];
		$coverart = $data[ 1 ] ?? '';
		if ( $coverart ) {
			$coverart = substr( $coverart, 0, -3 ).$time.substr( $coverart, -4 );
			$icon = '<img class="bkcoverart" src="'.rawurlencode( $coverart ).'" data-label="'.$name.'">';
		} else {
			$icon = '<i class="fa fa-bookmark bookmark bl"></i><a class="label">'.$name.'</a>';
		}
		$modehtml.= '
			<div class="lib-mode bookmark">
				<div class="mode mode-bookmark" data-mode="bookmark">
					<a class="lipath">'.$bkpath.'</a>'
					.$icon.
				'</div>
			</div>
		';
	}
}
// context menus
function menuli( $command, $icon, $label ) {
	if ( $icon !== 'iconcover' ) $icon = 'fa fa-'.$icon;
	return '<a data-cmd="'.$command.'" class="'.$command.'"><i class="'.$icon.'"></i>'.$label.'</a>';
}
function menudiv( $id, $html ) {
	return '<div id="menu-'.$id.'" class="menu contextmenu hide">'.$html.'</div>';
}
function menucommon( $add, $replace ) {
	$htmlcommon = '<a data-cmd="'.$add.'" class="add sub"><i class="fa fa-plus-o"></i>Add</a><i class="fa fa-play-plus submenu" data-cmd="'.$add.'play"></i>';
	$htmlcommon.= '<a data-cmd="nextplay" class="nextplay"><i class="fa fa-plus-o"></i>Play next</a>';
	$htmlcommon.= '<a data-cmd="'.$replace.'" class="replace sub"><i class="fa fa-replace"></i>Replace</a><i class="fa fa-play-replace submenu" data-cmd="'.$replace.'play"></i>';
	return $htmlcommon;
}

$kid3 = file_exists( '/usr/bin/kid3-cli' );
$menulisimilar = '<a data-cmd="similar" class="similar sub"><i class="fa fa-lastfm"></i>Add similar</a><i class="fa fa-play-plus submenu" data-cmd="similar"></i>';
$menu = '<div id="contextmenu">';

$htmlcommon = menucommon( 'add', 'replace' );

$html = menuli( 'play',       'play',          'Play' );
$html.= menuli( 'pause',      'pause',         'Pause' );
$html.= menuli( 'stop',       'stop',          'Stop' );
$html.= menuli( 'current',    'check',         'Current' );
$html.= menuli( 'wrsave',     'save',          'Save to WebRadio' );
$html.= menuli( 'savedpladd', 'file-playlist', 'Add to a playlist' );
$html.= menuli( 'remove',     'minus-circle',  'Remove' );
$html.= $menulisimilar;
$html.= menuli( 'tag',        'info-circle',   'Track Info' );
$html.= menuli( 'tagcd',      'tag',           'CD Tag Editor' );
$menu.= menudiv( 'plaction', $html );

$menudiv = '';
$html = $htmlcommon;
$html.= menuli( 'bookmark',  'star',            'Bookmark' );
$html.= menuli( 'exclude',   'folder-forbid',   'Exclude directory' );
$html.= menuli( 'update',    'refresh-library', 'Update database' );
$html.= menuli( 'thumb',     'iconcover',       'Update thumbnails' );
$html.= menuli( 'directory', 'folder',          'Browse directory' );
if ( $kid3 ) $html.= menuli( 'tag', 'tag', 'Tag Editor' );
$menu.= menudiv( 'folder', $html );

$menudiv = '';
$html = menucommon( 'add', 'replace' );
$html.= $menulisimilar;
$html.= menuli( 'savedpladd', 'file-playlist', 'Add to a playlist' );
$html.= menuli( 'directory', 'folder', 'Browse directory' );
if ( $kid3 ) $html.= menuli( 'tag', 'tag', 'Tag Editor' );
$menu.= menudiv( 'file', $html );

$menudiv = '';
$html = $htmlcommon;
$menu.= menudiv( 'filepl', $html );

$menudiv = '';
$html = $htmlcommon;
$html.= menuli( 'similar',       'lastfm',        'Add similar' );
$html.= menuli( 'wrsave',        'save',          'Save to WebRadio' );
$html.= menuli( 'savedpladd',    'file-playlist', 'Add to a playlist' );
$html.= menuli( 'savedplremove', 'minus-circle',  'Remove' );
if ( $kid3 ) $html.= menuli( 'tag', 'tag', 'Tag Editor' );
$menu.= menudiv( 'filesavedpl', $html );

$menudiv = '';
$html = menucommon( 'add', 'replace' );
$menu.= menudiv( 'radio', $html );

$menudiv = '';
$html = menucommon( 'wradd', 'wrreplace' );
$html.= menuli( 'wredit',     'edit-circle',  'Edit' );
$html.= menuli( 'wrcoverart', 'iconcover',    'Change coverart' );
$html.= menuli( 'wrdelete',   'minus-circle', 'Delete' );
$menu.= menudiv( 'webradio', $html );

$menudiv = '';
$html = menucommon( 'pladd', 'plreplace' );
$html.= menuli( 'plrename', 'edit-circle',  'Rename' );
$html.= menuli( 'pldelete', 'minus-circle', 'Delete' );
$menu.= menudiv( 'playlist', $html );

$menudiv = '';
$html = '';
$html.= menuli( 'bookmark', 'star',         'Bookmark' );
$html.= menuli( 'wrdirdelete',   'minus-circle', 'Delete' );
$html.= menuli( 'wrdirrename',   'edit-circle',  'Rename' );
$menu.= menudiv( 'wrdir', $html );

foreach( [ 'album', 'albumartist', 'artist', 'composer', 'conductor', 'genre', 'date' ] as $mode ) {
	$menudiv = '';
	$html = menucommon( $mode.'add', $mode.'replace' );
	$menu.= menudiv( $mode, $html );
}
$menu.= '</div>';
$ids = [ 'random', 'repeat', 'single', 'repeat1', 'consume', 'librandom', 'mute', 'btclient', 'snapclient', 'libupdate', 'addons', 'relays', 'stoptimer' ];
$modeicon = '';
foreach( $ids as $id ) {
	$modeicon.= '<i id="i-'.$id.'" class="fa fa-'.$id.' hide"></i>';
}
if ( $localhost ) str_replace( 'library blink', 'refresh-library', $modeicon );
$timeicon = str_replace( 'i-', 'ti-', $modeicon );
?>
<div id="bar-top" class="hide">
	<i id="logo" class="fa fa-plus-r-nobox"></i>
	<i id="button-settings" class="fa fa-gear"></i>
	<div id="playback-controls">
		<i id="previous" class="btn btn-default btn-cmd fa fa-previous"></i>
		<i id="stop" class="btn btn-default btn-cmd fa fa-stop"></i>
		<i id="play" class="btn btn-default btn-cmd fa fa-play"></i>
		<i id="pause" class="btn btn-default btn-cmd fa fa-pause"></i>
		<i id="next" class="btn btn-default btn-cmd fa fa-next"></i>
	</div>
</div>
<div id="settings" class="menu hide">
	<a id="features" class="settings"><i class="fa fa-features"></i>Features</a>
		<i id="lock" class="fa fa-lock submenu"></i>
	<a id="player" class="settings"><i class="fa fa-player"></i>Player</a>
		<i id="equalizer" class="fa fa-equalizer submenu"></i>
	<a id="networks" class="settings"><i class="fa fa-networks"></i>Networks</a>
		<i id="snapclient" class="fa fa-snapclient submenu"></i>
	<a id="system" class="settings"><i class="fa fa-plus-r"></i>System</a>
		<i id="relays" class="fa fa-relays submenu"></i>
	<a id="addons" class="sub"><i class="fa fa-jigsaw"></i>Addons</a>
		<i id="guide" class="fa fa-question-circle submenu"></i>
	<a id="power"><i class="fa fa-power"></i>Power</a>
		<i id="screenoff" class="fa fa-screenoff submenu"></i>
	<a id="displaylibrary" class="sub"><i class="fa fa-library"></i>Library</a>
		<i id="update" class="fa fa-refresh-library submenu"></i>
	<a id="displayplayback" class="sub"><i class="fa fa-playback"></i>Playback</a>
		<i id="displaycolor" class="submenu"><canvas id="iconrainbow"></canvas></i>
	<a id="displayplaylist"><i class="fa fa-playlist"></i>Playlist</a>
		<i id="switchraudio" class="fa fa-raudiobox submenu"></i>
</div>
<div id="page-playback" class="page">
	<div class="emptyadd hide"><i class="fa fa-plus-circle"></i></div>
	<i id="guide-bio" class="map guide fa fa-bio hide"></i>
	<i id="guide-lyrics" class="map guide fa fa-lyrics hide"></i>
	<i id="guide-album" class="map guide fa fa-lastfm hide"></i>
	<div id="info">
		<div id="divartist">
			<span id="artist"></span>
		</div>
		<div id="divtitle">
			<span id="title"></i></span>
		</div>
		<div id="divalbum">
			<span id="album"></span>
		</div>
		<div id="infoicon">
			<i id="playericon"></i>
			<span id="progress"></span>
			<span id="modeicon"><?=$modeicon?></span>
		</div>
		<div id="sampling"></div>
	</div>
	<div id="playback-row" class="row">
		<div id="time-knob" class="hide">
			<div id="time"></div>
			<div id="timeicon"><?=$timeicon?></div>
			<span id="elapsed" class="controls1"></span>
			<span id="total" class="controls1"></span>
			<div id="timemap">
				<i id="timeTL" class="map timemap"></i>
				<i id="timeT" class="map timemap fa fa-guide"></i>
				<i id="timeTR" class="map timemap fa fa-gear"></i>
				<i id="timeL" class="map timemap fa fa-previous"></i>
				<div id="timeM" class="map timemap"><i class="fa fa-play"></i>&nbsp;<i class="fa fa-pause"></i></div>
				<i id="timeR" class="map timemap fa fa-next"></i>
				<i id="timeBL" class="map timemap fa fa-random"></i>
				<i id="timeB" class="map timemap fa fa-stop"></i>
				<i id="timeBR" class="map timemap fa fa-repeat"></i>
			</div>
			<div id="play-group">
				<div class="btn-group">
					<i id="random" class="btn btn-default btn-cmd btn-toggle fa fa-random"></i>
					<i id="single" class="btn btn-default btn-cmd btn-toggle fa fa-single"></i>
					<i id="repeat" class="btn btn-default btn-cmd btn-toggle fa fa-repeat"></i>
				</div>
			</div>
		</div>
		<div id="coverart-block" class="hide">
			<div id="divcover" class="cover">
				<div id="time-bar"></div>
				<div id="time-band" class="band transparent"></div>
				<img id="coverart" src="" class="cover hide">
				<div id="vu" class="hide">
					<?php include 'assets/img/vu.svg';?>
				</div>
				<div id="qrwebui" class="qr hide"></div>
				<div id="qrip" class="qr hide"></div>
				<div id="covermap">
					<i id="coverTL" class="map covermap r1 c1 ws hs fa fa-scale-dn"></i>
					<i id="coverT" class="map covermap r1 c2 wl hs fa fa-guide"></i>
					<i id="coverTR" class="map covermap r1 c3 ws hs fa fa-gear"></i>
					<i id="coverL" class="map covermap r2 c1 ws hl fa fa-previous"></i>
					<div id="coverM" class="map covermap r2 c2 wl hl"><i class="fa fa-play"></i>&emsp;<i class="fa fa-pause"></i></div>
					<i id="coverR" class="map covermap r2 c3 ws hl fa fa-next"></i>
					<i id="coverBL" class="map covermap r3 c1 ws hs fa fa-random"></i>
					<i id="coverB" class="map covermap r3 c2 wl hs fa fa-stop"></i>
					<i id="coverBR" class="map covermap r3 c3 ws hs fa fa-repeat"></i>
				</div>
				<div id="volume-bar" class="hide"></div>
				<i id="volume-band" class="volumeband band fa fa-volume transparent"></i>
				<i id="volume-band-dn" class="volumeband band fa fa-minus transparent"></i>
				<i id="volume-band-up" class="volumeband band fa fa-plus transparent"></i>
				<div id="volume-text" class="hide"></div>
			</div>
		</div>
		<div id="volume-knob" class="hide">
			<div id="volume"></div>
			<div id="volmap">
				<i id="volT" class="map volmap fa fa-plus"></i>
				<i id="volL" class="map volmap fa fa-minus"></i>
				<i id="volM" class="map volmap fa fa-volume"></i>
				<i id="volR" class="map volmap fa fa-plus"></i>
				<i id="volB" class="map volmap fa fa-minus"></i>
			</div>
			<div id="vol-group">
				<div class="btn-group">
					<i id="voldn" class="btn btn-default fa fa-minus"></i>
					<i id="volmute" class="btn btn-default fa fa-volume"></i>
					<i id="volup" class="btn btn-default fa fa-plus"></i>
				</div>
			</div>
		</div>
	</div>
</div>

<div id="page-library" class="page hide">
	<div class="content-top">
		<i id="button-library" class="fa fa-library active"></i>
		<i id="button-lib-search" class="fa fa-search"></i>
		<div id="lib-search" class="hide">
			<div class="input-group">
				<input id="lib-search-input" type="text">
				<span class="input-group-btn">
					<button id="lib-search-btn" class="btn btn-default"><i class="fa fa-search"></i></button>
				</span>
			</div>
		</div>
		<div id="lib-search-close"></div>
		<div id="lib-path">
			<i id="button-lib-back" class="fa fa-arrow-left"></i>
			<div id="lib-title"><span class="title">LIBRARY</span><span id="li-count"><?=( number_format( $counts->song ) )?><i class="fa fa-music gr"></i></span></div>
			<div id="lib-breadcrumbs">
			</div>
			<span class="lipath"></span>
		</div>
	</div>
	<div id="lib-mode-list"><?=$modehtml?></div>
	<ul id="lib-list" class="list"></ul>
	<div id="lib-index" class="index index0"></div>
	<div id="lib-index1" class="index index1"></div>
</div>

<div id="page-playlist" class="page hide">
	<div class="emptyadd hide"><i class="fa fa-plus-circle"></i></div>
	<div class="content-top">
		<span id="pl-path"></span>
		<i id="button-playlist" class="fa fa-playlist active"></i>
		<i id="button-pl-back" class="fa fa-arrow-left hide"></i>
		<i id="button-pl-search" class="fa fa-search pllength"></i>
		<form id="pl-search" class="hide" method="post" onSubmit="return false;">
			<div class="input-group">
				<input id="pl-search-input" type="text">
				<span class="input-group-btn">
					<button id="pl-search-btn" class="btn btn-default" type="button"><i class="fa fa-search"></i></button>
				</span>
			</div>
		</form>
		<div id="pl-search-close" class="hide"></div>
		<div id="pl-manage" class="playlist">
			<i id="button-pl-playlists" class="fa fa-playlists"></i>
			<i id="button-pl-save" class="fa fa-save pllength"></i>
			<i id="button-pl-consume" class="fa fa-flash"></i>
			<i id="button-pl-librandom" class="fa fa-librandom"></i>
			<i id="button-pl-shuffle" class="fa fa-shuffle pllength"></i>
			<i id="button-pl-clear" class="fa fa-minus-circle pllength"></i>
		</div>
	</div>
	<ul id="pl-list" class="list playlist"></ul>
	<ul id="pl-savedlist" class="list hide"></ul>
	<div id="pl-index" class="index index0"></div>
	<div id="pl-index1" class="index index1"></div>
</div>

<?=$menu?>

<div id="colorpicker" class="hide">
	<div id="divcolor">
	<i id="colorcancel" class="fa fa-times"></i>
	<a id="colorreset" class="infobtn"><i class="fa fa-set0"></i> Default</a>&ensp;
	<a id="colorok" class="infobtn infobtn-primary">OK</a>
	</div>
</div>
<div id="bio" class="hide">
	<div class="container">
		<img id="biobanner">
		<div id="bioimg"></div>
		<div id="biocontent"></div>
	</div>
</div>
<div id="lyrics" class="hide">
	<div id="divlyricstitle">
		<img src="">
		<span id="lyricstitle"></span>
		<i id="lyricsclose" class="fa fa-times"></i>
	</div>
	<div id="divlyricsartist">
		<span id="lyricsartist"></span><i id="lyricsedit" class="fa fa-edit-circle"></i>
		<div id="lyricseditbtngroup" class="hide">
			<i id="lyricsundo" class="fa fa-undo hide"></i>
			<i id="lyricssave" class="fa fa-save hide"></i>
			<i id="lyricsdelete" class="fa fa-minus-circle"></i>
			<i id="lyricsback" class="fa fa-arrow-left bl"></i>
		</div>
	</div>
	<div id="lyricstext" class="lyricstext"></div>
	<textarea id="lyricstextarea" class="lyricstext"></textarea>
	<div id="lyricsfade"></div>
</div>
<div id="bar-bottom" class="transparent"> <!-- keep single line to suppress spaces -->
	<i id="library" class="fa fa-library"></i><i id="playback" class="fa fa-playback"></i><i id="playlist" class="fa fa-playlist"></i>
</div>
<div id="loader" class="splash">
	<?=$logo?>
</div>
