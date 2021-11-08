#!/bin/bash

ulimit -n 50000 >/dev/null 2>&1
LAST_RESTART=$(cat /opt/nDeploy/lock/nginx.lastrestart 2>/dev/null)

# $LAST_RESTART + 30 > CURRENT_TIME
if [ -n "$LAST_RESTART" ] && [ $((LAST_RESTART + 30)) -gt "`date +%s`" ]; then
	echo "[`date`] Last reload is at `date --date="@$LAST_RESTART"`, skipping reload"
	exit 0
fi

echo "[`date`][pid $$] Called script $0 $*" >> /opt/nDeploy/logs/nginx.log
echo "[`date`][pid $$] USER: `id` $0 $*" >> /opt/nDeploy/logs/nginx.log

NGINX_RESULT="`/usr/sbin/nginx -t 2>&1`"
RESULT=$?
echo "[`date`][pid $$] Run nginx -t: $NGINX_RESULT $0 $*" >> /opt/nDeploy/logs/nginx.log

if [ $RESULT -ne 0 ]; then
	echo "[`date`][pid $$] Cant restart nginx $0 $*" >> /opt/nDeploy/logs/nginx.log
	exit 1
fi

if [ -f /usr/bin/systemctl ]; then
	systemctl restart nginx
else
	/etc/init.d/nginx restart >/dev/null 2>&1
fi

echo '1 nDeploy::nginx::restarted'
echo $(date +%s) > /opt/nDeploy/lock/nginx.lastrestart
