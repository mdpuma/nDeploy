#!/bin/bash

vers="53 54 55 56 70 71 72"

# php-cgi handler  application/x-httpd-ea-php70
# lsapi handler    application/x-httpd-ea-php70___lsphp

for i in $vers; do find -maxdepth 4 -name .htaccess -type f -print0 | xargs -0 -n2 grep AddType | grep "application/x-httpd-ea-php$i " | cut -d: -f1 | xargs; done


files=".."
for i in $vers; do for j in $files; do grep "application/x-httpd-ea-php$i " $j >/dev/null; [ $? -eq 0] && echo $j ; done; done
