#!/bin/bash -e

yum install ruby ruby-devel rubygems rpm-build make gcc -y

# for nginx build
yum install hiredis-devel -y

gem install fpm -V
