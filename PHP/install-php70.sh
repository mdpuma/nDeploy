#!/bin/bash

VERSION=7.0.7
EXTENSIONS="opcache imagick pdo_firebird memcache uploadprogress"

source ~/.phpbrew/bashrc

# first, apply patch and autoconf
php -n /usr/bin/phpbrew install --patch php-fpm.5.4.dl.v2.patch --no-install --no-configure $VERSION
cd /usr/local/phpbrew/build/php-$VERSION; ./buildconf --force

# compile & install
php -n /usr/bin/phpbrew install --jobs 12 $VERSION +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr

# switch
source ~/.phpbrew/bashrc
phpbrew use $VERSION

# mkdir php-fpm.d
mkdir /usr/local/phpbrew/php/php-$VERSION/etc/php-fpm.d -p

# install extensions
for i in $EXTENSIONS; do
  phpbrew ext install $i
  if [ $? -ne 0 ]; then
    break 2
  fi
  phpbrew ext enable $i
done

# enable gd
echo extension=gd.so >> /usr/local/phpbrew/php/php-$VERSION/var/db/gd.ini

/opt/nDeploy/scripts/update_backend.py PHP php-$VERSION /usr/local/phpbrew/php/php-$VERSION