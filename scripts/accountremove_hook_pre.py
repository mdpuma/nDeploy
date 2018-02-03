#!/usr/bin/env python


import yaml
import sys
import json
import os
import subprocess
import signal
import time


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
backend_config_file = installation_path+"/conf/backends.yaml"
nginx_dir = "/etc/nginx"


def remove_file(fn):
    if os.path.isfile(fn):
        os.remove(fn)
        #print('Removing file '+fn)
    else:
        print('Cant remove file '+fn)
    return

# Function defs
def remove_php_fpm_pool(user_name):
    """Remove the php-fpm pools of deleted accounts"""
    backend_data_yaml = open(backend_config_file, 'r')
    backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
    backend_data_yaml.close()
    if "PHP" in backend_data_yaml_parsed:
        php_backends_dict = backend_data_yaml_parsed["PHP"]
        for php_path in list(php_backends_dict.values()):
            phppool_link = php_path + '/etc/php-fpm.d/' + user_name + '.conf'
            phppool_file = '/opt/nDeploy/conf/php-fpm.d/' + user_name + '.conf'
            if os.path.islink(phppool_link):
                #print('Removing link '+phppool_link)
                os.remove(phppool_link)
            remove_file(phppool_file)
    phppool_socket_link = '/opt/fpmsockets/' + user_name + '.sock'
    if os.path.islink(phppool_socket_link) == True:
        os.remove(phppool_socket_link)
    return


cpjson = json.load(sys.stdin)
mydict = cpjson["data"]
cpaneluser = mydict["user"]

cpuserdatayaml = "/var/cpanel/userdata/" + cpaneluser + "/main"
if os.path.isfile(cpuserdatayaml) == False:
    print(("1 nDeploy:remove:"+cpaneluser+" Can't run script accountremove_hook_pre.py, due missing "+cpuserdatayaml+" file"))
    sys.exit()
    
cpaneluser_data_stream = open(cpuserdatayaml, 'r')
yaml_parsed_cpaneluser = yaml.safe_load(cpaneluser_data_stream)
cpaneluser_data_stream.close()

main_domain = yaml_parsed_cpaneluser.get('main_domain')
sub_domains = yaml_parsed_cpaneluser.get('sub_domains')

remove_file(installation_path+"/user-data/"+cpaneluser)
remove_file(installation_path+"/domain-data/"+main_domain)
remove_file(nginx_dir+"/sites-enabled/"+main_domain+".conf")
remove_file(nginx_dir+"/sites-enabled/"+main_domain+".include")

subprocess.call("rm -rf /var/resin/hosts/"+main_domain, shell=True)
if os.path.isfile("/var/cpanel/userdata/" + cpaneluser + "/" + main_domain + "_SSL"):
    remove_file(nginx_dir+"/ssl/"+main_domain+".crt")
for domain_in_subdomains in sub_domains:
    domain_in_subdomains_orig=domain_in_subdomains
    if domain_in_subdomains.startswith("*"):
        domain_in_subdomains="_wildcard_."+domain_in_subdomains.replace('*.','')
    remove_file(installation_path+"/domain-data/"+domain_in_subdomains)
    remove_file(nginx_dir+"/sites-enabled/"+domain_in_subdomains+".conf")
    remove_file(nginx_dir+"/sites-enabled/"+domain_in_subdomains+".include")
    subprocess.call("rm -rf /var/resin/hosts/"+domain_in_subdomains, shell=True)
    if os.path.isfile("/var/cpanel/userdata/" + cpaneluser + "/" + domain_in_subdomains_orig + "_SSL"):
        remove_file(nginx_dir+"/ssl/"+domain_in_subdomains+".crt")
remove_php_fpm_pool(cpaneluser)
subprocess.call("/opt/nDeploy/scripts/init_backends.php --action=reload >/dev/null", shell=True)
subprocess.call("/opt/nDeploy/scripts/reload_nginx.sh >/dev/null 2>&1", shell=True)
print(("1 nDeploy:remove:"+cpaneluser))
