#!/bin/bash

ulimit -n 50000 >/dev/null 2>&1
LAST_RELOAD=$(cat /opt/nDeploy/lock/nginx.lastreopenlogs 2>/dev/null)

# $LAST_RELOAD + 60 > CURRENT_TIME
if [ -n "$LAST_RELOAD" ] && [ $((LAST_RELOAD + 60)) -gt "`date +%s`" ]; then
    echo '1 nDeploy::nginx::cant reopenlogs, skipping reopen logs'
    exit 0
fi

echo "[`date`][pid $$] Called script $0" >> /opt/nDeploy/logs/nginx.log

echo $(date +%s) > /opt/nDeploy/lock/nginx.lastreopenlogs
kill -s USR1 $(cat /var/run/nginx.pid)

echo '1 nDeploy::nginx::reopen logs'
exit 0
