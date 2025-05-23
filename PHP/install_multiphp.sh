#!/bin/bash

extensions="curl cli ftp fpm gd imap intl mbstring mcrypt mysqlnd mysql mssql opcache pdo sockets xml zip litespeed fileinfo exif iconv"
versions="php56 php70 php71 php72 php73 php74"

for i in $versions; do
	for j in $extensions; do
		pkgs="$pkgs ea-$i-php-$j"
	done
done

yum install $pkgs
yum install ea-apache24-mod_lsapi
