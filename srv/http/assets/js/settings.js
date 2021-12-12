function bash( command, callback, json ) {
	if ( typeof command === 'string' ) {
		var args = { cmd: 'bash', bash : command }
	} else {
		if ( command[ 0 ] === 'cmd' ) {
			var filesh = 'cmd';
			command.shift();
		} else {
			var filesh = page;
		}
		var args = { cmd: 'sh', sh: [ filesh +'.sh' ].concat( command ) }
	}
	$.post( 
		  'cmd.php'
		, args
		, callback || null
		, json || null
	);
}
var dirbash = '/srv/http/bash/';
var playersh = dirbash +'player.sh ';
var networkssh = dirbash +'networks.sh ';
var systemsh = dirbash +'system.sh ';
var cmd = {
	  albumignore  : 'cat /srv/http/data/mpd/albumignore'
	, asound       : playersh +'devices'
	, avahi        : networkssh +'avahi'
	, bluetooth    : "echo '<bll># bluetoothctl info</bll>'; bluetoothctl info"
	, bluetoothctl : systemsh +'bluetoothstatus'
	, iw           : "echo '<bll># iw reg get</bll>'; iw reg get; echo '<bll># iw list</bll>';  iw list"
	, journalctl   : systemsh +'journalctl'
	, lan          : networkssh +'ifconfigeth'
	, mount        : systemsh +'fstabget'
	, mpdignore    : playersh +'mpdignorelist'
	, rfkill       : "echo '<bll># rfkill</bll>'; rfkill"
	, soundprofile : systemsh +'soundprofileget'
	, system       : systemsh +'systemconfig'
	, timedatectl  : "echo '<bll># timedatectl</bll>'; timedatectl"
	, wlan         : networkssh +'ifconfigwlan'
}
var services = [ 'hostapd', 'localbrowser', 'mpd', 'shairport-sync', 'smb', 'snapclient', 'snapserver', 'spotifyd', 'upmpdcli' ];

