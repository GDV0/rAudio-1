$( function() { // document ready start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

var setmpdconf = '/srv/http/bash/settings/player-conf.sh';
var warning = `
<wh><i class="fa fa-warning fa-lg"></i>&ensp;Lower amplifier volume.</wh>

Signal will be set to original level (0dB).
Beware of too high volume from speakers.`;

$( '#playback' ).click( function() {
	if ( !$( this ).hasClass( 'disabled' ) ) {
		var cmd = G.player === 'mpd' ? 'mpcplayback' : 'playerstop';
		bash( '/srv/http/bash/cmd.sh '+ cmd );
	}
} );
$( '#setting-btreceiver' ).click( function() {
	bash( [ 'volumebtget' ], function( voldb ) {
		var voldb = voldb.split( ' ' );
		var vol = voldb[ 0 ];
		var db = voldb[ 1 ];
		info( {
			  icon          : 'volume'
			, title         : 'Bluetooth Volume'
			, message       : G.btaplayname.replace( / - A2DP$/, '' )
			, rangevalue    : vol
			, footer        : db +' dB'
			, beforeshow    : function() {
				$( '#infoButtons a' ).toggleClass( 'hide', db === '0.00' );
				$( '#infoRange input' ).on( 'click input keyup', function() {
					bash( 'amixer -D bluealsa -q sset "'+ G.btaplayname +'" '+ $( this ).val() +'%' );
				} ).on( 'touchend mouseup keyup', function() {
					bash( [ 'volumebtsave', $( this ).val(), G.btaplayname ] );
				} );
			}
			, buttonnoreset : 1
			, buttonlabel   : '<i class="fa fa-set0"></i>0dB'
			, button        : function() {
				bash( [ 'volumebt0db', G.btaplayname ] );
			}
			, okno          : 1
		} );
	} );
} );
$( '#audiooutput' ).change( function() {
	notify( 'Audio Output Device', 'Change ...', 'mpd' );
	bash( [ 'audiooutput', $( this ).val() ] );
} );
$( '#hwmixer' ).change( function() {
	var hwmixer = $( this ).val();
	notify( 'Hardware Mixer', 'Change ...', 'mpd' );
	bash( [ 'hwmixer', device.aplayname, hwmixer ] );
} );
$( '#setting-hwmixer' ).click( function() {
	var novolume = device.mixertype === 'none';
	bash( [ 'volumeget', 'db' ], function( voldb ) {
		var voldb = voldb.split( ' ' );
		var vol = voldb[ 0 ];
		var db = voldb[ 1 ];
		var card = G.asoundcard;
		var control = device.hwmixer;
		if ( novolume ) {
			info( {
				  icon       : 'volume'
				, title      : 'Mixer Device Volume'
				, message    : control
				, rangevalue : vol
				, footer     : '0dB (No Volume)'
				, beforeshow    : function() {
					$( '#infoRange input' ).prop( 'disabled', 1 );
				}
				, okno       : 1
			} );
			return
		}
		
		var toggle = function() { $( '#infoContent, .warning, #infoButtons a' ).toggleClass( 'hide' ) }
		info( {
			  icon          : 'volume'
			, title         : 'Mixer Device Volume'
			, message       : control
			, rangevalue    : vol
			, footer        : db +' dB'
			, beforeshow    : function() {
				$( '#infoContent' ).after( '<div class="infomessage warning hide">'+ warning +'</div>' );
				$( '.extrabtn' ).toggleClass( 'hide', db === '0.00' );
				$( '#infoRange input' ).on( 'click input keyup', function() {
					bash( 'amixer -c '+ card +' -Mq sset "'+ control +'" '+ $( this ).val() +'%' );
				} ).on( 'touchend mouseup keyup', function() {
					bash( [ 'volumeget', 'push' ] );
				} );
				$( '.extrabtn:eq( 0 ), #infoOk' ).addClass( 'hide' );
			}
			, buttonnoreset : 1
			, buttonlabel   : [ 'Back', '<i class="fa fa-set0"></i>0dB' ]
			, buttoncolor   : [ $( '.switchlabel' ).css( 'background-color' ), '' ]
			, button        : [ toggle, toggle ]
			, oklabel       : 'OK'
			, ok            : function() {
				bash( [ 'volume0db', card, control ] );
				toggle();
			}
		} );
	} );
} );
$( '#mixertype' ).change( function() {
	var mixertype = $( this ).val();
	if ( mixertype === 'none' ) {
		info( {
			  icon    : 'volume'
			, title   : 'Volume Control'
			, message : warning
			, cancel  : function() {
				$( '#mixertype' )
					.val( device.mixertype )
					.selectric( 'refresh' );
			}
			, ok      : function() {
				setMixerType( mixertype );
			}
		} );
	} else {
		setMixerType( mixertype );
	}
} );
$( '#novolume' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	if ( checked ) {
		info( {
			  icon    : 'volume'
			, title   : 'No Volume'
			, message : warning
			, cancel  : function() {
				$( '#novolume' ).prop( 'checked', G.novolume );
			}
			, ok      : function() {
				notify( 'No Volume', 'Enable ...', 'mpd' );
				bash( [ 'novolume', device.aplayname, device.card, device.hwmixer ] );
			}
		} );
	} else {
		info( {
			  icon         : 'volume'
			, title        : 'No Volume'
			, message      : `\
No volume</wh> will be disabled on:
&emsp; • Select a Mixer Control
&emsp; • Enable any Volume options`
			, messagealign : 'left'
		} );
		$( this ).prop( 'checked', 1 );
	}
} );
$( '#dop' ).click( function() {
	var checked = $( this ).prop( 'checked' );
	notify( 'DSP over PCM', checked, 'mpd' );
	bash( [ 'dop', checked, device.aplayname ] );
} );
$( '#setting-crossfade' ).click( function() {
	info( {
		  icon         : 'mpd'
		, title        : 'Crossfade'
		, textlabel    : 'Seconds'
		, focus        : 0
		, boxwidth     : 60
		, values       : G.crossfadeconf
		, checkchanged : ( G.crossfade ? 1 : 0 )
		, checkblank   : 1
		, cancel       : function() {
			$( '#crossfade' ).prop( 'checked', G.crossfade );
		}
		, ok           : function() {
			bash( [ 'crossfadeset', infoVal() ] );
			notify( 'Crossfade', G.crossfade ? 'Change ...' : 'Enable ...', 'mpd' );
		}
	} );
} );
$( '#setting-replaygain' ).click( function() {
	info( {
		  icon         : 'mpd'
		, title        : 'Replay Gain'
		, radio        : { Auto: 'auto', Album: 'album', Track: 'track' }
		, values       : G.replaygainconf
		, checkchanged : ( G.replaygain ? 1 : 0 )
		, cancel       : function() {
			$( '#replaygain' ).prop( 'checked', G.replaygain );
		}
		, ok           : function() {
			bash( [ 'replaygainset', infoVal() ] );
			notify( 'Replay Gain', G.replaygain ? 'Change ...' : 'Enable ...', 'mpd' );
		}
	} );
} );
$( '.filetype' ).click( function() {
	if ( $( '#divfiletype' ).is( ':empty' ) ) {
		bash( [ 'filetype' ], function( data ) {
			$( '#divfiletype' )
				.html( data )
				.toggleClass( 'hide' );
		} );
	} else {
		$( '#divfiletype' ).toggleClass( 'hide' );
	}
} );
$( '#setting-buffer' ).click( function() {
	info( {
		  icon         : 'mpd'
		, title        : 'Custom Audio Buffer'
		, textlabel    : 'audio_buffer_size <gr>(kB)</gr>'
		, focus        : 0
		, footer       : '(default: 4096)'
		, footeralign  : 'right'
		, boxwidth     : 110
		, values       : G.bufferconf
		, checkchanged : ( G.buffer ? 1 : 0 )
		, checkblank   : 1
		, cancel       : function() {
			$( '#buffer' ).prop( 'checked', G.buffer );
		}
		, ok           : function() {
			bash( [ 'bufferset', infoVal() ] );
			notify( 'Custom Audio Buffer', G.buffer ? 'Change ...' : 'Enable ...', 'mpd' );
		}
	} );
} );
$( '#setting-bufferoutput' ).click( function() {
	info( {
		  icon         : 'mpd'
		, title        : 'Custom Output Buffer'
		, textlabel    : 'max_output_buffer_size <gr>(kB)</gr>'
		, focus        : 0
		, footer       : '(default: 8192)'
		, footeralign  : 'right'
		, boxwidth     : 110
		, values       : G.bufferoutputconf
		, checkchanged : ( G.bufferoutput ? 1 : 0 )
		, checkblank   : 1
		, cancel       : function() {
			$( '#bufferoutput' ).prop( 'checked', G.bufferoutput );
		}
		, ok           : function() {
			bash( [ 'bufferoutputset', infoVal() ] );
			notify( 'Custom Output Buffer', G.bufferoutput ? 'Change ...' : 'Enable ...', 'mpd' );
		}
	} );
} );
var soxrinfo = `\
<table>
<tr><td>Precision</td>
	<td><select>
		<option value="16">16</option>
		<option value="20">20</option>
		<option value="24">24</option>
		<option value="28">28</option>
		<option value="32">32</option>
		</select></td><td>&nbsp;<gr>bit</gr></td>
</tr>
<tr><td>Phase Response</td>
	<td><input type="text"></td><td style="width: 115px">&nbsp;<gr>0-100</gr></td>
</tr>
<tr><td>Passband End</td>
	<td><input type="text"></td><td>&nbsp;<gr>0-100%</gr></td>
</tr>
<tr><td>Stopband Begin</td>
	<td><input type="text"></td><td>&nbsp;<gr>100-150%</gr></td>
</tr>
<tr><td>Attenuation</td>
	<td><input type="text"></td><td>&nbsp;<gr>0-30dB</gr></td>
</tr>
<tr><td>Rolloff</td>
	<td colspan="2"><select>
			<option value="0">0 - Small</option>
			<option value="1">1 - Medium</option>
			<option value="2">2 - None</option>
			<option value="8">8 - High precision</option>
			<option value="16">16 - Double precision</option>
			<option value="32">32 - Variable rate</option>
		</select>
	</td>
</tr>
</table>`;
$( '#setting-soxr' ).click( function() {
	info( {
		  icon          : 'mpd'
		, title         : 'SoXR Custom Settings'
		, content       : soxrinfo
		, values        : G.soxrconf
		, checkchanged  : ( G.soxr ? 1 : 0 )
		, checkblank    : 1
		, beforeshow    : function() {
			var $extra = $( '#infoContent tr' ).eq( 5 );
			$extra.find( '.selectric, .selectric-wrapper' ).css( 'width', '100%' );
			$extra.find( '.selectric-items' ).css( 'min-width', '100%' );
		}
		, boxwidth      : 70
		, cancel        : function() {
			$( '#soxr' ).prop( 'checked', G.soxr );
		}
		, ok            : function() {
			bash( [ 'soxrset', ...infoVal() ] );
			notify( 'SoXR Custom Settings', G.soxr ? 'Change ...' : 'Enable ...', 'mpd' );
		}
	} );
} );
var custominfo = `\
<table width="100%">
<tr><td><code>/etc/mpd.conf</code></td></tr>
<tr><td><pre>
...
user                   "mpd"</pre></td></tr>
	<tr><td><textarea></textarea></td></tr>
	<tr><td><pre>
...
audio_output {
	...
	mixer_device   "hw:N"</pre></td></tr>
<tr><td><textarea style="padding-left: 39px"></textarea></td></tr>
<tr><td><pre style="margin-top: -20px">
}</pre></td></tr>
</table>`;
$( '#setting-custom' ).click( function() {
	bash( [ 'customget', device.aplayname ], function( val ) {
		var val = val.split( '^^' );
		var valglobal = val[ 0 ].trim(); // remove trailing
		var valoutput = val[ 1 ].trim();
		info( {
			  icon         : 'mpd'
			, title        : "User's Configurations"
			, content      : custominfo.replace( 'N', G.asoundcard )
			, values       : [ valglobal, valoutput ]
			, checkchanged : ( G.custom ? 1 : 0 )
			, cancel       : function() {
				$( '#custom' ).prop( 'checked', G.custom );
			}
			, ok           : function() {
				var values = infoVal();
				if ( !values[ 0 ] && !values[ 1 ] ) {
					bash( [ 'customdisable' ] );
					notify( "User's Custom Settings", 'Disable ...', 'mpd' );
					return
				}
				
				bash( [ 'customset', values[ 0 ], values[ 1 ], device.aplayname ], function( std ) {
					if ( std == -1 ) {
						bannerHide();
						info( {
							  icon    : 'mpd'
							, title   : "User's Configurations"
							, message : 'MPD failed with the added lines'
										+'<br>Restored to previous configurations.'
						} );
					}
				} );
				notify( "User's Custom Settings", G.custom ? 'Change ...' : 'Enable ...', 'mpd' );
			}
		} );
	} );
} );

} ); // document ready end <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

