var freq = [ 31, 63, 125, 250, 500, 1, 2, 4, 8, 16 ];
var timeout;
var band = [];
var opthz = '';
freq.forEach( function( hz, i ) {
	band.push( '0'+ i +'. '+ freq[ i ] + ( i < 5 ? ' Hz' : ' kHz' ) );
	opthz += '<a>'+ hz + ( i < 5 ? '' : 'k' ) +'</a>';
} );
var content = `
<div id="eq">
<div class="hz">${ opthz }</div>
<div class="bottom">
	<i id="eqdelete" class="fa fa-minus-circle hide"></i>
	<i id="eqrename" class="fa fa-edit-circle"></i>
	<i id="eqsave" class="fa fa-save"></i>
	<input id="eqname" type="text" class="hide"><select id="eqpreset">PRESETS</select>
	<i id="eqnew" class="fa fa-plus-circle"></i><i id="eqcancel" class="fa fa-times bl hide"></i>
	<i id="eqflat" class="fa fa-set0"></i>
</div>
<div id="infoRange" class="vertical">${ '<input type="range" min="40" max="80">'.repeat( 10 ) }</div>
</div>`;
function equalizer() {
	bash( [ 'equalizerget' ], function( data ) {
		G.eqcurrent = data.current;
		G.vcurrent = data.values.join( '' );
		G.nameval = data.nameval;
		var eqbuttons = {}
		var changed = false;
		var values = [ '', data.current, ...data.values ]; // [ #eqname, #eqpreset, ... ]
		var optpreset = '';
		data.presets.forEach( function( name ) {
			optpreset += '<option value="'+ name +'">'+ name +'</option>';
		} );
		info( {
			  icon       : 'equalizer'
			, title      : 'Equalizer'
			, content    : content.replace( 'PRESETS', optpreset )
			, values     : values
			, beforeshow : function() {
				$( '#infoBox' ).css( 'width', 550 );
				eqButtonSet();
				if ( !/Android.*Chrome/i.test( navigator.userAgent ) ) { // fix: chrome android cannot drag
					$( '#infoRange input' ).on( 'click input keyup', function() {
						var $this = $( this );
						eqValueSet( band[ $this.index() ], $this.val() )
					} );
				} else {
					var $this, ystart, val, prevval;
					var yH = $( '#infoRange input' ).width() - 40;
					var step = yH / 40;
					$( '#infoRange input' ).on( 'touchstart', function( e ) {
						$this = $( this );
						ystart = e.changedTouches[ 0 ].pageY;
						val = +$this.val();
					} ).on( 'touchmove', function( e ) {
						var pageY = e.changedTouches[ 0 ].pageY;
						var diff = ystart - pageY;
						if ( Math.abs( diff ) < step ) return
						
						var v = val + Math.round( diff / step );
						if ( v === prevval || v > 80 || v < 40 ) return
						
						prevval = v;
						$this.val( v );
						eqValueSet( band[ $this.index() ], v )
					} );
				}
				$( '#eqpreset' ).change( function() {
					var name = $( this ).val();
					G.eqcurrent = name;
					bash( [ 'equalizer', 'preset', name ] );
				} );
				$( '#eqname' ).on( 'keyup paste cut', function( e ) {
					var val = $( this ).val().trim();
					var blank = val === '';
					var exists = data.presets.includes( val );
					if ( $( '#eqrename' ).hasClass( 'hide' ) ) {
						var changed = !blank && !exists && val !== G.eqcurrent;
					} else { // new
						var changed = !blank && !exists;
					}
					if ( e.key === 'Enter' && changed ) $( '#eqsave' ).click();
					$( '#eqsave' ).toggleClass( 'disabled', !changed );
				} );
				$( '#eqdelete' ).click( function() {
					G.eqcurrent = 'Flat';
					bash( [ 'equalizer', 'delete', $( '#eqpreset' ).val() ] );
					$( '#eqcancel' ).click();
				} );
				$( '#eqrename' ).click( function() {
					$( '#eqrename, #eqdelete' ).toggleClass( 'hide' );
					$( '#eqname' ).val( G.eqcurrent );
					$( '#eqnew' ).click();
				} );
				$( '#eqsave' ).click( function() {
					var eqname = $( '#eqname' ).hasClass( 'hide' ) ? $( '#eqpreset' ).val() : $( '#eqname' ).val();
					bash( [ 'equalizer', 'save', eqname ] );
					$( '#eqcancel' ).click();
					$( '#eqrename' ).removeClass( 'disabled' );
					$( '#eqsave' ).addClass( 'disabled' );
				} );
				$( '#eqnew' ).click( function() {
					eqbuttons = {};
					[ 'eqrename', 'eqsave', 'eqflat' ].forEach( function( btn ) {
						eqbuttons[ btn ] = $( '#'+ btn ).hasClass( 'disabled' );
					} );
					$( '#eqnew, #eq .selectric-wrapper' ).addClass( 'hide' );
					$( '#eqname, #eqcancel' ).removeClass( 'hide' );
					$( '#eqrename' ).addClass( 'disabled' );
					$( '#eqsave' ).addClass( 'disabled' );
				} );
				$( '#eqcancel' ).click( function() {
					$( '#eqrename, #eqnew, #eq .selectric-wrapper' ).removeClass( 'hide' );
					$( '#eqname, #eqcancel, #eqdelete' ).addClass( 'hide' );
					$( '#eqname' ).val( '' );
					[ 'eqrename', 'eqsave', 'eqflat' ].forEach( function( btn ) {
						$( '#'+ btn ).toggleClass( 'disabled', eqbuttons[ btn ] );
					} );
				} );
				$( '#eqflat' ).click( function() {
					G.eqcurrent = 'Flat';
					bash( [ 'equalizer', 'preset', 'Flat' ] );
				} );
			}
			, buttonnoreset : 1
			, okno          : 1
		} );
	}, 'json' );
}
function eqButtonSet() {
	var current = $( '#eqpreset' ).val();
	var flat = current === 'Flat';
	var unnamed = current === '(unnamed)';
	var changed = infoVal().slice( 2 ).join( ' ' ) !== G.nameval[ current ];
	$( '#eqrename' ).toggleClass( 'disabled', unnamed || flat || changed );
	$( '#eqsave' ).toggleClass( 'disabled', unnamed || flat || !changed );
	$( '#eqflat' ).toggleClass( 'disabled', flat );
}
function eqValueSet( band, val ) {
	clearTimeout( timeout );
	bash( [ 'equalizerupdn', band, val ] );
	eqButtonSet();
	timeout = setTimeout( function() {
		bash( [ 'equalizerget', 'pushstream', $( '#eqpreset' ).val() === 'Flat' ? 'set' : '' ] );
	}, 1000 );
}
