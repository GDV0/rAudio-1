$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

var gpiosvg = $( '#gpiosvg' ).html().replace( 'width="380px', 'width="330px' );;
var pin2gpio = {
	   3:2,   5:3,   7:4,   8:14, 10:15, 11:17, 12:18, 13:27, 15:22, 16:23, 18:24, 19:10, 21:9
	, 22:25, 23:11, 24:8,  26:7,  29:5,  31:6,  32:12, 33:13, 35:19, 36:16, 37:26, 38:20, 40:21
}
$( '.img' ).click( function() {
	var name = $( this ).data( 'name' );
	var txtlcdchar = `\
${ gpiosvg }<code>GND:(any black pin)</code>
<wh>I²C:</wh> <code>VCC:1</code> <code>SDA:3</code> <code>SCL:5</code> <code>5V:4</code>
<wh>GPIO:</wh> <code>VCC:4</code> <code>RS:15</code> <code>RW:18</code> <code>E:16</code> <code>D4-7:21-24</code>`;
	var txtmpdoled = `\
${ gpiosvg }<code>GND:(any black pin)</code> <code>VCC:1</code>
<wh>I²C:</wh> <code>SCL:5</code> <code>SDA:3</code>
<wh>SPI:</wh> <code>CLK:23</code> <code>MOS:19</code> <code>RES:22</code> <code>DC:18</code> <code>CS:24</code>`;
	var txtrotaryencoder = `${ gpiosvg }<code>GND: (any black pin)</code> &emsp; <code>+: not use</code>`
	var title = {
		  i2cbackpack   : [ 'Character LCD', '', 'lcdchar' ]
		, lcdchar       : [ 'Character LCD', txtlcdchar ]
		, relays        : [ 'Relays Module' ]
		, rotaryencoder : [ 'Rorary Encoder', txtrotaryencoder, 'volume' ]
		, lcd           : [ 'TFT 3.5" LCD' ]
		, mpdoled       : [ 'Spectrum OLED', txtmpdoled ]
		, powerbutton   : [ 'Power Button',  '', 'power', '300px', 'svg' ]
		, vuled         : [ 'VU LED',        '', 'led',   '300px', 'svg' ]
	}
	var d = title[ name ];
	info( {
		  icon        : d[ 2 ] || name
		, title       : d[ 0 ]
		, message     : '<img src="/assets/img/'+ name +'.'+ Math.ceil( Date.now() / 1000 ) +'.'+ (d[ 4 ] || 'jpg' )
						+'" style="height: '+ ( d[ 3 ] || '100%' ) +'; margin-bottom: 0;">'
		, footer      : d[ 1 ]
		, footeralign : 'left'
		, beforeshow  : function() {
			$( '.'+ name +'-no' ).addClass( 'hide' );
		}
		, okno        : 1
	} );
} );
$( '.container' ).on( 'click', '.settings', function() {
	location.href = 'settings.php?p='+ $( this ).data( 'setting' );
} );
$( 'body' ).on( 'click touchstart', function( e ) {
	if ( !$( e.target ).parents( '#divi2smodule' ).length && $( '#i2smodule' ).val() === 'none' ) {
		$( '#divi2smodulesw' ).removeClass( 'hide' );
		$( '#divi2smodule' ).addClass( 'hide' );
	}
} );
$( '#refresh' ).click( function( e ) {
	if ( $( e.target ).hasClass( 'help' ) ) return
	
	var $this = $( this );
	if ( $this.hasClass( 'blink' ) ) {
		clearInterval( G.intCputime );
		bannerHide();
		$this.removeClass( 'blink' );
	} else {
		$this.addClass( 'blink' );
		G.intCputime = setInterval( function() {
			bash( '/srv/http/bash/system-data.sh status', function( status ) {
				$.each( status, function( key, val ) {
					G[ key ] = val;
				} );
				renderStatus();
			}, 'json' );
		}, 10000 );
	}
} );
$( '#addnas' ).click( function() {
	infoMount();
} );
$( '#list' ).on( 'click', 'li', function() {
	var $this = $( this );
	G.li = $this;
	$( '#codehddinfo' ).addClass( 'hide' );
	var mountpoint = $this.find( '.mountpoint' ).text();
	$( 'li' ).removeClass( 'active' );
	var $menu = $( '#menu' );
	if ( !$menu.hasClass( 'hide' ) || mountpoint === '/' ) {
		$( '#menu, #codehddinfo' ).addClass( 'hide' );
		return
	}
	
	$this.addClass( 'active' );
	$menu.find( '.info, .spindown' ).toggleClass( 'hide', mountpoint.slice( 9, 12 ) !== 'USB' );
	var menuH = $menu.height();
	$menu
		.removeClass( 'hide' )
		.css( 'top', $this.position().top + 48 );
	var targetB = $menu.offset().top + menuH;
	var wH = window.innerHeight;
	if ( targetB > wH - 40 + $( window ).scrollTop() ) $( 'html, body' ).animate( { scrollTop: targetB - wH + 42 } );
} );
$( 'body' ).click( function( e ) {
	if ( this.id !== 'codehddinfo' && !$( e.target ).parents( '#list' ).length ) {
		$( '#menu, #codehddinfo' ).addClass( 'hide' );
		$( 'li' ).removeClass( 'active' );
	}
} );
$( '#menu a' ).click( function() {
	var $this = $( this );
	var cmd = $this.prop( 'class' );
	var source = G.li.find( '.source' ).text();
	var mountpoint = G.li.find( '.mountpoint' ).text();
	if ( mountpoint.slice( 9, 12 ) === 'NAS' ) {
		var icon = 'networks';
		var title = 'Network Mount';
	} else {
		var icon = 'usbdrive';
		var title = 'Local Mount';
	}
	if ( cmd === 'remount' ) {
		notify( title, 'Remount ...', icon );
		bash( [ 'remount', mountpoint, source ] );
	} else if ( cmd === 'unmount' ) {
		notify( title, 'Unmount ...', icon )
		bash( [ 'unmount', mountpoint ] );
	} else if ( cmd === 'forget' ) {
		notify( title, 'Forget ...', icon );
		bash( [ 'remove', mountpoint ] );
	} else if ( cmd === 'info' ) {
		var $code = $( '#codehddinfo' );
		if ( $code.hasClass( 'hide' ) ) {
			bash( 'hdparm -I '+ source, function( data ) {
				$code
					.html( data )
					.removeClass( 'hide' );
			} );
		} else {
			$code.addClass( 'hide' );
		}
	} else if ( cmd === 'spindown' ) {
		info( {
			  icon         : 'usbdrive'
			, title        : 'USB Drive'
			, message      : 'Spindown when idle:'
			, radio        : { Disable: 0, '2 minutes': 24, '5 minutes': 60, '10 minutes': 120 }
			, values       : G.hddspindown
			, checkchanged : 1
			, ok           : function() {
				var val = infoVal()
				notify( 'USB Drive Spindown', ( val === 0 ? 'Disable ...' : 'Idle: '+ ( val * 5 / 60 ) +'minutes ...' ), 'usbdrive' )
				bash( [ 'hddspindown', val, source ], function( std ) {
					if ( std == -1 ) {
						info( {
							  icon         : 'usbdrive'
							, title        : 'USB Drive'
							, message      : '<wh>'+ source +'</wh> not support spindown.'
						} );
						bannerHide();
					}
				} );
			}
		} );
	}
} );
$( '#setting-bluetooth' ).click( function() {
	var active = infoPlayerActive( $( this ) );
	if ( active ) return
	
	info( {
		  icon         : 'bluetooth'
		, title        : 'Bluetooth'
		, checkbox     : [ 'Discoverable <gr>by senders</gr>', 'Sampling 16bit 44.1kHz <gr>to receivers</gr>' ]
		, values       : G.bluetoothconf
		, checkchanged : ( G.bluetooth ? 1 : 0 )
		, cancel       : function() {
			$( '#bluetooth' ).prop( 'checked', G.bluetooth );
		}
		, ok           : function() {
			notify( 'Bluetooth', G.bluetooth ? 'Change ...' : 'Enable ...', 'bluetooth' );
			bash( [ 'bluetoothset', ...infoVal() ] );
		}
	} );
} );
$( '#setting-wlan' ).click( function() {
	bash( 'cat /srv/http/settings/regdomcodes.json', function( list ) {
		var options = '';
		$.each( list, function( k, v ) {
			options += '<option value="'+ k +'">'+ v +'</option>';
		} );
		var infowifi = `\
<table>
<tr><td style="padding-right: 5px; text-align: right;">Country</td><td><select>${ options }</select></td></tr>
<tr><td></td><td><label><input type="checkbox">Auto start Access Point</label></td></tr>
</table>`;
		info( {
			  icon         : 'wifi'
			, title        : 'Wi-Fi'
			, content      : infowifi
			, boxwidth     : 250
			, values       : G.wlanconf
			, checkchanged : ( G.wlan ? 1 : 0 )
			, cancel       : function() {
				$( '#wlan' ).prop( 'checked', G.wlan );
			}
			, ok           : function() {
				notify( 'Wi-Fi', G.wlan ? 'Change ...' : 'Enable ...', 'wifi' );
				bash( [ 'wlanset', ...infoVal() ] );
			}
		} );
	}, 'json' );
} );
$( '#i2smodulesw' ).click( function() {
	// delay to show switch sliding
	setTimeout( function() {
		$( '#i2smodulesw' ).prop( 'checked', 0 );
		$( '#divi2smodulesw' ).addClass( 'hide' );
		$( '#divi2smodule' )
			.removeClass( 'hide' )
			.find( '.selectric' ).click();
	}, 200 );
} );
$( '#i2smodule' ).change( function() {
	var aplayname = $( this ).val();
	var output = $( this ).find( ':selected' ).text();
	if ( aplayname !== 'none' ) {
		notify( 'Audio I&#178;S', 'Enable ...', 'volume' );
	} else {
		aplayname = 'onboard';
		output = '';
		notify( 'I&#178;S Module', 'Disable ...', 'volume' );
	}
	bash( [ 'i2smodule', aplayname, output ] );
} ).on( 'selectric-close', function() { // fix: toggle switch / select on 'Disable'
	setTimeout( function() {
		if ( $( '#i2smodule' ).val() !== 'none' ) {
			$( '#divi2smodulesw' ).addClass( 'hide' );
			$( '#divi2smodule' ).removeClass( 'hide' );
		} else {
			$( '#divi2smodulesw' ).removeClass( 'hide' );
			$( '#divi2smodule' ).addClass( 'hide' );
		}
	}, 300 );
} );
$( '#gpioimgtxt' ).click( function() {
	if ( $( '#gpiopin' ).is( ':hidden' ) && $( '#gpiopin1' ).is( ':hidden' ) ) {
		$( '#gpiopin' ).slideToggle();
		$( '#fliptxt, #close-img' ).toggle();
		$( this ).find( 'i' ).toggleClass( 'fa-chevron-down fa-chevron-up' )
	} else {
		$( '#gpiopin, #gpiopin1' ).css( 'display', 'none' );
		$( '#fliptxt' ).hide();
		$( this ).find( 'i' )
			.removeAttr( 'class' )
			.addClass( 'fa fa-chevron-down' );
	}
} );
$( '#gpiopin, #gpiopin1' ).click( function() {
	$( '#gpiopin, #gpiopin1' ).toggle();
} );
$( '#setting-lcdchar' ).click( function() {
	var radioaddr = '<td>Address</td>';
	G.lcdcharaddr.forEach( function( el ) {
		radioaddr += '<td><label><input type="radio" name="address" value="'+ el +'">0x'+ el.toString( 16 ) +'</label></td>';
	} );
	var optpins = '<select>';
	$.each( pin2gpio, function( k, v ) {
		optpins += '<option value='+ k +'>'+ k +'</option>';
	} );
	optpins += '</select>';
	var infolcdchar = `\
<table>
<tr id="cols"><td width="135">Size</td>
	<td width="80"><label><input type="radio" name="cols" value="20">20x4</label></td>
	<td width="80"><label><input type="radio" name="cols" value="16">16x2</label></td>
</tr>
<tr><td>Char<wide>acter</wide> Map</td>
	<td><label><input type="radio" name="charmap" value="A00">A00</label></td>
	<td><label><input type="radio" name="charmap" value="A02">A02</label></td>
</tr>
<tr><td>Interface</td>
	<td><label><input type="radio" name="inf" value="i2c">I&#178;C</label></td>
	<td><label><input type="radio" name="inf" value="gpio">GPIO</label></td>
</tr>
<tr id="i2caddress" class="i2c">${ radioaddr }</tr>
<tr class="i2c"><td>I&#178;C Chip</td>
	<td colspan="2">
	<select id="i2cchip">
		<option value="PCF8574">PCF8574</option>
		<option value="MCP23008">MCP23008</option>
		<option value="MCP23017">MCP23017</option>
	</select>
	</td>
</tr>
</table>
<table class="gpio">
<tr><td class="gpiosvg" colspan="8" style="padding-top: 10px;">${ gpiosvg }</td></tr>
<tr><td>RS</td><td>${ optpins }</td><td>RW</td><td>${ optpins }</td><td>E</td><td>${ optpins }</td><td></td><td></td></tr>
<tr><td>D4</td><td>${ optpins }</td><td>D5</td><td>${ optpins }</td><td>D6</td><td>${ optpins }</td><td>D7</td><td>${ optpins }</td></tr>
</table>
<table>
<tr><td width="63"></td><td><label><input id="backlight" type="checkbox">Sleep <gr>(60s)</gr></label></td></tr>
</table>`;
	// cols charmap inf address chip pin_rs pin_rw pin_e pins_data backlight
	var i2c = G.lcdcharconf[ 2 ] === 'i2c';
	info( {
		  icon          : 'lcdchar'
		, title         : 'Character LCD'
		, content       : infolcdchar
		, boxwidth      : 180
		, values        : G.lcdcharconf
		, checkchanged  : ( G.lcdchar ? 1 : 0 )
		, beforeshow    : function() {
			$( '#infoContent .gpio td:even' )
				.css( 'width', 60 )
				.find( '.selectric-wrapper, .selectric' )
				.css( 'width', 60 );
			$( '#infoContent .gpio td:odd' ).css( {
				  width           : 25
				, 'padding-right' : 1
				, 'text-align'    : 'right'
			} );
			$( '.gpio, .gpio .selectric-wrapper' ).css( 'font-family', 'Inconsolata' );
			$( '#infoContent svg .power' ).remove();
			$( '.i2c' ).toggleClass( 'hide', !i2c );
			$( '.gpio' ).toggleClass( 'hide', i2c );
			$( '#infoContent input[name=inf]' ).change( function() {
				i2c = $( '#infoContent input[name=inf]:checked' ).val() === 'i2c';
				$( '.i2c' ).toggleClass( 'hide', !i2c );
				$( '.gpio' ).toggleClass( 'hide', i2c );
			} );
		}
		, cancel        : function() {
			$( '#lcdchar' ).prop( 'checked', G.lcdchar );
		}
		, buttonlabel   : [ '<i class="fa fa-plus-r"></i>Logo', '<i class="fa fa-screenoff"></i>Sleep' ]
		, buttoncolor   : [ '', orange ]
		, button        : !G.lcdchar ? '' : [ 
			  function() { bash( '/srv/http/bash/lcdchar.py logo' ) }
			, function() { bash( '/srv/http/bash/lcdchar.py off' ) }
		]
		, buttonnoreset : 1
		, ok            : function() {
			bash( [ 'lcdcharset', ...infoVal() ] );
			notify( 'Character LCD', G.lcdchar ? 'Change ...' : 'Enabled ...', 'lcdchar' );
		}
	} );
} );
$( '#setting-powerbutton' ).click( function() {
	var offpin = '';
	var ledpin = '';
	var respin = '';
	$.each( pin2gpio, function( k, v ) {
		offpin += '<option value='+ k +'>'+ k +'</option>';
		if ( k != 5 ) {
			ledpin += '<option value='+ k +'>'+ k +'</option>';
			respin += '<option value='+ v +'>'+ k +'</option>';
		}
	} );
	var infopowerbutton = `\
<table>
<tr><td width="70">On</td>
	<td><input type="text" disabled></td>
</tr>
<tr><td>Off</td>
	<td><select >${ offpin }</select></td>
</tr>
<tr><td>LED</td>
	<td><select >${ ledpin }</select></td>
</tr>
<tr class="reserved hide"><td>Reserved</td>
	<td><select >${ respin }</select></td>
</tr>
</table>`;
	info( {
		  icon         : 'power'
		, title        : 'Power Button'
		, content      : gpiosvg + infopowerbutton
		, boxwidth     : 80
		, values       : [ 5, ...G.powerbuttonconf ]
		, checkchanged : ( G.powerbutton ? 1 : 0 )
		, beforeshow   : function() {
			$( '#infoContent .reserved' ).toggleClass( 'hide', G.powerbuttonconf[ 0 ] == 5 );
			$( '#infoContent select:eq( 0 )' ).change( function() {
				$( '#infoContent .reserved' ).toggleClass( 'hide', $( this ).val() == 5 );
			} );
		}
		, cancel       : function() {
			$( '#powerbutton' ).prop( 'checked', G.powerbutton );
		}
		, ok           : function() {
			bash( [ 'powerbuttonset', ...infoVal().slice( 1 ) ] );
			notify( 'Power Button', G.powerbutton ? 'Change ...' : 'Enable ...', 'power' );
		}
	} );
} );
$( '#setting-rotaryencoder' ).click( function() {
	var pin = '<td colspan="3"><select >';
	$.each( pin2gpio, function( k, v ) {
		pin += '<option value='+ v +'>'+ k +'</option>';
	} );
	pin += '</select></td>';
	var step = '';
	[ 1, 2, 4 ].forEach( function( v ) {
		step += '<td style="width: 55px"><label><input type="radio" name="step" value="'+ v +'">'+ v +'</label></td>'
	} );
	var inforotaryencoder = `\
<table>
<tr><td>CLK</td>${ pin }</tr>
<tr><td>DT</td>${ pin }</tr>
<tr><td>SW</td>${ pin }</tr>
<tr><td>Each step <gr>(%)</gr></td>${ step }</tr>
</table>`;
	info( {
		  icon         : 'volume'
		, title        : 'Rotary Encoder'
		, content      : gpiosvg + inforotaryencoder
		, boxwidth     : 90
		, values       : G.rotaryencoderconf
		, checkchanged : ( G.rotaryencoder ? 1 : 0 )
		, beforeshow   : function() {
			$( '#infoContent svg .power' ).remove();
		}
		, cancel       : function() {
			$( '#rotaryencoder' ).prop( 'checked', G.rotaryencoder );
		}
		, ok           : function() {
			bash( [ 'rotaryencoderset', ...infoVal() ] );
			notify( 'Rotary Encoder', G.rotaryencoder ? 'Change ...' : 'Enable ...', 'volume' );
		}
	} );
} );
$( '#setting-relays' ).click( function() {
	location.href = 'settings.php?p=relays';
} );
$( '#setting-mpdoled' ).click( function() {
	info( {
		  icon         : 'mpdoled'
		, title        : 'Spectrum OLED'
		, selectlabel  : 'Type'
		, content      : `\
<table>
<tr><td>Controller</td>
<td><select class="oledchip">
	<option value="1">SSD130x SPI</option>
	<option value="3">SSD130x I²C</option>
	<option value="4">Seeed I²C</option>
	<option value="6">SH1106 I²C</option>
	<option value="7">SH1106 SPI</option>
</select></td></tr>
<tr class="baud"><td>Refresh <gr>(baud)</gr></td>
<td><select>
	<option value="400000">400000</option>
	<option value="800000">800000</option>
	<option value="1200000">1200000</option>
</select></td></tr>
</table>`
		, values       : G.mpdoledconf
		, checkchanged : ( G.mpdoled ? 1 : 0 )
		, boxwidth     : 140
		, beforeshow   : function() {
			var i2c = !G.mpdoled || ( G.mpdoled && G.mpdoledconf[ 1 ] );
			$( '.baud' ).toggleClass( 'hide', !i2c );
			$( '.oledchip' ).change( function() {
				var val = $( this ).val();
				$( '.baud' ).toggleClass( 'hide', val < 3 || val > 6 );
			} );
		}
		, cancel       : function() {
			$( '#mpdoled' ).prop( 'checked', G.mpdoled );
		}
		, buttonlabel  : '<i class="fa fa-plus-r"></i>Logo'
		, button       : !G.mpdoled ? '' : function() {
			bash( '/srv/http/bash/cmd.sh mpdoledlogo' );
		}
		, ok           : function() {
			notify( 'Spectrum OLED', G.mpdoled ? 'Change ...' : 'Enable ...', 'mpdoled' );
			bash( [ 'mpdoledset', ...infoVal() ] );
		}
	} );
} );
$( '#setting-lcd' ).click( function() {
	info( {
		  icon         : 'lcd'
		, title        : 'TFT 3.5" LCD'
		, selectlabel  : 'Type'
		, select       : {
			  'Generic'               : 'tft35a'
			, 'Waveshare (A)'         : 'waveshare35a'
			, 'Waveshare (B)'         : 'waveshare35b'
			, 'Waveshare (B) Rev 2.0' : 'waveshare35b-v2'
			, 'Waveshare (C)'         : 'waveshare35c'
		}
		, values       : G.lcdmodel
		, checkchanged : ( G.lcd ? 1 : 0 )
		, boxwidth     : 190
		, buttonlabel  : ( !G.lcd ? '' : 'Calibrate' )
		, button       : ( !G.lcd ? '' : function() {
			info( {
				  icon    : 'lcd'
				, title   : 'TFT LCD'
				, message : 'Calibrate touchscreen?'
							+'<br>(Get stylus ready.)'
				, ok      : function() {
					notify( 'Calibrate Touchscreen', 'Start ...', 'lcd' );
					bash( [ 'lcdcalibrate' ] );
				}
			} );
		} )
		, cancel    : function() {
			$( '#lcd' ).prop( 'checked', G.lcd );
		}
		, ok           : function() {
			notify( 'TFT 3.5" LCD', G.lcd ? 'Change ...' : 'Enable ...', 'lcd' );
			bash( [ 'lcdset', infoVal() ] );
		}
	} );
} );
$( '#setting-vuled' ).click( function() {
	var opt = '';
	$.each( pin2gpio, function( k, v ) {
		opt += '<option value="'+ v +'">'+ k +'</option>';
	} );
	var htmlpins = '';
	for ( i = 1; i < 8; i++ ) {
		htmlpins += '<tr><td>'+ i +'/7</td><td><select>'+ opt +'</select></td></tr>';
	}
	info( {
		  icon         : 'led'
		, title        : 'VU LED'
		, message      : gpiosvg
		, select       : htmlpins
		, values       : G.vuledconf
		, checkchanged : 1
		, boxwidth     : 80
		, cancel        : function() {
			$( '#vuled' ).prop( 'checked', G.vuled );
		}
		, ok           : function() {
			notify( 'VU LED', 'Change ...', 'led' );
			bash( [ 'vuledset', ...infoVal() ] );
		}
	} );
} );
$( '#ledcalc' ).click( function() {
	info( {
		  icon       : 'led'
		, title      : 'LED Resister Calculator'
		, textlabel  : [ 'GPIO <gr>(V)</gr>', 'Current <gr>(mA)</gr>', 'LED forward voltage <gr>(V)</gr>', 'Resister <gr>(&#8486;)</gr>' ]
		, values     : [ 3.3, 5 ]
		, boxwidth   : 70
		, beforeshow : function() {
			$( '#infoContent input' ).prop( 'disabled', 1 );
			$( '#infoContent input:eq( 2 )' )
				.prop( 'disabled', 0 )
				.keyup( function() {
					var fv = $( this ).val();
					if ( fv > 3.3 ) {
						var ohm = '( > 3.3V)';
					} else {
						var ohm = fv ? Math.round( ( 3.3 - fv ) / 0.005 ) : '';
					}
					$( '#infoContent input:eq( 3 )' ).val( ohm );
				} );
		}
		, okno       : 1
	} );
} );
$( '#hostname' ).on( 'mousedown touchdown', function() {
	info( {
		  icon         : 'plus-r'
		, title        : 'Player Name'
		, textlabel    : 'Name'
		, values       : G.hostname
		, checkblank   : 1
		, checkchanged : 1
		, beforeshow   : function() {
			$( '#infoContent input' ).keyup( function() {
				$( this ).val( $( this ).val().replace( /[^a-zA-Z0-9-]+/g, '' ) );
			} );
		}
		, ok           : function() {
			notify( 'Name', 'Change ...', 'plus-r' );
			bash( [ 'hostname', infoVal() ] );
		}
	} );
} );
$( '#timezone' ).change( function( e ) {
	notify( 'Timezone', 'Change ...', 'globe' );
	bash( [ 'timezone', $( this ).val() ] );
} );
$( '#setting-timezone' ).click( function() {
	bash( [ 'mirrorlist' ], function( list ) {
		var lL = list.code.length;
		var selecthtml = '<select>';
		for ( i = 0; i < lL; i++ ) selecthtml += '<option value="'+ list.code[ i ] +'">'+ list.country[ i ] +'</option>';
		selecthtml += '</select>';
		var content = `
<table>
<tr><td>NTP</td><td><input type="text"></td></tr>
<tr><td>Package</td><td>${ selecthtml }</td></tr>
</table>`
		info( {
			  icon         : 'globe'
			, title        : 'Servers'
			, content      : content
			, boxwidth     : 240
			, values       : [ G.ntp, list.current ]
			, checkchanged : 1
			, checkblank   : [ 0 ]
			, ok           : function() {
				var values = infoVal();
				if ( values[ 0 ] !== G.ntp ) notify( 'NTP', 'Sync ...', 'globe' );
				bash( [ 'servers', ...values ], bannerHide );
			}
		} );
		bannerHide();
	}, 'json' );
} );
$( '#setting-soundprofile' ).click( function() {
	var textlabel = [
		  'sched_latency_ns'
		, 'vm.swappiness'
		, 'eth0 mtu'
		, 'eth0 txqueuelen'
	];
	var radio = {
		  Default   : '18000000 60 1500 1000'
		, RuneAudio : '1500000 0 1500 1000'
		, ACX       : '850000 0 1500 4000'
		, Orion     : '500000 20 1000 4000'
		, OrionV2   : '120000 0 1000 4000'
		, OrionV3   : '1500000 0 1000 4000'
		, OrionV4   : '145655 60 1000 4000'
		, Um3ggh1U  : '500000 0 1500 1000'
		, Custom    : '0'
	}
	var soundprofileconf = G.soundprofileconf.join( ' ' );
	var radioval = Object.values( radio );
	var rchecked = radioval.includes( soundprofileconf ) ? soundprofileconf : '0';
	G.soundprofileconf.push( rchecked );
	info( {
		  icon         : 'sliders'
		, title        : 'Kernel Sound Profile'
		, textlabel    : textlabel
		, boxwidth     : 110
		, radio        : radio
		, radiocolumn  : 1
		, values       : G.soundprofileconf
		, checkchanged : 1
		, checkblank   : 1
		, beforeshow   : function() {
			for ( i = 4; i < 9; i++ ) $( '#infoContent tr:eq( '+ i +') td:first-child' ).remove();
			var values, val;
			var $text = $( '#infoContent input:text' );
			var $radio = $( '#infoContent input:radio' );
			$radio.last().prop( 'disabled', true );
			$text.keyup( function() {
				var $this = $( this )
				$this.val( $this.val().replace( /[^0-9]/, '' ) );
				values = infoVal().slice( 0, -1 ).join( ' ' );
				if ( !radioval.includes( values ) ) values = 0;
				$radio.val( [ values ] );
			} );
			var iL = textlabel.length;
			$radio.change( function() {
				val = $( this ).val().split( ' ' );
				for ( i = 0; i < iL; i++ ) $text.eq( i ).val( val[ i ] );
			} );
		}
		, cancel       : function() {
			$( '#soundprofile' ).prop( 'checked', G.soundprofile );
		}
		, ok           : function() {
			bash( [ 'soundprofileset', ...infoVal() ] );
			notify( 'Kernel Sound Profile', G.soundprofile ? 'Change ...' : 'Enable ...', 'volume' );
		}
	} );
} );
$( '#shareddata' ).click( function() {
	if ( G.shareddata ) {
		info( {
			  icon    : 'networks'
			, title   : 'Shared Data'
			, message : 'Disable?'
			, cancel  : function() {
				$( '#shareddata' ).prop( 'checked', true );
			}
			, ok      : function() {
				bash( [ 'shareddatadisable' ] );
				notify( 'Shared Data', 'Disable ...', 'networks' );
			}
		} );
	} else {
		infoMount( 'shareddata' );
	}
} );
$( '#backup' ).click( function() {
	var backuptitle = 'Backup Settings';
	var icon = 'sd';
	notify( backuptitle, 'Process ...', 'sd blink' );
	bash( [ 'databackup' ], function( data ) {
		if ( data == 1 ) {
			notify( backuptitle, 'Download ...', icon );
			fetch( '/data/tmp/backup.gz' )
				.then( response => response.blob() )
				.then( blob => {
					var url = window.URL.createObjectURL( blob );
					var a = document.createElement( 'a' );
					a.style.display = 'none';
					a.href = url;
					a.download = 'backup.gz';
					document.body.appendChild( a );
					a.click();
					setTimeout( () => {
						a.remove();
						window.URL.revokeObjectURL( url );
						bannerHide();
					}, 1000 );
				} ).catch( () => {
					info( {
						  icon    : icon
						, title   : backuptitle
						, message : '<wh>Warning!</wh><br>File download failed.'
					} );
					bannerHide();
				} );
		} else {
			info( {
				  icon    : icon
				, title   : backuptitle
				, message : 'Backup failed.'
			} );
			bannerHide();
		}
	} );
	$( '#backup' ).prop( 'checked', 0 );
} );
$( '#restore' ).click( function() {
	var icon = 'restore';
	var title = 'Restore Settings';
	info( {
		  icon        : icon
		, title       : title
		, message     : 'Restore from:'
		, radio       : {
			  'Backup file <code>*.gz</code>' : 'restore'
			, 'Reset to default'              : 'reset'
		}
		, values      : 'restore'
		, fileoklabel : '<i class="fa fa-restore"></i>Restore'
		, filetype    : '.gz'
		, beforeshow  : function() {
			$( '#infoContent input' ).click( function() {
				if ( infoVal() !== 'restore' ) {
					$( '#infoFilename' ).addClass( 'hide' );
					$( '#infoFileBox' ).val( '' );
					$( '#infoFileLabel' ).addClass( 'hide infobtn-primary' );
					$( '#infoOk' )
						.html( '<i class="fa fa-reset"></i>Reset' )
						.css( 'background-color', orange )
						.removeClass( 'hide' );
				} else {
					$( '#infoOk' )
						.html( '<i class="fa fa-restore"></i>Restore' )
						.css( 'background-color', '' )
						.addClass( 'hide' );
					$( '#infoFileLabel' ).removeClass( 'hide' );
				}
			} );
		}
		, ok          : function() {
			notify( 'Restore Settings', 'Restore ...', 'sd' );
			if ( infoVal() === 'reset' ) {
				bash( '/srv/http/bash/datareset.sh', bannerHide );
			} else {
				var file = $( '#infoFileBox' )[ 0 ].files[ 0 ];
				var formData = new FormData();
				formData.append( 'cmd', 'datarestore' );
				formData.append( 'file', file );
				$.ajax( {
					  url         : 'cmd.php'
					, type        : 'POST'
					, data        : formData
					, processData : false  // no - process the data
					, contentType : false  // no - contentType
					, success     : function( data ) {
						if ( data == -1 ) {
							info( {
								  icon    : icon
								, title   : title
								, message : 'File upload failed.'
							} );
							bannerHide();
							loaderHide();
						}
					}
				} );
			}
			setTimeout( loader, 0 );
		}
	} );
	$( '#restore' ).prop( 'checked', 0 );
} );
$( '.listtitle' ).click( function() {
	var $this = $( this );
	var $chevron = $this.find( 'i' );
	var $list = $this.next();
	if ( $list.hasClass( 'hide' ) ) {
		$chevron
			.removeClass( 'fa-chevron-down' )
			.addClass( 'fa-chevron-up' );
		if ( $list.html() ) {
			$list.removeClass( 'hide' );
		} else {
			bash( 'pacman -Qq', function( list ) {
				var list = list.split( '\n' );
				pkghtml = '';
				list.forEach( function( pkg ) {
					pkghtml += '<bl>'+ pkg +'</bl><br>';
				} );
				$list
					.html( pkghtml.slice( 0, -4 ) )
					.removeClass( 'hide' );
			} );
		}
	} else {
		$chevron
			.removeClass( 'fa-chevron-up' )
			.addClass( 'fa-chevron-down' );
		$list.addClass( 'hide' );
	}
} );
$( '.list' ).on( 'click', 'bl', function() {
	if ( localhost ) return
	
	var pkg = $( this ).text();
	if ( [ 'alsaequal', 'audio_spectrum_oled', 'bluez-alsa', 'cava', 'hfsprogs', 'matchbox-window-manager'
			, 'mpdscribble', 'nginx-mainline-pushstream', 'snapcast', 'upmpdcli' ].includes( pkg ) ) {
		if ( pkg === 'bluez-alsa' ) pkg = pkg.replace( 'bluez-alsa', 'bluez-alsa-git' );
		window.open( 'https://aur.archlinux.org/packages/'+ pkg );
	} else {
		window.open( 'https://archlinuxarm.org/packages/aarch64/'+ pkg );
	}
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

function infoMount( values ) {
	if ( values === 'shareddata' ) {
		var values = [ 'cifs', '192.168.1.', '', '', '', '' ];
		var shareddata = 1;
	} else if ( values.length === 6 ) {
		var shareddata = 1;
	} else {
		var shareddata = 0;
	}
	var htmlmount = `\
<table id="tblinfomount">
<tr><td>Type</td>
	<td><label><input type="radio" name="inforadio" value="cifs" checked>CIFS</label>&emsp;
	<label><input type="radio" name="inforadio" value="nfs">NFS</label></td>
</tr>`;
	if ( !shareddata ) htmlmount += `\
<tr><td>Name</td>
	<td><input type="text"></td>
</tr>`;
	htmlmount += `\
<tr><td>IP</td>
	<td><input type="text"></td>
</tr>
<tr id="sharename"><td>Share name</td>
	<td><input type="text"></td>
</tr>
<tr class="guest"><td>User</td>
	<td><input type="text"></td>
</tr>
<tr class="guest"><td>Password</td>
	<td><input type="password" checked></td><td><i class="fa fa-eye fa-lg"></i></td>
</tr>
<tr><td>Options</td>
	<td><input type="text"></td>
</tr>`;
	if ( !shareddata ) htmlmount += `\
<tr><td></td>
	<td><label><input type="checkbox" checked>Update Library on mount</label></td>
</tr>`;
	htmlmount += '</table>';
	info( {
		  icon       : 'networks'
		, title      : shareddata ? 'Shared Data' : 'Add Network Storage'
		, content    : htmlmount
		, values     : values || [ 'cifs', '', '192.168.1.', '', '', '', '', true ]
		, beforeshow : function() {
			$( '#infoContent td:eq( 0 )' ).css( 'width', 90 );
			$( '#infoContent td:eq( 1 )' ).css( 'width', 230 );
			var $sharelabel = $( '#sharename td:eq( 0 )' );
			var $share = $( '#sharename input' );
			var $guest = $( '.guest' );
			$( '#infoContent input:radio' ).change( function() {
				if ( $( this ).val() === 'nfs' ) {
					$sharelabel.text( 'Share path' );
					$guest.addClass( 'hide' );
					$share.val( '/'+ $share.val() );
				} else {
					$sharelabel.text( 'Share name' );
					$guest.removeClass( 'hide' );
					$share.val( $share.val().replace( /\//g, '' ) );
				}
			} );
		}
		, cancel     : function() {
			$( '#shareddata' ).prop( 'checked', false );
		}
		, ok         : function() {
			var values = infoVal();
			bash( [ shareddata ? 'shareddata' : 'mount', ...values ], function( error ) {
				if ( error ) {
					info( {
						  icon    : 'networks'
						, title   : shareddata ? 'Shared Data' : 'Mount Share'
						, message : error
						, ok      : function() {
							infoMount( values );
						}
					} );
					bannerHide();
				} else {
					refreshData();
				}
			} );
			notify( shareddata ? 'Shared Data' : 'Network Mount', 'Mount ...', 'networks' );
		}
	} );
}
function renderPage( list ) {
	$( '#systemvalue' ).html(
		  'rAudio '+ G.version +' <gr>• '+ G.versionui +'</gr>'
		+'<br>'+ G.kernel.replace( /-r.*H (.*)/, ' <gr>• $1</gr>' )
		+'<br>'+ G.firmware
		+'<br>'+ G.rpimodel.replace( /(Rev.*)$/, '<wide>$1</wide>' )
		+'<br>'+ G.soc + ' <gr>•</gr> '+ G.socram
		+'<br>'+ G.soccpu
	);
	renderStatus();
	var html = '';
	$.each( G.list, function( i, val ) {
		if ( val.mounted ) {
			var dataunmounted = '';
			var dot = '<grn>&ensp;•&ensp;</grn>';
		} else {
			var dataunmounted = ' data-unmounted="1"';
			var dot = '<red>&ensp;•&ensp;</red>';
		}
		html += '<li '+ dataunmounted;
		html += '><i class="fa fa-'+ val.icon +'"></i><wh class="mountpoint">'+ val.mountpoint +'</wh>'+ dot
		html += '<gr class="source">'+ val.source +'</gr>';
		html +=  val.size ? '&ensp;'+ val.size +'</li>' : '</li>';
	} );
	$( '#list' ).html( html );
	if ( 'bluetooth' in G || 'wlan' in G ) {
		if ( 'bluetooth' in G ) {
			$( '#bluetooth' ).parent().prev().toggleClass( 'single', !G.bluetooth );
		} else {
			$( '#divbluetooth' ).addClass( 'hide' );
		}
		if ( 'wlan' in G ) {
			$( '#wlan' )
				.toggleClass( 'disabled', G.hostapd || G.wlanconnected )
				.parent().prev().toggleClass( 'single', !G.wlan );
		} else {
			$( '#divwlan' ).addClass( 'hide' );
		}
	} else {
		$( '#divbluetooth' ).parent().addClass( 'hide' );
	}
	$( '#i2smodule' ).val( 'none' );
	$( '#i2smodule option' ).filter( function() {
		var $this = $( this );
		return $this.text() === G.audiooutput && $this.val() === G.audioaplayname;
	} ).prop( 'selected', true );
	G.i2senabled = $( '#i2smodule' ).val() !== 'none';
	$( '#divi2smodulesw' ).toggleClass( 'hide', G.i2senabled );
	$( '#divi2smodule' ).toggleClass( 'hide', !G.i2senabled );
	$( '#divsoundprofile' ).toggleClass( 'hide', !G.soundprofileconf );
	$( '#hostname' ).val( G.hostname );
	$( '#avahiurl' ).text( G.hostname +'.local' );
	$( '#timezone' ).val( G.timezone );
	$( '#shareddata' ).prop( 'checked', G.shareddata );
	showContent();
}
function renderStatus() {
	var status = G.cpuload.replace( / /g, ' <gr>•</gr> ' );
	status += + G.cputemp < 80 ? '<br>'+ G.cputemp +' °C' : '<br><red><i class="fa fa-warning blink red"></i>&ensp;'+ G.cputemp +' °C</red>';
	status += '<br>'+ G.time.replace( ' ', ' <gr>•</gr> ' ) +'<wide>&emsp;'+ G.timezone.replace( '/', ' · ' ) +'</wide>'
			+'<br>'+ G.uptime +'<wide>&emsp;<gr>since '+ G.uptimesince.replace( ' ', ' • ' ) +'</gr></wide>'
			+'<br>'+ ( G.startup ? G.startup.replace( /\(/g, '<gr>' ).replace( /\)/g, '</gr>' ) : 'Booting ...' );
	if ( !G.online ) status += '<br><i class="fa fa-warning"></i>&ensp;No Internet connection.';
	if ( G.throttled !== '0x0' ) { // https://www.raspberrypi.org/documentation/raspbian/applications/vcgencmd.md
		status += '<br><i class="fa fa-warning';
		var bits = parseInt( G.throttled ).toString( 2 ); // 20 bits: 19..0 ( hex > decimal > binary )
		if ( bits.slice( -1 ) == 1 ) {                    // bit# 0  - undervoltage now
			status += ' blink red"></i>&ensp;<red>Voltage under 4.7V</red> - currently detected.';
		} else if ( bits.slice( -19, 1 ) == 1 ) {         // bit# 19 - undervoltage occured
			status += '"></i>&ensp;Voltage under 4.7V - occurred.';
		}
	}
	$( '#status' ).html( status );
}
