#!/bin/bash

function enable {
	echo -e '\e[93m Modifying apache http and https port in cpanel \e[0m'
	sed -i "s/apache_port.*/apache_port=0.0.0.0:8000/" /var/cpanel/cpanel.config
	sed -i "s/apache_ssl_port.*/apache_ssl_port=0.0.0.0:4430/" /var/cpanel/cpanel.config
	sed -i 's/service\[httpd\]=80,/service[httpd]=8000,/' /etc/chkserv.d/httpd
	echo 'service[nginx]=80,GET / HTTP/1.0,HTTP/1..,/etc/init.d/nginx restart' > /etc/chkserv.d/nginx
	#/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings > /dev/null
	/usr/local/cpanel/libexec/tailwatchd --restart
	
	if [ -d /var/cpanel/templates/apache2_4 ]; then
		if [ -f /var/cpanel/templates/apache2_4/vhost.local ];then
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
		else
			cp -p /var/cpanel/templates/apache2_4/vhost.default /var/cpanel/templates/apache2_4/vhost.local
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
		fi
		if [ -f /var/cpanel/templates/apache2_4/ssl_vhost.local ];then
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
		else
			cp -p /var/cpanel/templates/apache2_4/ssl_vhost.default /var/cpanel/templates/apache2_4/ssl_vhost.local
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
		fi
	fi
	
	if [ -d /var/cpanel/templates/apache2_2 ]; then
		if [ -f /var/cpanel/templates/apache2_2/vhost.local ];then
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_2/vhost.local
		else
			cp -p /var/cpanel/templates/apache2_2/vhost.default /var/cpanel/templates/apache2_2/vhost.local
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_2/vhost.local
		fi
		if [ -f /var/cpanel/templates/apache2_2/ssl_vhost.local ];then
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_2/ssl_vhost.local
		else
			cp -p /var/cpanel/templates/apache2_2/ssl_vhost.default /var/cpanel/templates/apache2_2/ssl_vhost.local
			sed -i "s/CustomLog/#CustomLog/" /var/cpanel/templates/apache2_2/ssl_vhost.local
		fi
	fi
	
	install_modremoteip 2>/dev/null
	
	if [ -z "`grep HTTPS=on /usr/local/apache/conf/includes/pre_virtualhost_global.conf`" ]; then
		echo "SetEnvIf X-Forwarded-Proto https HTTPS=on" >> /usr/local/apache/conf/includes/pre_virtualhost_global.conf
	fi
	
	echo -n "Rebuild:"
	for CPANELUSER in $(cat /etc/domainusers|sort -u|cut -d: -f1); do
		/opt/nDeploy/scripts/generate_config.py $CPANELUSER
		echo -n " $CPANELUSER";
	done
	
	echo -e '\e[93m Rebuilding Apache httpd backend configs and restarting daemons \e[0m'
	/scripts/rebuildhttpdconf
	#/scripts/restartsrv httpd
	service httpd restart
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
}

function disable {
	echo -e '\e[93m Reverting apache http and https port in cpanel \e[0m'
	sed -i "s/apache_port.*/apache_port=0.0.0.0:80/" /var/cpanel/cpanel.config
	sed -i "s/apache_ssl_port.*/apache_ssl_port=0.0.0.0:443/" /var/cpanel/cpanel.config
	sed -i 's/service\[httpd\]=8000,/service[httpd]=80,/' /etc/chkserv.d/httpd
	rm /etc/chkserv.d/nginx
	/usr/local/cpanel/whostmgr/bin/whostmgr2 --updatetweaksettings > /dev/null
	/usr/local/cpanel/libexec/tailwatchd --restart
	
	if [ -d /var/cpanel/templates/apache2_2 ]; then
		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_2/vhost.local
		sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_2/ssl_vhost.local
	fi
	sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_4/vhost.local
	sed -i "s/#CustomLog/CustomLog/" /var/cpanel/templates/apache2_4/ssl_vhost.local
	
	sed -i '/SetEnvIf X-Forwarded-Proto https HTTPS=on/d' /usr/local/apache/conf/includes/pre_virtualhost_global.conf
	
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
	#/scripts/restartsrv httpd
	service httpd restart
}

function install_modremoteip {
	[[ -n "`grep remoteip_module /etc/httpd/conf/includes/pre_main_2.conf`" ]] && return 0
	cd /tmp
	rm *.la *.lo *.o *.slo -v
	wget https://svn.apache.org/repos/asf/httpd/httpd/branches/2.4.x/modules/metadata/mod_remoteip.c
	apxs -ciA -n mod_remoteip mod_remoteip.c
	rm /tmp/mod_remoteip.*
	
	echo "LoadModule remoteip_module modules/mod_remoteip.so" >> /etc/httpd/conf/includes/pre_main_2.conf
	echo "RemoteIPHeader X-Real-IP" >> /etc/httpd/conf/includes/pre_main_2.conf
	echo "RemoteIPInternalProxy $(ip -o -4 addr | awk '{ print $4}' | awk -F/ '{print $1}' |xargs)" >> /etc/httpd/conf/includes/pre_main_2.conf
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