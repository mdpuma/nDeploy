#!/bin/bash
#Author: Anoop P Alias

RPM_ITERATION="41"

rm -f nDeploy-pkg/nDeploy-*rpm nDeploy-pkg-centos7/nDeploy-*rpm
for version in nDeploy-pkg nDeploy-pkg-centos7; do
	rsync -v ../scripts ../conf $version/opt/nDeploy/
	rsync -v ../apache_fpm_cp ../nDeploy_cp $version/opt/nDeploy/
	rsync -v ../domain-data ../user-data ../PHP ../logs ../lock $version/opt/nDeploy/
done

cd nDeploy-pkg
chmod 755 opt/nDeploy/scripts/* opt/nDeploy/apache_fpm_cp/* opt/nDeploy/nDeploy_cp/* -v
fpm -s dir -t rpm -C ../nDeploy-pkg --vendor "AMPLICA" --iteration ${RPM_ITERATION}.el6 -d python-inotify -d nginx-nDeploy -d perl-YAML-Tiny -d python-argparse -d PyYAML -d python-lxml -a noarch -m admin@amplica.md -e --description "nDeploy cPanel plugin" --url http://amplica.md --after-install ../after_ndeploy_install --before-remove ../after_ndeploy_uninstall --name nDeploy .

cd ../nDeploy-pkg-centos7
chmod 755 opt/nDeploy/scripts/* opt/nDeploy/apache_fpm_cp/* opt/nDeploy/nDeploy_cp/* -v
fpm -s dir -t rpm -C ../nDeploy-pkg-centos7 --vendor "AMPLICA" --iteration ${RPM_ITERATION}.el7 -d python-inotify -d nginx-nDeploy -d perl-YAML-Tiny -d python-argparse -d PyYAML -d python-lxml -a noarch -m admin@amplica.md -e --description "nDeploy cPanel plugin" --url http://amplica.md --after-install ../after_ndeploy_install --before-remove ../after_ndeploy_uninstall --name nDeploy .
cd ..