function playbackIcon() {
	$( '#playback' )
		.removeAttr( 'class' )
		.addClass( 'fa fa-'+ ( G.state === 'play' ? 'pause' : 'play' ) )
		.toggleClass( 'disabled', !G.state || ( G.player !== 'mpd' && G.state !== 'play' ) );
}
function renderPage() {
	playbackIcon();
	var htmlstatus =  G.version +'<br>'
					+'<i class="fa fa-song gr"></i>&ensp;'+ ( G.counts.song || 0 ).toLocaleString() +'&emsp; '
					+'<i class="fa fa-album gr"></i>&ensp;'+ ( G.counts.album || 0 ).toLocaleString() +'<wide>&emsp; '
					+'<i class="fa fa-webradio gr"></i>&ensp;'+ ( G.counts.webradio || 0 ).toLocaleString() +'</wide>';
	if ( !G.active ) htmlstatus += '<br><i class="fa fa-warning red"></i>&ensp;MPD not running'
	$( '#statusvalue' ).html( htmlstatus );
	if ( G.asoundcard != -1 ) {
		device = G.devices[ G.asoundcard ];
		G.novolume = device.mixertype === 'none' && !G.camilladsp && !G.crossfade && !G.equalizer && !G.normalization && !G.replaygain;
		var htmldevices = '';
		$.each( G.devices, function() {
			if ( this.aplayname !== 'Loopback' ) htmldevices += '<option value="'+ this.card +'">'+ this.name +'</option>';
		} );
		if ( G.btaplayname ) {
			$( '#divaudiooutput, #divhwmixer, #divmixertype, #divbitperfect' ).addClass( 'hide' );
			$( '#divbtreceiver' ).removeClass( 'hide' );
			$( '#btaplayname' ).html( '<option>'+ G.btaplayname.replace( / - A2DP$/, '' ) +'</option>' );
			$( '#setting-btreceiver' ).removeClass( 'hide' );
		} else {
			$( '#divaudiooutput, #divhwmixer, #divmixertype, #divbitperfect' ).removeClass( 'hide' );
			$( '#divbtreceiver' ).addClass( 'hide' );
			$( '#audiooutput' )
				.html( htmldevices )
				.val( G.asoundcard );
			var htmlhwmixer = device.mixermanual ? '<option value="auto">Auto</option>' : '';
			if ( 'mixerdevices' in device ) {
				device.mixerdevices.forEach( function( mixer ) {
					htmlhwmixer += '<option value="'+ mixer +'">'+ mixer +'</option>';
				} );
			}
			$( '#hwmixer' )
				.html( htmlhwmixer )
				.val( device.hwmixer );
			var htmlmixertype = '<option value="none">None / 0dB</option>';
			if ( device.mixers ) htmlmixertype += '<option value="hardware">Mixer device</option>';
			htmlmixertype += '<option value="software">MPD software</option>';
			$( '#mixertype' )
				.html( htmlmixertype )
				.val( device.mixertype );
			$( '#setting-hwmixer' ).toggleClass( 'hide', device.mixers === 0 );
			$( '#novolume' ).prop( 'checked', G.novolume );
			$( '#divdop' ).toggleClass( 'disabled', device.aplayname.slice( 0, 7 ) === 'bcm2835' );
			$( '#dop' ).prop( 'checked', device.dop == 1 );
			$( '#ffmpeg' ).toggleClass( 'disabled', G.dabradio );
		}
		$( '#divaudiooutput div' ).eq( 0 ).html( G.camilladsp ? '<i class="fa fa-camilladsp"></i>' : 'Device' );
	}
	if ( $( '#infoRange .value' ).length ) {
		var cmd = O.title === 'Mixer Device Volume' ? [ 'volumeget', 'db' ] : [ 'volumebtget' ];
		bash( cmd, function( voldb ) {
			var voldb = voldb.split( ' ' );
			var vol = voldb[ 0 ];
			var db = voldb[ 1 ];
			$( '#infoRange .value' ).text( vol );
			$( '#infoRange input' ).val( vol );
			$( '.infofooter' ).text( db +' dB' );
			$( '#infoButtons a' ).eq( 1 ).toggleClass( 'hide', db === '0.00' );
		} );
	}
	$( '#divlists' ).toggleClass( 'hide', !G.lists.includes( true ) );
	for ( i = 0; i < 3; i++ ) $( '#divlists .sub' ).eq( i ).toggleClass( 'hide', !G.lists[ i ] );
	showContent();
}
function setMixerType( mixertype ) {
	var hwmixer = device.mixers ? device.hwmixer : '';
	notify( 'Mixer Control', 'Change ...', 'mpd' );
	bash( [ 'mixertype', mixertype, device.aplayname, hwmixer ] );
}
