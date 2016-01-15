#!/bin/bash

ulimit -n 50000
LAST_RELOAD=$(cat /opt/nDeploy/lock/nginx.lastreload 2>/dev/null)

# $LAST_RELOAD + 30 > CURRENT_TIME
if [ -n "$LAST_RELOAD" ] && [ $((LAST_RELOAD + 30)) -gt "`date +%s`" ]; then
	echo "[`date`] Last reload is at `date --date="@$LAST_RELOAD"`, skipping reload"
	exit 0
fi


if [ -d /etc/systemd ]; then
	/usr/sbin/nginx -t && systemctl reload nginx
else
	/usr/sbin/nginx -t && /etc/init.d/nginx reload
fi
echo $(date +%s) > /opt/nDeploy/lock/nginx.lastreload