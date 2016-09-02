#!/bin/bash

yum install libmcrypt-devel openssl-devel gmp-devel curl-devel libcurl-devel libcurlssl-devel libicu-devel bzip2-devel readline-devel -y
yum install ImageMagick-devel sqlite-devel freetds-devel freetds
yum install firebird-devel -y

curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew
chmod +x phpbrew
mv phpbrew /usr/bin/phpbrew

phpbrew init

sed -i 's/PHPBREW_ROOT="$HOME\/.phpbrew"/PHPBREW_ROOT="\/usr\/local\/phpbrew"/' ~/.phpbrew/bashrc

source ~/.phpbrew/bashrc