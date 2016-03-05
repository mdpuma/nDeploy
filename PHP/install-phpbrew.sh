#!/bin/bash

curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew
chmod +x phpbrew
mv phpbrew /usr/bin/phpbrew

phpbrew init

sed -i 's/PHPBREW_ROOT="$HOME\/.phpbrew"/PHPBREW_ROOT="\/usr\/local\/phpbrew"/' ~/.phpbrew/bashrc

source ~/.phpbrew/bashrc