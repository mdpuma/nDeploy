#!/bin/bash

ulimit -n 50000 >/dev/null 2>&1
LAST_RELOAD=$(cat /opt/nDeploy/lock/nginx.lastreload 2>/dev/null)

# $LAST_RELOAD + 60 > CURRENT_TIME
if [ -n "$LAST_RELOAD" ] && [ $((LAST_RELOAD + 60)) -gt "`date +%s`" ]; then
    echo '1 nDeploy::nginx::cant reload, skipping reload'
    exit 0
fi

echo "[`date`][pid $$] Called script $0" >> /opt/nDeploy/logs/nginx.log

NGINX_RESULT="`/usr/sbin/nginx -t 2>&1`"
RESULT=$?
echo "[`date`][pid $$] Run nginx -t: $NGINX_RESULT $0 $*" >> /opt/nDeploy/logs/nginx.log

if [ $RESULT -ne 0 ]; then
	echo "[`date`][pid $$] Cant reload nginx $0 $*" >> /opt/nDeploy/logs/nginx.log
	exit 1
fi

echo $(date +%s) > /opt/nDeploy/lock/nginx.lastreload
kill -s HUP $(cat /var/run/nginx.pid)

echo '1 nDeploy::nginx::reloaded'
exit 0
