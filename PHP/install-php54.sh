#!/bin/bash

VERSION=5.4.45
EXTENSIONS="zendopcache imagick pdo_firebird memcache uploadprogress"

source ~/.phpbrew/bashrc

# compile & install
php -n /usr/bin/phpbrew install --jobs 12 $VERSION +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr

# mkdir php-fpm.d
mkdir /usr/local/phpbrew/php/php-$ver/etc/php-fpm.d -p

# switch
phpbrew use $VERSION

# install extensions
for i in $EXTENSIONS; do
  phpbrew ext install $i
  if [ $? -ne 0 ]; then
    break 2
  fi
  phpbrew ext enable $i
done

# enable gd
echo extension=gd.so >> /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/gd.ini

# fix zendopcache
sed -i '/extension/s/zendopcache/opcache/' /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/zendopcache.ini

/opt/nDeploy/scripts/update_backend.py PHP $PHPBREW_PHP /usr/local/phpbrew/php/$PHPBREW_PHP