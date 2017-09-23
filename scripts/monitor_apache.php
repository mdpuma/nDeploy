#!/usr/bin/env php
<?php

$apache_status_url = 'http://127.0.0.1:8000/whm-server-status';
$max_processes = 150;

ini_set('display_errors', 'On');
error_reporting(E_ALL);

// get status
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apache_status_url);
curl_setopt($ch, CURLOPT_HEADER, 0);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1); 
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 10);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
$output = curl_exec($ch);
curl_close($ch);

// parse status
$lines = explode("\n", $output);
foreach($lines as $l) {
	if(preg_match("/([0-9]+) requests currently being processed,/", $l, $matches)) {
		$processes = $matches[1];
		break;
	}
}

// do action
if($processes >= $max_processes) {
	system("killall httpd -9 -v");
	system("systemctl restart httpd");
	file_put_contents('php://stderr', "httpd is running within limit of processes (".$processes."/".$max_processes.")\n");

} else {
	echo("httpd is running within limit of processes (".$processes."/".$max_processes.")\n");
}
?>
