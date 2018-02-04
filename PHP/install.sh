#!/bin/bash -e
# 
# phpbrew known
# Read local release list (last update: 2017-09-23 04:52:55 UTC).
# You can run `phpbrew update` or `phpbrew known --update` to get a newer release list.
# 7.2: 7.2.2, 7.2.1, 7.2.0 ...
# 7.1: 7.1.14, 7.1.13, 7.1.12, 7.1.11, 7.1.10, 7.1.9, 7.1.8, 7.1.7 ...
# 7.0: 7.0.27, 7.0.26, 7.0.25, 7.0.24, 7.0.23, 7.0.22, 7.0.21, 7.0.20 ...
# 5.6: 5.6.33, 5.6.32, 5.6.31, 5.6.30, 5.6.29, 5.6.28, 5.6.27, 5.6.26 ...
# 5.5: 5.5.37, 5.5.36, 5.5.35, 5.5.34, 5.5.33, 5.5.32, 5.5.31, 5.5.30 ...
# 5.4: 5.4.45, 5.4.44, 5.4.43, 5.4.42, 5.4.41, 5.4.40, 5.4.39, 5.4.38 ...


VERSION=5.6.31
NAME="php-$VERSION"
PHP_ARGS="-d memory_limit=512M"

# Additional extensions: memcache memcached redis sqlite3
EXTENSIONS="opcache imagick uploadprogress mssql pdo_dblib"

PATCH_CLOUDLINUX=0

source ~/.phpbrew/bashrc
export PHPBREW_ROOT="/usr/local/phpbrew"
WORKDIR=`pwd`

# patch
function apply_patch() {
    cp -v php-fpm.5.4.dl.v2.patch $1
    cd $1
    patch -p1 < php-fpm.5.4.dl.v2.patch
    autoconf
    cd -
}

if [ $PATCH_CLOUDLINUX -eq 1 ]; then
    # first just download
    php $PHP_ARGS /usr/bin/phpbrew $DEBUG install --no-install --no-configure --no-clean --dryrun $VERSION

    # apply patch
    apply_patch $PHPBREW_ROOT/build/php-$VERSION
fi

# compile & install
php $PHP_ARGS /usr/bin/phpbrew install --jobs 12 --name $NAME $VERSION +default +fpm +mysql +exif +ftp +gd +intl +soap +pdo +curl +gmp +imap +iconv +sqlite +gettext -- --with-libdir=lib64 --with-gd=shared --enable-gd-natf --with-jpeg-dir=/usr --with-png-dir=/usr

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
      [ $VERSION == "5.3.29" ] && i=zendopcache
      phpbrew ext install $i
      sed -i '/extension/s/zendopcache/opcache/' /usr/local/phpbrew/php/$PHPBREW_PHP/var/db/$i.ini
      ;;
    memcached)
      case $VERSION in
          7.*)
              phpbrew ext install github:php-memcached-dev/php-memcached php7 -- --disable-memcached-sasl
              ;;
          *)
              phpbrew ext install $i
              ;;
      esac
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
cp $WORKDIR/php.ini.include /usr/local/phpbrew/php/$PHPBREW_PHP/etc/php.ini

/opt/nDeploy/scripts/update_backend.py PHP $PHPBREW_PHP /usr/local/phpbrew/php/$PHPBREW_PHP