#!/bin/bash -xe
#Author: Anoop P Alias

##Vars
NGINX_VERSION="1.20.1"
NGINX_RPM_ITER="1.20.1.el7"
OPENSSL_VERSION="1.1.1"
CACHE_PURGE_VERSION="2.3"

CURRENT_DIR=$PWD

CPU_COUNT=$(ls /sys/devices/system/cpu/cpu[0-9]* -d | wc -l)

rm -f nginx-pkg-64-centos7/nginx-nDeploy*rpm
rm -rf nginx-${NGINX_VERSION}* openssl-$OPENSSL_VERSION

rsync -a --exclude 'etc/rc.d' nginx-pkg-64-common/ nginx-pkg-64-centos7/

yum -y install rpm-build libcurl-devel pcre-devel git GeoIP-devel

[ ! -f openssl-$OPENSSL_VERSION.tar.gz ] && wget https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
tar -xvzf openssl-$OPENSSL_VERSION.tar.gz
# cd openssl-$OPENSSL_VERSION
# ./config --prefix=/usr/local/openssl-$OPENSSL_VERSION --openssldir=/usr/local/openssl-$OPENSSL_VERSION
# make
# make install

wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}/

wget https://github.com/FRiCKLE/ngx_cache_purge/archive/master.zip -O ngx_cache_purge.zip
unzip ngx_cache_purge.zip -d .

git clone https://github.com/kyprizel/testcookie-nginx-module.git

git clone https://github.com/nginx-modules/ngx_brotli.git
cd ngx_brotli
git submodule update --init
cd $CURRENT_DIR/nginx-${NGINX_VERSION}

./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nobody --group=nobody --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-http_gzip_static_module \
	--with-http_stub_status_module --with-http_geoip_module --with-file-aio --with-threads \
	--add-module=ngx_brotli --add-module=testcookie-nginx-module --add-module=ngx_cache_purge-master \
	--with-openssl=$CURRENT_DIR/openssl-$OPENSSL_VERSION \
	--with-openssl-opt=enable-tls1_3 \
	--with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'

make -j$CPU_COUNT

make DESTDIR=./tempo install

rsync -a tempo/usr/sbin ../nginx-pkg-64-centos7/usr/

cd ../nginx-pkg-64-centos7
mkdir -p var/log/nginx
mkdir -p var/run
chmod 644 etc/nginx/testcookie/testcookie_html/*
mkdir etc/nginx/status_html -p

fpm -s dir -t rpm -C ../nginx-pkg-64-centos7 --vendor "iphost.md" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) \
	-m admin@iphost.md -e --description "nDeploy custom nginx package" --url https://innovahosting.net --conflicts nginx \
	-d zlib -d openssl -d pcre -d libcurl --config-files /etc/nginx \
	--after-install ../after_nginx_install --before-remove ../after_nginx_uninstall --name nginx-nDeploy .

mv nginx-nDeploy*.rpm ../RPMS -v
