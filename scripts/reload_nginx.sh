#!/bin/bash

ulimit -n 10000
if [ -f /etc/init.d/nginx ]; then
	/usr/sbin/nginx -t && /etc/init.d/nginx reload
else
	/usr/sbin/nginx -t && systemctl reload nginx
fi