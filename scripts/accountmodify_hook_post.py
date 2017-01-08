#!/usr/bin/env python


import yaml
import sys
import os
import time
import subprocess
try:
    import simplejson as json
except ImportError:
    import json

__author__ = "Anoop P Alias"
__copyright__ = "Copyright Anoop P Alias"
__license__ = "GPL"
__email__ = "anoopalias01@gmail.com"


# This script is supposed to be called by cPanel after an account is modified
# All we need to do is call config generator with the new username as arg
installation_path = "/opt/nDeploy"  # Absolute Installation Path
backend_config_file = installation_path+"/conf/backends.yaml"
nginx_dir = "/etc/nginx/sites-enabled/"

# Function defs
def remove_php_fpm_pool(user_name):
    """Remove the php-fpm pools of deleted accounts"""
    backend_data_yaml = open(backend_config_file, 'r')
    backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
    backend_data_yaml.close()
    if "PHP" in backend_data_yaml_parsed:
        php_backends_dict = backend_data_yaml_parsed["PHP"]
        for php_path in list(php_backends_dict.values()):
            phppool_file = php_path + "/etc/php-fpm.d/" + user_name + ".conf"
            if os.path.islink(phppool_file):
                os.remove(phppool_file)
    os.remove("/opt/fpmsockets/"+user_name+".sock")
    return

def silentremove(filename):
    try:
        os.remove(filename)
    except OSError:
        pass

# Get the values send by cPanel in stdin
cpjson = json.load(sys.stdin)
mydict = cpjson["data"]
# Assuming someone changed the cPanel username
cpanelnewuser = mydict["newuser"]
cpaneluser = mydict["user"]
maindomain = mydict["domain"]
# Calling the config generate script for the user
if cpanelnewuser != cpaneluser:
    subprocess.call(installation_path+"/scripts/generate_config.py "+cpanelnewuser, shell=True)
    silentremove(installation_path+"/conf/php-fpm.d/"+cpaneluser+".conf")
    remove_php_fpm_pool(cpaneluser)
    print(("1 nDeploy:postmodify:"+cpanelnewuser))
else:
    subprocess.call(installation_path+"/scripts/generate_config.py "+cpaneluser, shell=True)
    print(("1 nDeploy:postmodify:"+cpaneluser))