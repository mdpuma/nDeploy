#!/bin/bash

PHPFPM_BACKENDS="5.4 5.5 5.6 7.0"

check_nginx() {
	URL=http://localhost:808/nginx-status
	RESPONSE=`curl --max-time 15 $URL 2>/dev/null | xargs`
	echo "[`date`] URL=$URL Response=$RESPONSE"
	echo $RESPONSE | grep -E "^Active connections:" >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		[[ -d /etc/systemd ]] && systemctl restart nginx || /etc/init.d/nginx restart
		echo 'Restarted nginx' 1>&2
	fi
}

check_phpfpm() {
	for VER in $PHPFPM_BACKENDS; do
		URL=http://localhost:808/ping$VER
		RESPONSE=`curl --max-time 15 $URL 2>/dev/null`
		echo "[`date`] URL=$URL Response=$RESPONSE"
		if [ "$RESPONSE" != 'pong' ]; then
			/opt/nDeploy/scripts/init_backends.pl --action=restart --forced --php=$VER
			echo "Restarted php-$VER" 1>&2
		fi
	done
}

check_watcher() {
	pgrep -F /opt/nDeploy/watcher.pid >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		[[ -d /etc/systemd ]] && systemctl restart ndeploy_watcher || /etc/init.d/ndeploy_watcher restart
		echo 'Restarted ndeploy_watcher' 1>&2
	fi
}

check_nginx
check_phpfpm
check_watcher