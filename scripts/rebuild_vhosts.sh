#!/bin/bash

USERS=$(cat /etc/domainusers|cut -d: -f1)
COUNT=$(echo $USERS|xargs -n1|wc -l)
i=0
echo -n "Rebuild:"
for CPANELUSER in $USERS; do
	/opt/nDeploy/scripts/generate_config.py $CPANELUSER
	let i++
	echo "[$i/$COUNT] /opt/nDeploy/scripts/generate_config.py $CPANELUSER"
done

/opt/nDeploy/scripts/reload_nginx.sh
