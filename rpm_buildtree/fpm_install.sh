#!/bin/bash -e

yum install ruby ruby-devel rubygems rpm-build make gcc -y

gem install json -v 1.8.6 -V
gem install fpm -v 1.4.0 -V