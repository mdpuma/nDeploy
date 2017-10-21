#!/usr/bin/env python

import yaml
import os
import sys
import argparse
from generate_config import php_backend_add, php_backend_reload
import subprocess
import codecs
import jinja2

__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"
backend_config_file = installation_path + "/conf/backends.yaml"

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

def configure(username, reload):
    cpuserdatadir = "/var/cpanel/userdata/" + username
    if os.path.isdir(cpuserdatadir) == False and pwd.getpwnam(username) == False:
        print('ERROR : no such cpanel userdata dir ' + cpuserdatadir)
        sys.exit(1)

    if os.path.isfile(installation_path + "/conf/templates/user_data.yaml"):
        userdatayaml = installation_path + "/user-data/" + username
        if os.path.isfile(userdatayaml):
            userdatayaml_data_stream = open(userdatayaml,'r')
            yaml_parsed_userdata = yaml.safe_load(userdatayaml_data_stream)
            userdatayaml_data_stream.close()
            myversion = yaml_parsed_userdata.get('PHP')
            backend_data_yaml = open(backend_config_file, 'r')
            backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
            backend_data_yaml.close()
            if "PHP" in backend_data_yaml_parsed:
                php_backends_dict = backend_data_yaml_parsed["PHP"]
                php_path = php_backends_dict.get(myversion)
                if php_path == None:
                    print("No such php version available")
                    sys.exit(1)
                
                # remove php-fpm.d configs for following user
                remove_php_fpm_pool(username)
                
                # make config and reload php-fpm
                php_backend_add(username, "/home/" + username, myversion, php_path, reload)
                
                path_to_socket = php_path + "/var/run/" + username + ".sock"                    
                os.symlink(path_to_socket, "/opt/fpmsockets/" + username + ".sock")
            else:
                print("ERROR:: PHP Backends missing")
        else:
            subprocess.call("cp " + installation_path + "/conf/templates/user_data.yaml " + userdatayaml, shell=True)
            subprocess.call("chown " + username + ":" + username + " " + userdatayaml, shell=True)
            configure(username, reload)
    else:
        print('ERROR : no ' + installation_path + '/conf/templates/user_data.yaml file')
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Set PHP-FPM socket for cpanel user to be used with Apache HTTPD")
    parser.add_argument("CPANELUSER")
    parser.add_argument('-r', '--reload', default=0)
    args = parser.parse_args()
    configure(args.CPANELUSER, args.reload)
