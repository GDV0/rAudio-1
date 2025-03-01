// keyboard controls
$( document ).keydown( function( e ) { // keyup cannot e.preventDefault() page scroll
	if ( G.local || ! I.infohide ) return
	
	var key = e.key;
	if ( key === 'Backspace' && ! $( 'input:focus, textarea:focus' ).length ) {
		if ( G.library ) {
			$( '#button-lib-back' ).click();
		} else if ( G.playlist ) {
			$( '#button-pl-back' ).click();
		}
		return
	}
	
	if ( key === 'Enter' ) {
		if ( ! $( '#settings' ).hasClass( 'hide' ) ) {
			var $menu = $( '#settings' ).find( 'a.active' );
			if ( ! $menu.length ) $menu = $( '#settings' ).find( '.submenu.active' );
			var href = $menu.prop( 'href' );
			href ? location.href = href : $menu.click();
			return
		}
	}
	
	if ( key === 'Escape' ) {
		if ( $( '.menu:not(.hide)' ).length ) {
			$( '.menu' ).addClass( 'hide' );
			if ( 'colorpicker' in G ) $( '#colorcancel' ).click();
		} else {
			$( '#button-settings' ).click();
		}
		return
	}
		
	if ( key === 'Home' ) {
		if ( G.library ) {
			$( '#library' ).click();
		} else if ( G.playlist ) {
			$( '#playlist' ).click();
		}
		return
	}
	
	if ( key === '#' || key >= 'a' && key <= 'z' ) { // index bar
		key = key.toUpperCase();
		if ( G.library && ! $( '#lib-list .index' ).hasClass( 'hide' ) ) {
			$( '#lib-index' ).find( 'wh:contains('+ key +')' ).click();
			if ( G.albumlist ) {
				$( '#lib-list .coverart.active' ).removeClass( 'active' );
				if ( key !== '#' ) {
					$( '#lib-list .coverart[data-index='+ key +']' ).eq( 0 ).addClass( 'active' );
				} else {
					$( '#lib-list .coverart' ).eq( 0 ).addClass( 'active' );
				}
			} else {
				$( '#lib-list li.active' ).removeClass( 'active' );
				if ( key !== '#' ) {
					$( '#lib-list li[data-index='+ key +']' ).eq( 0 ).addClass( 'active' );
				} else {
					$( '#lib-list li' ).eq( 0 ).addClass( 'active' );
				}
			}
		} else if ( G.playlist && ! $( '#pl-list .index' ).hasClass( 'hide' ) ) {
			$( '#pl-savedlist li.active' ).removeClass( 'active' );
			if ( key !== '#' ) {
				$( '#pl-savedlist li[data-index='+ key +']' ).eq( 0 ).addClass( 'active' );
			} else {
				$( '#pl-savedlist li' ).eq( 0 ).addClass( 'active' );
			}
		}
		return
	}
	
	if ( ! $( '#colorpicker' ).hasClass( 'hide' ) ) return

	var keyevent = {
		  MediaNextTrack     : 'next'
		, MediaPause         : 'pause'
		, MediaPlay          : 'play'
		, MediaPreviousTrack : 'previous'
		, MediaStop          : 'stop'
		, MediaTrackPrevious : 'previous'
		, MediaTrackNext     : 'next'
	}
	if ( G.localhost ) {
		keyevent.AudioVolumeDown = 'voldn';
		keyevent.AudioVolumeMute = 'volmute';
		keyevent.AudioVolumeUp   = 'volup';
	}
	if ( ( key === ' ' && ! [ 'input', 'password', 'textarea' ].includes( e.target.localName ) ) || key === 'MediaPlayPause' ) {
		var btn = G.status.state === 'play' ? ( G.status.webradio ? 'stop' : 'pause' ) : 'play';
		$( '#'+ btn ).click();
		e.preventDefault();
		return
		
	} else if ( key === 'Tab' ) {
		e.preventDefault();
		if ( G.library ) {
			$( '#playback' ).click();
		} else if ( G.playback ) {
			$( '#playlist' ).click();
		} else {
			$( '#library' ).click();
		}
		return
		
	} else {
		$( '#'+ keyevent[ key ] ).click();
		if ( key.slice( 5 ) === 'Media' ) return
		
	}
	// context menu
	var $contextmenu = $( '.contextmenu:not( .hide )' );
	if ( ! $contextmenu.length ) $contextmenu = $( '#settings:not( .hide )' );
	if ( $contextmenu.length ) {
		if ( G.library ) {
			var $liactive = $( '#lib-list li.active' );
		} else if ( G.playlist ) {
			if ( ! G.savedlist ) {
				var $liactive = $( '#pl-list li.updn' );
				if ( ! $liactive.length ) $liactive = $( '#pl-list li.active' );
			} else {
				var $liactive = $( '#pl-savedlist li.active' );
			}
		}
		var $menuactive = $contextmenu.find( 'a.active' );
		var $menufirst  = $contextmenu.find( 'a:not( .hide )' ).eq( 0 );
		var $menulast   = $contextmenu.find( 'a:not( .hide )' ).last();
		switch ( key ) {
			case 'ArrowLeft':
				if ( $( '.submenu.active' ).length ) {
					$( '.submenu.active' )
						.removeClass( 'active' )
						.prev().addClass( 'active' );
				} else {
					$( '.menu' ).addClass( 'hide' )
					$menuactive.removeClass( 'active' );
					$( '.submenu' ).removeClass( 'active' );
					if ( G.playlist ) $( '#pl-list li' ).removeClass( 'lifocus' );
				}
				break;
			case 'ArrowRight':
				var $next = $menuactive.next();
				if ( $next.hasClass( 'submenu' ) ) {
					$menuactive.removeClass( 'active' );
					$next.addClass( 'active' );
				}
				break;
			case 'ArrowUp':
			case 'ArrowDown':
				e.preventDefault();
				if ( $( '.submenu.active' ).length ) {
					$menuactive = $( '.submenu.active' );
					if ( key === 'ArrowDown' ) {
						$next = $menuactive.nextAll( 'a:not( .hide )' ).eq( 0 );
						if ( ! $next.length ) $next = $menuactive.prevAll( 'a:not( .hide )' ).last();
					} else {
						$next = $menuactive.prevAll( 'a:not( .hide )' ).eq( 1 );
						if ( ! $next.length ) $next = $menuactive.nextAll( 'a:not( .hide )' ).last();
					}
					$next.addClass( 'active' );
					$menuactive.removeClass( 'active' );
					return
				}
				
				if ( ! $menuactive.length ) {
					$menufirst.addClass( 'active' );
				} else {
					$menuactive.removeClass( 'active' );
					$( '.submenu' ).removeClass( 'active' );
					if ( key === 'ArrowDown' ) {
						if ( $menuactive.is( $menulast ) ) {
							$menufirst.addClass( 'active' );
						} else {
							$menuactive.nextAll( 'a:not( .hide )' ).eq( 0 ).addClass( 'active' );
						}
					} else {
						if ( $menuactive.is( $menufirst ) ) {
							$menulast.addClass( 'active' );
						} else {
							$menuactive.prevAll( 'a:not( .hide )' ).eq( 0 ).addClass( 'active' );
						}
					}
				}
				break;
			case 'Enter':  // context menu
				if ( $( '.menu:not(.hide)' ).length ) $contextmenu.find( '.active' ).click();
				break;
		}
		return
	}
	
	if ( G.playback ) {
		var key_btn = {
			  ArrowLeft  : 'previous'
			, ArrowRight : 'next'
			, ArrowUp    : 'volup'
			, ArrowDown  : 'voldn'
		}
		$( '#'+ key_btn[ key ] ).click();
	} else if ( G.library ) {
		if ( ! $( '#lib-search' ).hasClass( 'hide' ) ) return
		
		// home /////////////////////////////////////////
		if ( ! $( '#lib-mode-list' ).hasClass( 'hide' ) ) {
			var $blupdn = $( '.lib-mode.updn' );
			if ( ! $blupdn.length ) {
				$( '.lib-mode:not( .hide )' ).eq( 0 ).addClass( 'updn' );
				return
			}
			
			switch ( key ) {
				case 'ArrowLeft':
					var $div = $( '.lib-mode.updn' ).prevAll( ':not( .hide )' ).eq( 0 );
					$( '.lib-mode' ).removeClass( 'updn' );
					if ( ! $div.length ) $div = $( '.lib-mode:not( .hide )' ).last();
					$div.addClass( 'updn' );
					break;
				case 'ArrowRight':
					var $div = $( '.lib-mode.updn' ).nextAll( ':not( .hide )' ).eq( 0 );
					$( '.lib-mode' ).removeClass( 'updn' );
					if ( ! $div.length ) $div = $( '.lib-mode:not( .hide )' ).eq( 0 );
					$div.addClass( 'updn' );
					break;
				case 'Enter':
					$( '.lib-mode.updn .mode' ).click();
					break;
			}
			return
		}
		
		if ( G.albumlist ) { // album
			if ( ! $( '#lib-list .coverart.active' ).length ) {
				$( '#lib-list .coverart' ).eq( 0 ).addClass( 'active' );
				return
			}
			
			var $active = $( '#lib-list .coverart.active' );
			switch ( key ) {
				case 'ArrowLeft':
				case 'ArrowRight':
					if ( arrowL && $active.index() === 0 ) return
					if ( arrowR && $active.index() === $( '#lib-list .coverart' ).length + 1 ) return
					
					var $next = arrowR ? $active.next() : $active.prev();
					$active.removeClass( 'active' );
					$next.addClass( 'active' );
					var rect  = $next[ 0 ].getBoundingClientRect();
					var wH    = $( window ).height();
					var eH    = $next.height();
					var top   = $next.offset().top;
					if ( rect.bottom > 0 && rect.bottom < ( wH - eH ) ) {
						var scroll = top - ( G.bars ? 80 : 40 );
					} else if ( rect.top > 0 && rect.top < ( wH - eH ) ) {
						var scroll = top - eH;
					}
					$( 'html, body' ).scrollTop( scroll );
					break;
				case 'ArrowUp':
					$( '#button-lib-back' ).click();
					break;
				case 'Enter':
					G.iactive = $( '#lib-list .coverart.active' ).index();
					$active.click();
					break;
			}
			return
		}
		
		switch ( key ) {
			case 'ArrowLeft': // back button
				$( '#button-lib-back' ).click();
				return
			case 'ArrowRight': // show context menu
				$( '#lib-list li.active .lib-icon' ).click();
				return
			// list ///////////////////////////////////////
			case 'ArrowUp':
			case 'ArrowDown':
				scrollUpDown( e, $( '#lib-list' ), key );
				break;
			case 'Enter':
				var $liactive = $( '#lib-list li.active' );
				if ( $( '.licover' ).length || $( '#lib-list li.mode-webradio' ).length ) {
					if ( $( '.menu:not(.hide)' ).length ) { // context menu
						var menu = $liactive.find( '.lib-icon' ).data( 'target' );
						$( menu ).find( 'a' ).eq( 1 ).click();
					}
				} else {
					$liactive.click();
				}
				break;
		}
		menuHide();
	} else if ( G.playlist ) {
		if ( G.savedplaylist || G.savedlist ) {
			switch ( key ) {
				case 'ArrowUp':
				case 'ArrowDown':
					scrollUpDown( e, $( '#pl-savedlist' ), key );
					break;
				case 'ArrowRight':
					$( '#pl-savedlist li.active .pl-icon' ).click();
					break;
				case 'Enter':
					$( '#pl-savedlist li.active' ).click();
					break;
				case 'ArrowLeft':
					if ( ! $( '.contextmenu:not( .hide )' ).length ) $( '#button-pl-back' ).click();
					break;
			}
		} else {
			switch ( key ) {
				case 'ArrowUp':
				case 'ArrowDown':
					var $liactive = $( '#pl-list li.updn' );
					if ( ! $liactive.length ) $( '#pl-list li.active' ).addClass( 'updn' );
					scrollUpDown( e, $( '#pl-list' ), key );
					break;
				case 'ArrowRight':
					$( '#pl-list li.updn' ).length ? $( '#pl-list li.updn .pl-icon' ).click() : $( '#pl-list li.active .pl-icon' ).click();
					break;
				case 'Enter':
					$( '#pl-list li.updn' ).click();
					break;
				case 'Delete':
					$( '#button-pl-clear' ).click();
					break;
			}
		}
	}
} );
function scrollUpDown( e, $list, key ) {
	if ( $( '.contextmenu' ).not( '.hide' ).length ) return
	
	e.preventDefault();
	var $li       = $list.find( 'li' );
	var $liactive = $list.find( 'li.active' );
	if ( ! $liactive.length ) {
		$li.first().addClass( 'active' );
		setTimeout( () => $( 'html, body' ).scrollTop( 0 ), 300 );
		return
	}
	
	var classactive = 'active';
	if ( $list.prop( 'id' ) === 'pl-list' ) {
		$liactive   = $list.find( 'li.updn' );
		classactive = 'updn';
	}
	var $linext     = key === 'ArrowUp' ? $liactive.prev( 'li' ) : $liactive.next( 'li' );
	var barH        = G.display.bars ? 0 : 40;
	if ( G.library && $( '.licover' ).length && ! G.display.hidecover && G.display.fixedcover ) barH += 230;
	if ( ! $linext.length ) $linext = key === 'ArrowUp' ? $li.last() : $li.first();
	$liactive.removeClass( classactive );
	$linext.addClass( classactive );
	var litop       = $linext[ 0 ].getBoundingClientRect().top;
	var libottom    = $linext[ 0 ].getBoundingClientRect().bottom;
	var licount     = Math.round( ( G.wH - 120 - ( barH * 2 ) ) / 49 );
	if ( $linext.is( ':first-child' ) ) {
		$( 'html, body' ).scrollTop( 0 );
	} else if ( $linext.is( ':last-of-type' ) && libottom > G.wH - 40 - barH ) {
		$( 'html, body' ).scrollTop( litop - 80 - barH - ( licount - 2 ) * 49 );
	} else if ( litop < 80 - barH ) {
		$( 'html, body' ).scrollTop( $( window ).scrollTop() - 120 - G.wH % 49 - barH - ( licount - 3 ) * 49 );
	} else if ( libottom > G.wH - 40 - barH ) {
		$( 'html, body' ).scrollTop( $linext.offset().top - 80 - barH );
	}
}