#!/bin/bash
# Author: Anoop P Alias

function enable {
	if [ -f /var/cpanel/templates/apache2_4/vhost.local ] && [ -z "`grep '#nDeploy#' /var/cpanel/templates/apache2_4/vhost.local`" ];then
		sed -i '/DocumentRoot/ r /opt/nDeploy/conf/apache_vhost_include_php.tmpl' /var/cpanel/templates/apache2_4/vhost.local
	else
		cp -p /var/cpanel/templates/apache2_4/vhost.default /var/cpanel/templates/apache2_4/vhost.local
		sed -i '/DocumentRoot/ r /opt/nDeploy/conf/apache_vhost_include_php.tmpl' /var/cpanel/templates/apache2_4/vhost.local
	fi
	if [ -f /var/cpanel/templates/apache2_4/ssl_vhost.local ] && [ -z "`grep '#nDeploy#' /var/cpanel/templates/apache2_4/ssl_vhost.local`" ];then
		sed -i '/DocumentRoot/ r /opt/nDeploy/conf/apache_vhost_include_php.tmpl' /var/cpanel/templates/apache2_4/ssl_vhost.local
	else
		cp -p /var/cpanel/templates/apache2_4/ssl_vhost.default /var/cpanel/templates/apache2_4/ssl_vhost.local
		sed -i '/DocumentRoot/ r /opt/nDeploy/conf/apache_vhost_include_php.tmpl' /var/cpanel/templates/apache2_4/ssl_vhost.local
	fi
	
	/opt/nDeploy/scripts/apache_default_php_setup.py
	
	echo -n "Rebuild:"
	for CPANELUSER in $(cat /etc/domainusers|cut -d: -f1 | sort | uniq); do
		/opt/nDeploy/scripts/apache_php_config_generator.py $CPANELUSER
		echo -n " $CPANELUSER";
	done
	
	/scripts/rebuildhttpdconf
	/scripts/restartsrv httpd
}



function disable {
	sed -i '/#nDeploy#/,/#nDeploy#/d' /var/cpanel/templates/apache2_4/vhost.local
	sed -i '/#nDeploy#/,/#nDeploy#/d' /var/cpanel/templates/apache2_4/ssl_vhost.local
	rm -f /opt/nDeploy/conf/user_data.yaml.tmpl
	
	/scripts/rebuildhttpdconf
	/scripts/restartsrv httpd
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
 
esac
