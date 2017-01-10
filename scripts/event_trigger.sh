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
echo $1 | grep -E "\.main\.|\.lock|\.db|\.cache|cache\.?|sed[a-zA-Z0-9]+" && exit 0

# ignore event when directory is removed
echo $3 |grep -E "IN_DELETE\|IN_ISDIR" && exit 0

echo "[`date`][pid $$] Called script $0 $*" >> /opt/nDeploy/logs/hook.log


case "$2" in
	0)
		if(echo $1 | grep -E "_SSL$");then
			CPANELUSER=$(echo $1|awk -F'/' '{print $5}')
			echo "$(date) Conf:Gen ${CPANELUSER}"
			/opt/nDeploy/scripts/generate_config.py $CPANELUSER
			echo "[`date`][pid $$] Run generate_config reload_nginx part" >> /opt/nDeploy/logs/hook.log
		fi
		exit 0
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