function status( id, refresh ) {
	var $el = $( '#code'+ id );
	if ( !refresh && !$el.hasClass( 'hide' ) ) {
		$el.addClass( 'hide' );
		return
	}
		
	if ( $el.hasClass( 'hide' ) ) {
		var timeoutGet = setTimeout( function() {
			notify( 'Get Data', id, page );
		}, 1000 );
	}
	var command = services.includes( id ) ? [ 'cmd', 'pkgstatus', id ] : cmd[ id ]+' 2> /dev/null';
	bash( command, function( status ) {
		clearTimeout( timeoutGet );
		$el.html( status ).promise().done( function() {
			$el.removeClass( 'hide' );
			if ( id === 'mpdconf' ) {
				setTimeout( function() {
					$( '#codempdconf' ).scrollTop( $( '#codempdconf' ).height() );
				}, 100 );
			}
			if ( id === 'albumignore' || id === 'mpdignore' ) $( 'html, body' ).scrollTop( $( '#code'+ id ).offset().top - 90 );
		} );
		resetLocal();
	} );
}
function infoPlayerActive( $this ) {
	var $switch = $this.prev().prev();
	if ( $switch.hasClass( 'disabled' ) ) {
		info( {
			  icon    : $switch.data( 'icon' )
			, title   : $switch.data( 'label' )
			, message : $switch.data( 'disabled' )
		} );
		return true
	}
}
function list2JSON( list ) {
	try {
		G = JSON.parse( list );
	} catch( e ) {
		var msg = e.message.split( ' ' );
		var pos = msg.pop();
		var errors = '<red>Errors:</red> '+ msg.join( ' ' ) +' <red>'+ pos +'</red>'
					+'<hr>'
					+ list.slice( 0, pos ) +'<red>&#9646;</red>'+ list.slice( pos );
		$( '#data' ).html( errors ).removeClass( 'hide' );
		return false
	}
	$( '#button-data' ).removeAttr( 'class' );
	$( '#data' ).empty().addClass( 'hide' );
	return true
}
function loader() {
	$( '#loader' ).removeClass( 'hide' );
}
function loaderHide() {
	$( '#loader' ).addClass( 'hide' );
}
function notify( title, message, icon, delay ) {
	if ( typeof message === 'boolean' || typeof message === 'number' ) var message = message ? 'Enable ...' : 'Disable ...';
	banner( title, message, icon +' blink', delay || -1 );
}
function refreshData() {
	if ( !$( '#infoOverlay' ).hasClass( 'hide' ) ) return
	
	if ( page === 'networks' ) {
		if ( !$( '#divwifi' ).hasClass( 'hide' ) ) {
			scanWlan();
			resetLocal();
			return
		} else if ( !$( '#divbluetooth' ).hasClass( 'hide' ) ) {
			scanBluetooth();
			resetLocal();
			return
		}
	}
	
	bash( dirbash + page +'-data.sh', function( list ) {
		if ( typeof list === 'string' ) { // on load, try catching any errors
			var list2G = list2JSON( list );
			if ( !list2G ) return
		} else {
			G = list;
		}
		setSwitch();
		renderPage();
	} );
}
function resetLocal() {
	if ( $( '#bannerTitle' ).text() === 'USB Drive' ) return
	
	$( '#bannerIcon i' ).removeClass( 'blink' );
	setTimeout( bannerHide, 1000 );
}
function setSwitch() {
	if ( page !== 'networks' && page !== 'relays' ) {
		$( '.switch' ).each( function() {
			$( this ).prop( 'checked', G[ this.id ] );
		} );
		$( '.setting' ).each( function() {
			var sw = this.id.replace( 'setting-', '' );
			$( this ).toggleClass( 'hide', !G[ sw ] );
		} );
	}
}
function showContent() {
	resetLocal();
	if ( $( 'select' ).length ) selectricRender();
	$( 'pre.status' ).each( function( el ) {
		if ( !$( this ).hasClass( 'hide' ) ) status( this.id.replace( 'code', '' ), 'refresh' );
	} );
	if ( $( '#data' ).hasClass( 'hide' ) ) { // page data
		setTimeout( function() {
			loaderHide();
			$( '.head, .container' ).removeClass( 'hide' );
		}, 300 );
	} else {
		$( '#data' ).html( JSON.stringify( G, null, 2 ) );
	}
}
// active / inactive window /////////
var active = 1;
connect = () => {
	if ( !active ) {
		active = 1;
		pushstream.connect();
		$( '#scanning-bt, #scanning-wifi' ).addClass( 'blink' );
	}
}
disconnect = () => {
	if ( active ) {
		active = 0;
		hiddenSet();
	}
}
hiddenSet = () => {
	if ( page === 'networks' ) {
		if ( !$( '#divbluetooth' ).hasClass( 'hide' ) || !$( '#divwifi' ).hasClass( 'hide' ) ) {
			bash( 'killall -q networks-scanbt.sh; killall -q networks-scanwlan.sh' );
			clearTimeout( G.timeoutScan );
			$( '#scanning-bt, #scanning-wifi' ).removeClass( 'blink' );
			$( '.back' ).click();
		}
	} else if ( page === 'system' ) {
		if ( $( '#refresh' ).hasClass( 'blink' ) ) {
			bash( 'killall -q system-data.sh' );
			clearInterval( G.intCputime );
			$( '#refresh' ).removeClass( 'blink' );
		}
	}
}
document.addEventListener( 'visibilitychange', () => document.hidden ? disconnect() : connect() ); // invisible
window.onpagehide = window.onblur = disconnect; // invisible + visible but not active
window.onpageshow = window.onfocus = connect;
////////////////////////////////////
var pushstream = new PushStream( {
	  modes                                 : 'websocket'
	, timeout                               : 5000
	, reconnectOnChannelUnavailableInterval : 5000
} );
var streams = [ 'bluetooth', 'notify', 'player', 'refresh', 'reload', 'volume', 'volumebt', 'wifi' ];
streams.forEach( function( stream ) {
	pushstream.addChannel( stream );
} );
pushstream.connect();
pushstream.onstatuschange = function( status ) {
	if ( status === 2 ) {
		bannerHide();
		refreshData();
	} else if ( status === 0 ) { // disconnected
		hiddenSet();
	}
}
pushstream.onmessage = function( data, id, channel ) {
	switch( channel ) {
		case 'bluetooth': psBluetooth( data ); break;
		case 'notify':    psNotify( data );    break;
		case 'player':    psPlayer( data );    break;
		case 'refresh':   psRefresh( data );   break;
		case 'reload':    psReload();          break;
		case 'volume':    psVolume( data );    break;
		case 'volumebt':  psVolumeBt( data );  break;
		case 'wifi':      psWifi( data );      break;
	}
}
function psBluetooth( data ) {
	if ( page === 'networks' ) {
		G.listbt = data;
		renderBluetooth();
	}
}
function psNotify( data ) {
	G.bannerhold = data.hold || 0;
	banner( data.title, data.text, data.icon, data.delay );
	if ( 'power' in data ) {
		if ( data.power === 'off' ) {
			$( '#loader' ).addClass( 'splash' );
			setTimeout( bannerHide, 10000 );
		}
		loader();
	}
}
function psPlayer( data ) {
	var player_id = {
		  airplay   : 'shairport-sync'
		, bluetooth : 'bluetooth'
		, snapcast  : 'snapserver'
		, spotify   : 'spotifyd'
		, upnp      : 'upmpdcli'
	}
	$( '#'+ player_id[ data.player ] ).toggleClass( 'disabled', data.active );
}
function psRefresh( data ) {
	if ( data.page === page ) {
		G = data;
		renderPage();
		setSwitch();
	}
}
function psReload() {
	if ( localhost ) location.reload();
}
function psVolume( data ) {
	if ( G.local || !$( '#infoRange .value' ).text() ) return
	
	clearTimeout( G.debounce );
	G.debounce = setTimeout( function() {
		var val = data.type !== 'mute' ? data.val : 0;
		$( '#infoRange .value' ).text( val );
		$( '#infoRange input' ).val( val );
		$( '.infofooter' ).text( data.db +' dB' );
		$( '#infoContent' ).removeClass( 'hide' );
		$( '.warning, #infoButtons a:eq( 0 )' ).addClass( 'hide' );              // ok
		$( '#infoButtons a:eq( 1 )' ).toggleClass( 'hide', data.db === '0.00' ); // 0dB
	}, 300 );
}
function psVolumeBt( data ) {
	if ( !$( '#infoRange .value' ).text() ) return
	
	$( '#infoRange .value' ).text( data.val );
	$( '#infoRange input' ).val( data.val );
	$( '.infofooter' ).text( data.db +' dB' );
	$( '#infoButtons' ).toggleClass( 'hide', data.db === '0.00' );
}
function psWifi( data ) {
	info( {
		  icon    : 'wifi'
		, title   : 'Wi-Fi'
		, message : 'Reboot to connect <wh>'+ data.ssid +'</wh> ?'
		, oklabel : '<i class="fa fa-reboot"></i>Reboot'
		, okcolor : orange
		, ok      : function() {
			bash( [ 'reboot' ] );
		}
	} );
}
//---------------------------------------------------------------------------------------
G = {}
var debounce;
var dirsystem = '/srv/http/data/system';
var intervalcputime;
var intervalscan;
var local = 0;
var localhost = [ 'localhost', '127.0.0.1' ].includes( location.hostname );
var orange = '#de810e';
var page = location.href.replace( /.*p=/, '' ).split( '&' )[ 0 ];
var red = '#bb2828';
var timer;
var pagenext = {
	  features : [ 'system', 'player' ]
	, player   : [ 'features', 'networks' ]
	, networks : [ 'player', 'system' ]
	, system   : [ 'networks', 'features' ]
}
var $focus;
var selectchange = 0;

