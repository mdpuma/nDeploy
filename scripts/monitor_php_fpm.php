#!/usr/bin/env php
<?php

ini_set('display_errors', 'On');
ini_set('date.timezone', 'Europe/Chisinau');
ini_set('error_log', 'error_log');
error_reporting(E_ALL);

// load state from file
$reload_state = [];
load_state();

check_watcher();
$ret = check_nginx('http://127.0.0.1:808/nginx-status', 5);
// if($ret == 0) check_phpfpm(['5.4', '5.6', '7.0'], 5);

var_dump($reload_state);
if($reload_state) {
	foreach($reload_state as $i => $j) {
		if($j['failed_cron']>2) {
			print_stderr("failed to revive php-fpm, let's kill php-fpm (probable cloudlinux bug)");
			system("killall php-fpm -9 -v 1>&2");
			$reload_state[$i]['failed_cron']=0;
		}
	}
}
var_dump($reload_state);
// save state to file
save_state();

function increase_attempt($service) {
	global $reload_state;
	if(!isset($reload_state[$service]['restarts'])) 
		$reload_state[$service]['restarts'] = 0;
	$reload_state[$service]['restarts'] += 1;
}
function load_state($file = 'php-fpm.state') {
	global $reload_state;
	if(is_file($file)) {
		$reload_state = json_decode(file_get_contents($file), true);
	}
	foreach($reload_state as $i => $j) {
		$reload_state[$i]['restarts']=0;
	}
}
function save_state($file = 'php-fpm.state') {
	global $reload_state;
	foreach($reload_state as $i => $j) {
		
		if(!isset($reload_state[$i]['failed_cron'])) {
			$reload_state[$i]['failed_cron'] = 0;
		}
		
		if($reload_state[$i]['restarts'] > 0) {
			$reload_state[$i]['failed_cron']++;
		} else {
			if($reload_state[$i]['failed_cron']>0)
				$reload_state[$i]['failed_cron']--;
		}
	}
	file_put_contents($file, json_encode($reload_state));
}

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function check_watcher() {
    $pidfile = '/opt/nDeploy/watcher.pid';
    if(is_file($pidfile)) {
        $pid = trim(file_get_contents($pidfile));
        system("ps -p $pid >/dev/null 2>&1", $ret);
        if($ret != 0) {
            restart_watcher();
        }
    } else {
        restart_watcher();
    }
}
function restart_watcher() {
    print_stderr("Try to restart ndeploy_watcher");
    if(is_dir("/etc/systemd")) {
        system("systemctl restart ndeploy_watcher");
    } else {
        system("/etc/init.d/ndeploy_watcher restart");
    }
}
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function check_nginx($status_url, $attempts=5) {
    do {
        $status = curl_simple($status_url);
        if($status==false) 
            print_stderr("nginx status is failed");
        $attempts--;
    } while($attempts > 0 && $status == false);
    $status = str_replace("\n", '', $status);
    if(!preg_match("/Active connections:/", $status)) {
        return restart_nginx();
    }
    return 0;
}
function restart_nginx() {
    print_stderr("try to restart nginx");
    $tries=3;
    while($tries>=0) {
        if(is_dir("/etc/systemd")) {
            system("systemctl restart nginx", $ret);
        } else {
            system("/etc/init.d/nginx restart", $ret);
        }
        print_stderr("return code is $ret");
        if($ret==0) {
            print_stdout("successfully restarted nginx");
            return $ret;
            break;
        }
        $tries--;
        sleep(1);
    }
    return $ret;
}
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function check_phpfpm($php_versions=array(), $attempts=5) {
    foreach($php_versions as $version) {
        $attempt = $attempts;
        do {
            $status = curl_simple('http://127.0.0.1:808/ping'.$version);
            if($status==false) {
                print_stderr("php-".$version." status is failed");
                $attempt--;
                usleep(500000);
            }
        } while($attempt > 0 && $status == false);
        print_stdout("phpfpm_$version=$status");
        if($status != 'pong') {
            print_stderr("no pong response, restarting php-".$version);
            restart_phpfpm($version);
        }
    }
    
    usleep(500000);
    $yaml_array = read_yaml('/opt/nDeploy/conf/backends.yaml');
    foreach($yaml_array as $version => $path) {
        $pidfile = $path.'/var/run/php-fpm.pid';
        if(is_file($pidfile)) {
            $pid = trim(file_get_contents($pidfile));
            system("ps -p $pid >/dev/null 2>&1", $ret);
            if($ret != 0) {
                print_stderr("no process with pid ".$pidfile.", restarting php-".$version);
                restart_phpfpm($version);
            } else {
                print_stdout("master-process phpfpm_$version exists");
            }
        } else {
            print_stderr("no pidfile $pidfile");
            restart_phpfpm($version);
        }
    }
}
function restart_phpfpm($version) {
	increase_attempt($version);
    print_stderr('try to restart php-'.$version);
    system('/opt/nDeploy/scripts/init_backends.php --action=restart --forced --php='.$version.'$ >/dev/null');
}
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function curl_simple($url, $timeout=10, $connect_timeout=10) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_HEADER, 0);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1); 
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $connect_timeout);
    curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
    $output = curl_exec($ch);
    curl_close($ch);
    return $output;
}
function print_stderr($msg) {
    $date = date("d-m-Y h:i");
    file_put_contents('php://stderr', '['.$date.'] '.$msg."\n");
}
function print_stdout($msg) {
    $date = date("d-m-Y h:i");
    echo('['.$date.'] '.$msg."\n");
}

// PHP:
//   php-5.3.29: /usr/local/phpbrew/php/php-5.3.29
//   php-5.4.45: /usr/local/phpbrew/php/php-5.4.45
//   php-5.6.30: /usr/local/phpbrew/php/php-5.6.30
//   php-7.0.12: /usr/local/phpbrew/php/php-7.0.12
// PROXY:
//   apache: '8000'

function read_yaml($config) {
    if(!is_file($config)) {
        print_stderr("cant open file $config");
    }
    $content = file_get_contents($config);
    $content = explode("\n", $content);
    $result='';
    foreach($content as $i => $line) {
        if(empty($line)) continue;
        list($var1, $var2) = @explode(':', $line);
        $var1=trim($var1);
        $var2=trim($var2);
        if(substr($var1,0,3) !== 'php') continue;
        $var1=substr($var1,4);
        $result[$var1]=$var2;
    }
    return $result;
}
?>
