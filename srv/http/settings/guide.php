<style>
.container { padding: 40px 0 0 0 }
#guide {
	width: 100%;
	height: 100%;
	left: 0;
	right: 0;
	margin: 0 auto;
	user-select: none;
}
.helpblock { margin: 0 }
#guide .bottom-bar {
	height: 33px;
	background: var( --cga );
}
#guide p {
	margin: 0;
	line-height: 40px;
}
#guide a {
	display: inline-block;
	width: 20%;
	line-height: 33px;
	padding-right: 5px;
	text-align: center;
	cursor: pointer;
}
#guide i {
	width: 33px;
	vertical-align: -2px;
	font-size: 20px;
	text-align: center;
}
#guide a.active { background-color: var( --cm ) !important }
#guide img { width: 100% }
#prevnext { padding-right: 0 !important }
@media ( max-width: 450px ) {
	#guide a span { display: none }
}
</style>

<p class="helpblock" style="display: none">
Bottom bar:
 • Icons - Skip to each section
 • Arrow icons / Swipe - Previous / next page
</p>
<div id="guide">
	<p><span class="count" style="float: right"></span></p>
	
	<img class="image" src="/assets/img/guide/1.jpg<?=$hash?>">
	
<?php
$html     = '<div class="bottom-bar">';
foreach( [ 'library', 'playback', 'playlist', 'settings' ] as $id ) {
	$html.= '<a id="'.$id.'" class="btn"><i class="fa fa-'.$id.'"></i><span>'.ucfirst( $id ).'</span></a>';
}
$html    .= '<a id="prevnext"><i class="prev fa fa-arrow-left"></i><i class="next fa fa-arrow-right"></i></a>
			 </div>';
echo $html;
?>
</div>
<script>
nlibrary  = 23;
nplaylist = 40;
nsettings = 48;
ntotal    = 60;
n         = 1;
E         = {};
[ 'close', 'container', 'count', 'helpblock', 'helphead', 'image', 'next', 'prev' ].forEach( ( el ) => {
	E[ el ] = document.getElementsByClassName( el )[ 0 ];
} );
E.btns    = Array.from( document.getElementsByClassName( 'btn' ) );

E.btns[ 1 ].classList.add( 'active' );
E.count.textContent = n +' / '+ ntotal;
E.container.classList.remove( 'hide' );
E.close.addEventListener( 'click', function() {
	location.href = '/';
} );
E.helphead.addEventListener( 'click', function() {
	if ( E.helpblock.style.display === 'none' ) {
		this.classList.add( 'bl' );
		E.helpblock.style.display = '';
	} else {
		this.classList.remove( 'bl' );
		E.helpblock.style.display = 'none';
	}
} );
E.btns.forEach( ( el ) => {
	el.addEventListener( 'click', function() {
		var page = {
			  playback : 1
			, library  : nlibrary
			, playlist : nplaylist
			, settings : nsettings
		}
		n = page[ this.id ]
		renderPage( n );
	} );
} );
E.next.addEventListener( 'click', function() {
	n = n < ntotal ? n + 1 : 1;
	renderPage( n );
} );
E.prev.addEventListener( 'click', function() {
	n = n > 1 ? n - 1 : ntotal;
	renderPage( n );
} );
document.body.addEventListener( 'keyup', ( e ) => {
	if ( e.key === 'ArrowLeft' ) {
		E.prev.click();
	} else if ( e.key === 'ArrowRight' ) {
		E.next.click();
	}
} );

if ( navigator.maxTouchPoints ) { // swipe
	var xstart;
	window.addEventListener( 'touchstart', function( e ) {
		xstart = e.changedTouches[ 0 ].pageX;
	} );
	window.addEventListener( 'touchend', function( e ) {
		var xdiff = xstart - e.changedTouches[ 0 ].pageX;
		if ( Math.abs( xdiff ) > 100 ) {
			xdiff > 0 ? E.next.click() : E.prev.click();
		}
	} );
}

function renderPage( n ) {
	E.count.textContent = n +' / '+ ntotal;
	E.image.src = '/assets/img/guide/'+ n +'.jpg<?=$hash?>';
	E.btns.forEach( ( el ) => {
		el.classList.remove( 'active' );
	} );
	if ( n >= 1 && n < nlibrary ) {
		var id = 'playback';
	} else if ( n >= nlibrary && n < nplaylist ) {
		var id = 'library';
	} else if ( n >= nplaylist && n < nsettings ) {
		var id = 'playlist';
	} else {
		var id = 'settings';
	}
	document.getElementById( id ).classList.add( 'active' );
}
</script>
