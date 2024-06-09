#!/bin/bash -e

dnf module enable ruby:3.0

yum install ruby ruby-devel rubygems rpm-build make gcc -y

# for nginx build
yum install hiredis-devel -y

#gem install backports -v 3.21.0
#gem install json -v 1.8.6 -V
#gem install childprocess -v 1.0.1 -V
#gem install git -v 1.7.0 -V
#gem install rexml -v 3.2.2 -V
#gem install dotenv -v 2.8.1

gem install fpm -V


#dnf config-manager --set-enabled powertools
