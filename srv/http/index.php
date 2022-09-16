<?php
$login = file_exists( '/srv/http/data/system/login' );
if ( $login ) session_start();
$time = time();  // for cache busting
$localhost = in_array( $_SERVER[ 'REMOTE_ADDR' ], ['127.0.0.1', '::1'] );
?>

<!DOCTYPE html>
<html>
<head>
	<title>rAudio</title>
	<meta name="apple-mobile-web-app-title" content="rAudio">
	<meta name="application-name" content="rAudio">
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover">
	<meta name="apple-mobile-web-app-capable" content="yes">
	<meta name="apple-mobile-web-app-status-bar-style" content="black">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="msapplication-tap-highlight" content="no">
	<link rel="icon" href="/assets/img/icon.<?=$time?>.png">
	<link rel="apple-touch-icon" sizes="180x180" href="/assets/img/icon.png">
	<link rel="stylesheet" href="/assets/css/colors.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/common.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/info.<?=$time?>.css">
	<link rel="stylesheet" href="/assets/css/roundslider-1.6.1.min.css">
	<link rel="stylesheet" href="/assets/css/main.<?=$time?>.css">
</head>
<body>

<?php include 'index-body.php';?>

<script src="/assets/js/plugin/jquery-3.6.1.min.js"></script>
<script src="/assets/js/plugin/pushstream-20211210.min.js"></script>
<script src="/assets/js/plugin/html5kellycolorpicker-1.21.min.js"></script>
<script src="/assets/js/plugin/lazysizes-5.3.2.min.js"></script>
<script src="/assets/js/plugin/pica-9.0.1.min.js"></script>
<script src="/assets/js/plugin/qrcode.min.js"></script>
<script src="/assets/js/plugin/roundslider-1.6.1.min.js"></script>
<script src="/assets/js/plugin/Sortable-1.15.0.min.js"></script>
<script src="/assets/js/info.<?=$time?>.js"></script>
<script src="/assets/js/context.<?=$time?>.js"></script>
<script src="/assets/js/function.<?=$time?>.js"></script>
<script src="/assets/js/main.<?=$time?>.js"></script>
<script src="/assets/js/passive.<?=$time?>.js"></script>

<?php if ( file_exists( '/srv/http/data/system/equalizer' ) ) {?>
<link rel="stylesheet" href="/assets/css/equalizer.<?=$time?>.css">
<link rel="stylesheet" href="/assets/css/selectric.<?=$time?>.css">
<script src="/assets/js/equalizer.<?=$time?>.js"></script>
<script src="/assets/js/plugin/jquery.selectric-1.13.1.min.js"></script>
<?php }
	  if ( $localhost ) {?>
<link rel="stylesheet" href="/assets/css/simple-keyboard-3.4.139.min.css">
<link rel="stylesheet" href="/assets/css/keyboard.<?=$time?>.css">
<div id="keyboard" class="hide"><div class="simple-keyboard"></div></div>
<script src="/assets/js/plugin/simple-keyboard-3.4.139.min.js"></script>
<script src="/assets/js/keyboard.<?=$time?>.js"></script>
	  <?php }?>
	
</body>
</html>
