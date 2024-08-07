#!/usr/bin/env php
<?php

ini_set('display_errors', 'On');
ini_set('date.timezone', 'Europe/Chisinau');
ini_set('error_log', 'error_log');
error_reporting(E_ALL);

check_apache('http://127.0.0.1:8000/whm-server-status', 300, 5);

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function check_apache($url, $max_processes, $attempts=3) {
    do {
        $status = curl_simple($url);
        if($status==false) 
            print_stderr("apache status is failed");
        $attempts--;
        usleep(500000);
    } while($attempts>0 && $status == false);
    
    $pidfile = '/var/run/apache2/httpd.pid';
//     print_stdout("apache_status is '$status'");
    
    // parse status
    $found=0;
    $lines = explode("\n", $status);
    foreach($lines as $l) {
        if(preg_match("/([0-9]+) requests currently being processed,/", $l, $matches)) {
            $processes = $matches[1];
            $found=1;
            break;
        }
    }
    if($found!=1) {
        print_stderr("cant find processes count, force restart apache");
        restart_apache();
    } else {
        // do action
        if($processes >= $max_processes) {
            print_stderr("httpd is running within limit of processes (".$processes."/".$max_processes.")");
            print_stderr("restarting apache");
            restart_apache();
        } else {
            print_stdout("httpd is running within limit of processes (".$processes."/".$max_processes.")");
        }
    }
    $pid = trim(file_get_contents($pidfile));
    system("ps -p $pid >/dev/null 2>&1", $ret);
    if($ret==0) {
        print_stdout("apache is running, pid=$pid");
    }
}
function restart_apache() {
    system("killall httpd -9 -v");
    sleep(1);
    // clean ipcs semaphores
    system("for i in `ipcs -s | grep nobody | awk '{print $2}'`; do ipcrm sem \$i; done");
    if(is_file('/usr/bin/systemctl')) {
        system('systemctl restart httpd');
    } else {
        system('/etc/init.d/httpd restart');
    }
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

?>
