#!/usr/bin/env python

import yaml
import sys
import os
import signal
import time
import argparse


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
nginx_dir = "/etc/nginx"


def remove_file(fn):
    if os.path.isfile(fn):
        os.remove(fn)
        print('Removing file '+fn)
    else:
        print('Cant remove file '+fn)
    return

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Remove additional domain/subdomain")
    parser.add_argument("DOMAIN")
    args = parser.parse_args()
    domain = args.DOMAIN
    
    remove_file(nginx_dir+"/sites-enabled/"+domain+".conf")
    remove_file(nginx_dir+"/sites-enabled/"+domain+".include")
    remove_file(installation_path+"/domain-data/"+domain)
    remove_file(nginx_dir+"/ssl/"+domain+".crt")