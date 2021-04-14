#!/bin/bash -e

yum install ruby ruby-devel rubygems rpm-build make gcc -y

gem install json -v 1.8.6 -V
gem install childprocess -v 1.0.1 -V
gem install fpm -v 1.10.2 -V
