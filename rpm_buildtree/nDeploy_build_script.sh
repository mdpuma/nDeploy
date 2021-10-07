#!/bin/bash
#Author: Anoop P Alias

RPM_ITERATION="47"

rm -f nDeploy-pkg/nDeploy-*rpm nDeploy-pkg-centos7/nDeploy-*rpm
for version in nDeploy-pkg nDeploy-pkg-centos7; do
	mkdir $version/opt/nDeploy/{lock,logs,user-data,domain-data} -p
	mkdir $version/opt/nDeploy/conf/php-fpm.d -p
	rsync -av ../scripts ../conf ../PHP $version/opt/nDeploy/
	rsync -av ../apache_fpm_cp ../nDeploy_cp $version/opt/nDeploy/
	
	chmod 755 $version/opt/nDeploy/scripts/*
	chmod 755 $version/etc/rc.d/init.d/ndeploy_*
done

#cd nDeploy-pkg
#chmod 755 opt/nDeploy/scripts/* opt/nDeploy/apache_fpm_cp/* opt/nDeploy/nDeploy_cp/* -v
#fpm -s dir -t rpm -C ../nDeploy-pkg --vendor "AMPLICA" --iteration ${RPM_ITERATION}.el6 -d python-inotify -d python-jinja2 -d python-simplejson -d nginx-nDeploy -d python-argparse -d PyYAML -d perl-YAML-Tiny -d python-lxml -d ea-apache24-mod_remoteip -d ea-apache24-mod_env -a noarch -m admin@amplica.md -e --description "nDeploy cPanel plugin" --url http://amplica.md --after-install ../after_ndeploy_install --before-remove ../after_ndeploy_uninstall --name nDeploy .

cd ../nDeploy-pkg-centos7
chmod 755 opt/nDeploy/scripts/* opt/nDeploy/apache_fpm_cp/* opt/nDeploy/nDeploy_cp/* -v
fpm -s dir -t rpm -C ../nDeploy-pkg-centos7 --vendor "AMPLICA" --iteration ${RPM_ITERATION}.el7 -d python-inotify -d python-jinja2 -d python-simplejson -d nginx-nDeploy -d python-argparse -d PyYAML -d perl-YAML-Tiny -d python-lxml -d ea-apache24-mod_remoteip -d ea-apache24-mod_env -a noarch -m admin@amplica.md -e --description "nDeploy cPanel plugin" --url http://amplica.md --after-install ../after_ndeploy_install --before-remove ../after_ndeploy_uninstall --name nDeploy .
mv nDeploy-*.rpm ../RPMS -v
cd ..
