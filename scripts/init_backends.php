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

$max_wait_stop = 10; // wait n seconds after stop, until do force stop
$max_wait_reload = 10; // wait n seconds after reload, until do force restart

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

make_mutex($installation_path.'/lock/init_backends.lock');
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
remove_mutex($installation_path.'/lock/init_backends.lock');

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

function start($version, $path) {
    global $php_fpm_config;
    
    print "Starting $version: ";
    
    if(is_dir('/etc/systemd')) {
        system('systemctl start '.$version, $ret);
    } else {
        system($path.'/sbin/php-fpm --fpm-config '.$php_fpm_config.' >/dev/null 2>&1', $ret);
    }
    
    if($ret == 0) {
        print "started\n";
    } else {
        print 'cant start (exitcode='.$ret.")\n";
    }
}

function stop($version, $path, $forced=0) {
    global $php_fpm_config, $max_wait_stop;
    $master_pid = read_pidfile($path.'/var/run/php-fpm.pid');
    if($master_pid) {
        if($forced == 0) {
            system('kill -QUIT '.$master_pid, $ret);
            $type='graceful';
        } else {
            system('kill -TERM '.$master_pid, $ret);
            $type='forced';
        }
        if($ret == 0) {
            print "Sent signal to $type stop $version (pid=$master_pid)\n";
            
            $retry = $max_wait_stop;
            print "Waiting for $version to close: ";
            do {
                // do logic
                system('kill -s 0 '.$master_pid.' 2>/dev/null', $ret);
                if($ret!==0) { // return code is not 0, then master-process is no more existing
                    print " exited\n";
                    break;
                }
                sleep(1);
                print ". ";
                $retry--;
            } while($retry > 0);
            if($retry == 0) {
                $forced = 1;
            }
        } else {
            print "Cant $type stop $version (exitcode=$ret, pid=$master_pid)\n";
        }
        
        // do forced stop of php-fpm master process and childs
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
    global $php_fpm_config, $max_wait_reload;
    $master_pid = read_pidfile($path.'/var/run/php-fpm.pid');
    if($master_pid) {
        system('kill -USR2 '.$master_pid, $ret);
        if($ret == 0) {
            print "Sent signal to reload $version (pid=$master_pid)\n";
            
            $retry = $max_wait_reload;
            print "Waiting for $version to finish reloading: ";
            do {
                // do logic
                system('kill -s 0 '.$master_pid.' 2>/dev/null', $ret);
                if($ret!==0) { // return code is not 0, then master-process is no more existing
                    print " reloaded\n";
                    $retry=-1;
                    break;
                }
                sleep(1);
                print ". ";
                $retry--;
            } while($retry > 0);
            if($retry == 0) {
                // stop forced if reload doesn't finish in $max_wait_reload seconds
                print "too late, do force restart\n";
                stop($version, $path, 1);
                start($version, $path);
            }
        } else {
            print "Cant $type reload $version (exitcode=$ret, pid=$master_pid)\n";
        }
    }
}

function reloadlogs($version, $path) {
    global $php_fpm_config;
    $master_pid = read_pidfile($path.'/var/run/php-fpm.pid');
    if($master_pid) {
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
function read_pidfile($pidfile) {
    if(!is_file($pidfile)) return false;
    return trim(file_get_contents($pidfile));
}

function make_mutex($mutex_file) {
    if(is_file($mutex_file)) {
//         print "Exiting, due already running init_backends.php\n";
        fwrite(STDERR, "Exiting, due already running init_backends.php\n");
        die();
    }
    @touch($mutex_file);
}
function remove_mutex($mutex_file) {
    @unlink($mutex_file);
}
?>