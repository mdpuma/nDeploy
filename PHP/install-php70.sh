#!/bin/bash -e

VERSION=7.0.12
EXTENSIONS="opcache imagick uploadprogress"

source ~/.phpbrew/bashrc
export PHPBREW_ROOT="/usr/local/phpbrew"
phpbrew update

# first, apply patch and autoconf
# php -n /usr/bin/phpbrew install --patch php-fpm.5.4.dl.v2.patch --no-install --no-configure $VERSION
# cd /usr/local/phpbrew/build/php-$VERSION; ./buildconf --force

# compile & install
php -d memory_limit=512M -d disable_functions= /usr/bin/phpbrew install --jobs 12 $VERSION +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr

# switch
source ~/.phpbrew/bashrc
phpbrew use $VERSION

# mkdir php-fpm.d
mkdir /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php-fpm.d -p

# install extensions
for i in $EXTENSIONS; do
  phpbrew ext install $i
  if [ $? -ne 0 ]; then
    break 2
  fi
  phpbrew ext enable $i
done

phpbrew ext install github:php-memcached-dev/php-memcached php7 -- --disable-memcached-sasl

# enable gd
echo extension=gd.so > /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/gd.ini

/opt/nDeploy/scripts/update_backend.py PHP $PHPBREW_PHP /usr/local/phpbrew/php/$PHPBREW_PHP