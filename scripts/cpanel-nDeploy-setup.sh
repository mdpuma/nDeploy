#!/bin/bash -e

function enable {
	echo -e '\e[93m Generating the default nginx vhosts \e[0m'
	/opt/nDeploy/scripts/generate_default_vhost_config.py
	echo -e '\e[93m Modifying apache http and https port in cpanel \e[0m'
	/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_port value=0.0.0.0:8000
	/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_ssl_port value=0.0.0.0:4430
	sed -i 's/service\[httpd\]=80,/service[httpd]=8000,/' /etc/chkserv.d/httpd
	echo 'service[nginx]=80,GET / HTTP/1.0,HTTP/1..,/etc/init.d/nginx restart' > /etc/chkserv.d/nginx
	echo 'nginx:1' >> /etc/chkserv.d/chkservd.conf
	/usr/local/cpanel/libexec/tailwatchd --restart
	
	echo -e '\e[93m Rebuilding Apache httpd backend configs and restarting daemons \e[0m'
# 	if [ -f /var/cpanel/templates/apache2_4/vhost.default ]; then
# 		if [ -f /var/cpanel/templates/apache2_4/vhost.local ];then
# 			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
# 		else
# 			cp -p /var/cpanel/templates/apache2_4/vhost.default /var/cpanel/templates/apache2_4/vhost.local
# 			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
# 		fi
# 		if [ -f /var/cpanel/templates/apache2_4/ssl_vhost.local ];then
# 			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
# 		else
# 			cp -p /var/cpanel/templates/apache2_4/ssl_vhost.default /var/cpanel/templates/apache2_4/ssl_vhost.local
# 			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
# 		fi
# 	fi
	
	echo -n "Rebuild:"
	for CPANELUSER in $(cat /etc/domainusers|sort -u|cut -d: -f1); do
		/opt/nDeploy/scripts/generate_config.py $CPANELUSER
		echo -n " $CPANELUSER";
	done
	
	/scripts/rebuildhttpdconf
	osversion=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+'|cut -d"." -f1)
	if [ ${osversion} -le 6 ];then
		chkconfig nginx on
		chkconfig ndeploy_watcher on
		chkconfig ndeploy_backends on
		
		service nginx restart
		service ndeploy_watcher restart
		service ndeploy_backends restart
	else
		systemctl enable nginx
		systemctl enable ndeploy_watcher
		systemctl enable ndeploy_backends
		
		systemctl restart nginx
		systemctl restart ndeploy_watcher
		systemctl restart ndeploy_backends
	fi
	/scripts/restartsrv_httpd
}

function disable {
	echo -e '\e[93m Reverting apache http and https port in cpanel \e[0m'
	/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_port value=0.0.0.0:80
	/usr/local/cpanel/bin/whmapi1 set_tweaksetting key=apache_ssl_port value=0.0.0.0:443
	sed -i 's/service\[httpd\]=8000,/service[httpd]=80,/' /etc/chkserv.d/httpd
	rm /etc/chkserv.d/nginx
	echo 'nginx:1' >> /etc/chkserv.d/chkservd.conf
	/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings > /dev/null
	/usr/local/cpanel/libexec/tailwatchd --restart
	
# 	if [ -f /var/cpanel/templates/apache2_2/vhost.local ]; then
# 		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_2/vhost.local
# 		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_2/ssl_vhost.local
# 	fi
# 	if [ -f /var/cpanel/templates/apache2_4/vhost.local ]; then
# 		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
# 		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
# 	fi
	
	if [ -d /etc/apache2 ]; then
		rm /etc/apache2/conf.d/includes/post_virtualhost_global.conf /etc/apache2/conf.d/includes/httpd_mod_remoteip.include
	else
		rm /etc/httpd/conf/includes/post_virtualhost_global.conf /etc/httpd/conf/includes/httpd_mod_remoteip.include
	fi
	
	echo -e '\e[93m Rebuilding Apache httpd backend configs.Apache will listen on default ports!  \e[0m'
	
	/scripts/rebuildhttpdconf
	osversion=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+'|cut -d"." -f1)
	if [ ${osversion} -le 6 ];then
		service nginx stop
		service ndeploy_watcher stop
		service ndeploy_backends stop
		chkconfig nginx off
		chkconfig ndeploy_watcher off
		chkconfig ndeploy_backends off
	else
		systemctl stop nginx
		systemctl stop ndeploy_watcher
		systemctl stop ndeploy_backends
		systemctl disable nginx
		systemctl disable ndeploy_watcher
		systemctl disable ndeploy_backends
	fi
	/scripts/restartsrv_httpd
}

case "$1" in
	enable)
		enable
		;;
	
	disable)
		disable
		;;
	*)
		echo $"Usage: $0 {enable|disable}"
		exit 1
		;;
esac