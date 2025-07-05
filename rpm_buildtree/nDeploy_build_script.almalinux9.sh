#!/bin/bash
#Author: Anoop P Alias

RPM_ITERATION="50.almalinux9"

rm -f nDeploy-pkg/nDeploy-*rpm nDeploy-pkg-centos7/nDeploy-*rpm

mkdir nDeploy-pkg/opt/nDeploy/{lock,logs,user-data,domain-data} -p
rsync -av ../scripts ../conf ../PHP nDeploy-pkg/opt/nDeploy/
rsync -av ../nDeploy_cp nDeploy-pkg/opt/nDeploy/

chmod 755 nDeploy-pkg/opt/nDeploy/scripts/*

cd nDeploy-pkg
chmod 755 opt/nDeploy/scripts/* opt/nDeploy/nDeploy_cp/* -v
fpm -s dir -t rpm -C . --vendor "IPHOST" --iteration ${RPM_ITERATION} -d python3-lxml -d python3-pyyaml -d python3-inotify -d python3-jinja2 -d python3-simplejson -d perl-YAML-Tiny -d python3-configargparse -d ea-apache24-mod_remoteip -d ea-apache24-mod_env -a noarch -m admin@innovahosting.net -e --description "nDeploy cPanel plugin" --url http://innovahosting.net --after-install ../after_ndeploy_install --before-remove ../after_ndeploy_uninstall --name nDeploy .
mv nDeploy-*.rpm ../RPMS -v
cd ..
