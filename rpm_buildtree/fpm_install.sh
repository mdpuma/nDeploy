#!/bin/bash -e

yum install ruby ruby-devel rubygems rpm-build make gcc -y

gem install backports -v 3.21.0
gem install json -v 1.8.6 -V
gem install childprocess -v 1.0.1 -V
gem install git -v 1.7.0 -V
gem install rexml -v 3.2.2 -V
gem install fpm -V
