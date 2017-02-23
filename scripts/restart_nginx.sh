#!/bin/bash

ulimit -n 50000 >/dev/null 2>&1

echo "[`date`][pid $$] Called script $0 $*" >> /opt/nDeploy/logs/hook.log
echo "[`date`][pid $$] USER: `id` $0 $*" >> /opt/nDeploy/logs/hook.log

NGINX_RESULT="`/usr/sbin/nginx -t 2>&1`"
RESULT=$?
echo "[`date`][pid $$] Run nginx -t: $NGINX_RESULT $0 $*" >> /opt/nDeploy/logs/hook.log

if [ $RESULT -ne 0 ]; then
	echo "[`date`][pid $$] Cant restart nginx $0 $*" >> /opt/nDeploy/logs/hook.log
	exit 1
fi

if [ -d /etc/systemd ]; then
	systemctl restart nginx
else
	/etc/init.d/nginx restart >/dev/null 2>&1
fi

echo '1 nDeploy::nginx::restarted'