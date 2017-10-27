#!/usr/local/bin/php
<?php

ini_set('display_errors', 'On');
ini_set('date.timezone', 'Europe/Chisinau');
ini_set('error_log', 'error_log');
error_reporting(E_ALL);

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

$installation_path = '/opt/nDeploy';
$backend_config_file = $installation_path.'/conf/backends.yaml';
$php_fpm_config = $installation_path.'/conf/php-fpm.conf';

system("/sbin/sysctl -q -w net.core.somaxconn=4096");

$o = getopt('', array(
    'action:',
    'php:',
    'forced::',
));

if(!isset($o['action'])) {
    print "Usage ".$argv[0]." --action=<start/stop/restart/reload/reloadlogs> [--php=<phpver>] [--forced]\n";
    exit(1);
}
if(!isset($o['forced']))
    $o['forced']=0;
else
    $o['forced']=1;

$php_versions = read_yaml($backend_config_file);
// var_dump($php_versions);
// var_dump($o);
foreach($php_versions as $ver => $path) {
    if(!@preg_match('/'.$o['php'].'/', $ver)) continue;
    switch($o['action']) {
        case 'start':       start($ver, $path); break;
        case 'stop':        stop($ver, $path, $o['forced']); break;
        case 'reload':      reload($ver, $path); break;
        case 'reloadlogs':  reloadlogs($ver, $path); break;
        case 'restart': {
            stop($ver, $path, $o['forced']);
            start($ver, $path);
            break;
        }
    }
}

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function start($version, $path) {
    global $php_fpm_config;
    $php_bin = $path.'/sbin/php-fpm';
    
    $retry=5;
    print "Starting $version: ";
    do {
        if(is_dir('/etc/systemd')) {
            system('systemctl start '.$version, $ret);
        } else {
            system($php_bin.' --fpm-config '.$php_fpm_config.' >/dev/null 2>&1', $ret);
        }
        usleep(0.5*100000);
        print ". ";
        $retry--;
    } while($ret != 0 && $retry > 0);
    if($ret == 0) {
        print "started\n";
    } else {
        print 'cant start (exitcode='.$ret.")\n";
    }
}

function stop($version, $path, $forced=0) {
    global $php_fpm_config;
    $pidfile = $path.'/var/run/php-fpm.pid';
    if(is_file($pidfile)) {
        $master_pid = file_get_contents($pidfile);
        $master_pid = trim($master_pid);
        if($forced == 0) {
            system('kill -QUIT '.$master_pid, $ret);
            $type='Graceful';
        } else {
            system('kill -TERM '.$master_pid, $ret);
            $type='Forced';
        }
        if($ret == 0) {
            print "$type stop successful $version (pid=$master_pid)\n";
        } else {
            print "Cant $type stop $version (exitcode=$ret, pid=$master_pid)\n";
        }
        if($forced) {
            $output = exec('fuser -n file '.$path.'/sbin/php-fpm 2>/dev/null');
            if($output != '') {
                exec('ps -fp '.$output.' 2>/dev/null', $output2);
                $output2 = implode("\n", $output2);
                print "Processes which will be killed forced:\n".$output2."\n\n";
                exec('kill -9 '.$output);
            }
        }
    }
}

function reload($version, $path) {
    global $php_fpm_config;
    $pidfile = $path.'/var/run/php-fpm.pid';
    if(is_file($pidfile)) {
        $master_pid = file_get_contents($pidfile);
        $master_pid = trim($master_pid);
        system('kill -USR2 '.$master_pid, $ret);
        if($ret == 0) {
            print "Reload successful $version (pid=$master_pid)\n";
        } else {
            print "Cant $type stop $version (exitcode=$ret, pid=$master_pid)\n";
        }
    }
}

function reloadlogs($version, $path) {
    global $php_fpm_config;
    $pidfile = $path.'/var/run/php-fpm.pid';
    if(is_file($pidfile)) {
        $master_pid = file_get_contents($pidfile);
        $master_pid = trim($master_pid);
        system('kill -USR1 '.$master_pid, $ret);
        if($ret == 0) {
            print "Reload successful $version (pid=$master_pid)\n";
        } else {
            print "Cant $type stop $version (exitcode=$ret, pid=$master_pid)\n";
        }
    }
}

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
//         $var1=substr($var1,4);
        $result[$var1]=$var2;
    }
    return $result;
}
?>