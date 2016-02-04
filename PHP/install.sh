#!/bin/sh

yum install libmcrypt-devel openssl-devel gmp-devel curl-devel libcurl-devel libcurlssl-devel -y
yum install firebird-devel -y
yum install ImageMagick-devel sqlite-devel freetds-devel freetds

curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew
chmod +x phpbrew
sudo mv phpbrew /usr/bin/phpbrew

phpbrew init

# Download cloudlinux patches
if [ ! -f "cl-apache-patches.tar.gz" ]; then
	wget http://repo.cloudlinux.com/cloudlinux/sources/da/cl-apache-patches.tar.gz -O cl-apache-patches.tar.gz
fi

read

# patch -p1 < fpm-lve-php5.4.patch

source ~/.phpbrew/bashrc

export PHPBREW_ROOT=/usr/local/phpbrew
mkdir $PHPBREW_ROOT -v

# default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext
cd /opt/nDeploy/PHP
for ver in 5.4.45 5.6.17 7.0.2; do
  # first, apply patch and autoconf
  php -n /usr/bin/phpbrew --debug install --patch fpm-lve-php5.4.v2.patch --no-configure --no-install $ver
  
  cd /usr/local/phpbrew/build/php-$ver; ./buildconf --force
  
  # configure & make
  php -n /usr/bin/phpbrew --debug install --jobs 12 $ver +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr
  
  # check if lve is enabled
  strings /usr/local/phpbrew/build/php-$ver/sapi/fpm/php-fpm | grep fpm_lve -i
done

#  --with-mssql=/usr/lib64/ --enable-msdblib for mssql support

phpbrew use $ver

EXTENSIONS="imagick pdo_firebird memcache uploadprogress"
for i in $EXTENSIONS; do
  phpbrew ext install $i
  if [ $? -ne 0 ]; then
    exit $?
  fi
  phpbrew ext enable $i
done

phpbrew ext install imagick
phpbrew ext install pdo_dblib -- --with-libdir=lib64
phpbrew ext install pdo_firebird
phpbrew ext install memcache /memcached
phpbrew ext install uploadprogress

# devel
phpbrew ext install xhprof 0.9.4
phpbrew ext disable xhprof

# gd installed by main php compile
mkdir /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/ -p
echo extension=gd.so >> /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/gd.ini
phpbrew ext enable gd
phpbrew ext install gd -- --with-freetype-dir=/usr/include/freetype ???? not work

http://www.directadmin.com/imap.txt
https://github.com/phpbrew/phpbrew/issues/227
http://www.devsumo.com/technotes/2013/12/php-building-php-5-4-with-imap-on-red-hat-linux/
phpbrew ext install imap


/opt/nDeploy/scripts/update_backend.py PHP php-5.4.45 /usr/local/phpbrew/php/php-5.4.45


Extensions install
example mssql

phpize
./configure 
./configure --with-libdir=lib64
make
make install
