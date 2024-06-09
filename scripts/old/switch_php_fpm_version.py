#!/usr/bin/env python

import yaml
import os
import sys
import argparse
import subprocess

__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
backend_config_file = installation_path+"/conf/backends.yaml"

# Function defs
def update_apache_backend(user_name, backend_category, backend_name):
    """Update php-fpm version from user-data file"""
    userdata_file = installation_path+"/user-data/"+user_name
    new_backend_data_yaml = {backend_category: backend_name}
    
    if "PHP" in backend_data_yaml_parsed:
        php_backends_dict = backend_data_yaml_parsed["PHP"]
        php_path = php_backends_dict.get(backend_name)
        if php_path == None:
            print("ERROR : No such php version available "+backend_name)
            sys.exit(1)
    
    if os.path.isfile(userdata_file) == False:
        print('ERROR : no userdata file '+userdata_file)
        sys.exit(1)
    
    with open(userdata_file,'w') as yaml_file:
        yaml_file.write(yaml.dump(new_backend_data_yaml, default_flow_style=False))
    yaml_file.close()

parser = argparse.ArgumentParser(description="Switch a apache php-fpm version")
parser.add_argument("CPANELUSER")
parser.add_argument("backend_category")
parser.add_argument("backend_name")
args = parser.parse_args()

backend_data_yaml = open(backend_config_file, 'r')
backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
backend_data_yaml.close()

update_apache_backend(args.CPANELUSER, args.backend_category, args.backend_name)