document.title = page;

if ( localhost ) $( 'a' ).removeAttr( 'href' );

$( document ).keyup( function( e ) {
	if ( !$( '#infoOverlay' ).hasClass( 'hide' ) ) return
	
	var key = e.key;
	if ( key === 'Tab'  ) {
		$( '#bar-bottom div' ).removeClass( 'bgr' );
		$( '.switchlabel, .setting' ).removeClass( 'focus' );
		setTimeout( function() {
			$focus = $( 'input:checkbox:focus' );
			if ( $focus.length ) {
				$focus.next().addClass( 'focus' );
			}
		}, 0 );
	} else if ( key === 'Escape' ) {
		$focus = $( '.switchlabel.focus' );
		setTimeout( function() {
			if ( $focus.length ) $focus.prev().focus();
		}, 300 );
		if ( $( '.setting.focus' ).length ) {
			$( '.setting' ).removeClass( 'focus' );
			return
		}
		
		if ( $focus.length && $focus.prev().prop( 'checked' ) && $focus.next().hasClass( 'setting' ) ) {
			$( '.switchlabel.focus' ).next().addClass( 'focus' );
		}
	} else if ( key === 'ArrowLeft' || key === 'ArrowRight' ) {
		var $current = $( '#bar-bottom .bgr' ).length ? $( '#bar-bottom .bgr' ) : $( '#bar-bottom .active' );
		var id = $current[ 0 ].id;
		var $next = key === 'ArrowLeft' ? $( '#'+ pagenext[ id ][ 0 ] ) : $( '#'+ pagenext[ id ][ 1 ] );
		$( '#bar-bottom div' ).removeClass( 'bgr' );
		if ( !$next.hasClass( 'active' ) ) $next.addClass( 'bgr' );
	} else if ( key === 'Enter' ) {
		if ( $( '#bar-bottom .bgr' ).length ) {
			$( '#bar-bottom .bgr' ).click();
		} else {
			$focus = $( '.setting.focus' );
			if ( $focus.length ) $focus.click();
		}
	}
} );
$( '#close' ).click( function() {
	if ( page === 'networks' ) {
		clearTimeout( intervalscan );
		bash( 'killall networks-scanbt.sh networks-scanwlan.sh &> /dev/null' );
	}
	bash( [ 'cmd', 'rebootlist' ], function( list ) {
		if ( !list ) {
			location.href = '/';
		} else {
			var list = list.replace( /\^/s, '\n' );
			info( {
				  icon    : page
				, title   : 'System Setting'
				, message : `\
Reboot required for:
<wh>${ list }</wh>`
				, cancel  : function() {
					bash( 'rm -f /srv/http/data/shm/reboot /srv/http/data/tmp/backup.*' );
					location.href = '/';
				}
				, okcolor : orange
				, oklabel : '<i class="fa fa-reboot"></i>Reboot'
				, ok      : function() {
					bash( [ 'cmd', 'power', 'reboot' ] );
				}
			} );
		}
	} );
} );
$( '#button-data' ).click( function() {
	if ( !G ) return
	
	if( $( '#data' ).hasClass( 'hide' ) ) {
		$( '.container' ).addClass( 'hide' );
		$( '#data' )
			.html( JSON.stringify( G, null, 2 ) )
			.removeClass( 'hide' );
		$( '#button-data' ).addClass( 'fa fa-times' );
	} else {
		$( '.container' ).removeClass( 'hide' );
		$( '#data' ).addClass( 'hide' );
		$( '#button-data' ).removeClass( 'fa fa-times' );
	}
} ).on( 'mousedown touchdown', function() {
	timer = setTimeout( function() {
		location.reload();
	}, 1000 );
} ).on( 'mouseup mouseleave touchup touchleave', function() {
	clearTimeout( timer );
} );
$( '#help' ).click( function() {
	var eltop = $( 'heading' ).filter( function() {
		return this.getBoundingClientRect().top > 0
	} )[ 0 ]; // return 1st element
	if ( eltop ) var offset0 = eltop.getBoundingClientRect().top;
	if ( window.innerHeight > 570 ) {
		var visible = $( '.help-block:not( .hide )' ).length > 0;
		$( this ).toggleClass( 'bl', !visible );
		$( '.section' ).each( function() {
			if ( $( this ).hasClass( 'hide' ) ) return
			
			$( this ).find( '.help-block' ).toggleClass( 'hide', visible );
		} )
		
	} else {
		var visible = $( '#bar-bottom' ).css( 'display' ) !== 'none';
		$( '#bar-bottom' ).css( 'display', visible ? '' : 'block' );
	}
	if ( eltop ) $( 'html, body' ).scrollTop( eltop.offsetTop - offset0 );
} );
$( '.help' ).click( function() {
	$( this ).parents( '.section' ).find( '.help-block' ).toggleClass( 'hide' );
	$( '#help' ).toggleClass( 'bl', $( '.help-block:not( .hide )' ).length !== 0 );
} );
$( '.container' ).on( 'click', '.status', function( e ) {
	if ( $( e.target ).is( 'i' ) ) return
	
	var $this = $( this );
	if ( !$this.hasClass( 'single' ) ) status( $this.data( 'status' ) );
} );
$( '.switch' ).click( function() {
	var id = this.id;
	var $this = $( this );
	var checked = $this.prop( 'checked' );
	var label = $this.data( 'label' );
	var icon = $this.data( 'icon' );
	if ( $this.hasClass( 'disabled' ) ) {
		$this.prop( 'checked', !checked );
		info( {
			  icon    : icon
			, title   : label
			, message : $this.data( 'disabled' )
		} );
		return
	}
	
	if ( $this.hasClass( 'common' ) ) {
		if ( checked ) {
			$( '#setting-'+ id ).click();
		} else {
			notify( label, 'Disable ...', icon );
			bash( [ id +'disable' ] );
		}
	} else {
		notify( label, checked, icon );
		bash( [ this.id, checked ] );
	}
} );
$( '#bar-bottom div' ).click( function() {
	loader();
	location.href = 'settings.php?p='+ this.id;
} );
