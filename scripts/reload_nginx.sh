#!/bin/bash

ulimit -n 10000
if [ -d /etc/systemd ]; then
	/usr/sbin/nginx -t && systemctl reload nginx
else
	/usr/sbin/nginx -t && /etc/init.d/nginx reload
fi