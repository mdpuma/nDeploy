#!/bin/bash -e
# 7.1.3
# 7.0.17
# 5.6.30
# 5.5.38
# 5.4.45


VERSION=5.6.30
NAME="php-$VERSION"
EXTENSIONS="opcache imagick uploadprogress memcached mssql pdo_dblib redis sqlite3"

source ~/.phpbrew/bashrc
export PHPBREW_ROOT="/usr/local/phpbrew"

# first, apply patch and autoconf
php -n -d memory_limit=512M /usr/bin/phpbrew install --patch fpm-lve-php5.4_fixed.patch --no-install --no-configure $VERSION

# compile & install
php -n -d memory_limit=512M /usr/bin/phpbrew install --jobs 12 --name $NAME $VERSION +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr

# switch
source ~/.phpbrew/bashrc
phpbrew use $VERSION

# mkdir php-fpm.d
mkdir /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php-fpm.d -p

# install extensions
for i in $EXTENSIONS; do
  case $i in
    opcache)
      [ $VERSION == "5.4.45" ] && i=zendopcache
      phpbrew ext install $i
      sed -i '/extension/s/zendopcache/opcache/' /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/zendopcache.ini
      ;;
    memcached)
      phpbrew ext install github:php-memcached-dev/php-memcached php7 -- --disable-memcached-sasl
      ;;
    mssql)
      phpbrew ext install mssql -- --with-libdir=lib64
      ;;
    pdo_dblib)
      phpbrew ext install pdo_dblib -- --with-libdir=lib64
      ;;
    *)
      phpbrew ext install $i
      ;;
  esac
  if [ $? -ne 0 ]; then
    break 2
  fi
  phpbrew ext enable $i
done

# enable gd
echo extension=gd.so > /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/gd.ini

# update php.ini
mv /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php.ini /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php.ini.bak
cp php.ini.include /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php.ini

/opt/nDeploy/scripts/update_backend.py PHP $PHPBREW_PHP /usr/local/phpbrew/php/$PHPBREW_PHP