#!/bin/bash
# Call example 
# When is changed something from /var/cpanel/userdata ['create', 'modify', 'delete']
#     /opt/nDeploy/scripts/event_trigger.sh $filename 0 $tflags
#
# When is changed something from /opt/nDeploy/domain-data ['modify' , 'atrribute_change']
#     /opt/nDeploy/scripts/event_trigger.sh $filename 1 $tflags
# 
# When is changed something from /opt/nDeploy/userdata-data
#     /opt/nDeploy/scripts/event_trigger.sh $filename 2 $tflags
# 

# ignore files with .cache, .lock
echo $1 | grep -E "\.main\.|\.lock|\.db|\.cache|cache\.?" && exit 0

# ignore event when directory is removed
echo $3 |grep -E "IN_DELETE\|IN_ISDIR" && exit 0

echo "[`date`][pid $$] Called script $0 $*" >> /opt/nDeploy/logs/hook.log


case "$2" in
	0)
		#/var/cpanel/userdata/example/example.com_SSL => example
		CPANELUSER=$(echo $1|awk -F'/' '{print $5}')
		FILENAME=$(basename $1)
		
		# this is already doing by accountcreate_hook_post.pl
		# call when is created directory
		#if [ $3 == "IN_CREATE|IN_ISDIR" ]; then
		#	echo "[`date`][pid $$] Run INCREATE|IN_ISDIR part /opt/nDeploy/scripts/apache_php_config_generator.py $CPANELUSER"
		#	/opt/nDeploy/scripts/apache_php_config_generator.py $CPANELUSER
		#fi
		
		# this is needed for remove subdomains/domains
		# call when is removed file
		if [ $3 == "IN_DELETE" ]; then
			DOMAIN=$(echo $1|awk -F'/' '{print $6}')
			if [ -f /opt/nDeploy/domain-data/$DOMAIN ] && [ -n "$DOMAIN" ]; then
				/opt/nDeploy/scripts/hook_domain_remove.py $DOMAIN
				echo "[`date`][pid $$] Run hook_domain_remove.py part" >> /opt/nDeploy/logs/hook.log
				
				/opt/nDeploy/scripts/reload_nginx.sh
				echo "[`date`][pid $$] Run reload_nginx part" >> /opt/nDeploy/logs/hook.log
				exit 0;
			fi
		fi
		
		[ $FILENAME == "main" ] && exit 0
		if [ ! -f /opt/nDeploy/domain-data/$FILENAME ] && [ $FILENAME != "main" ] && [ $3 != "IN_CREATE" ]; then
			exit 0
		fi
		;;
	1)
		[ $3 != "IN_MODIFY" ] && exit 0
		
		#cant be *.lock || .* || *main
		CPANELUSER=$(stat -c "%U" $1)
		;;
	2)
		[ $3 != "IN_MODIFY" ] && exit 0
		
		CPANELUSER=$(stat -c "%U" $1)
		if [[ $CPANELUSER == root || $CPANELUSER == .* ]];then
			exit 0
		else
			(
				flock -x -w 300 500
				echo "[`date`][pid $$] Run apache_php_config_generator init_backends part" >> /opt/nDeploy/logs/hook.log
				/opt/nDeploy/scripts/apache_php_config_generator.py $CPANELUSER
				/opt/nDeploy/scripts/init_backends.pl --action=reload
			) 500>/opt/nDeploy/lock/$CPANELUSER.aplock
			rm -f /opt/nDeploy/lock/$CPANELUSER.aplock
		fi
		exit 0
		;;
esac

if [[ $CPANELUSER == root || $CPANELUSER == *.lock || $CPANELUSER == .* || $1 == *main ]]; then
	exit 0
else
	(
		flock -x -w 300 500
		echo "[`date`][pid $$] Run generate_config reload_nginx part" >> /opt/nDeploy/logs/hook.log
		/opt/nDeploy/scripts/generate_config.py $CPANELUSER
		/opt/nDeploy/scripts/reload_nginx.sh
	) 500>/opt/nDeploy/lock/$CPANELUSER.lock
	rm -f /opt/nDeploy/lock/$CPANELUSER.lock
fi
