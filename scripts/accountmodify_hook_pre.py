#!/usr/bin/env python3


import sys
import os
import subprocess
try:
    import simplejson as json
except ImportError:
    import json
import shutil


__author__ = "Anoop P Alias"
__copyright__ = "Copyright Anoop P Alias"
__license__ = "GPL"
__email__ = "anoopalias01@gmail.com"


# Define a function to silently remove files
def silentremove(filename):
    try:
        os.remove(filename)
    except OSError:
        pass


# This hook script is called by cPanel before an account is modified
# We are intrested in username and main-domain name modifications
# Mainly take care of removing stuff here as the post-accountmodify hook will
# take care of creating new configs
installation_path = "/opt/nDeploy"  # Absolute Installation Path
nginx_dir = "/etc/nginx/sites-enabled/"

# Get data send by cPanel on stdin
cpjson = json.load(sys.stdin)
mydict = cpjson.get('data')
if mydict == None:
    print("1 nDeploy::skiphook::accountModify::pre")
    sys.exit(0)

cpaneluser = mydict["user"]

# sometimes cpanel/whm invoke this script without newuser atribute
if mydict["newuser"] == None:
    cpanelnewuser = cpaneluser
else:
    cpanelnewuser = mydict["newuser"]

maindomain = mydict["domain"]

# Get details of current main-domain and sub-domain stored in cPanel datastore
cpuserdatajson = "/var/cpanel/userdata/" + cpaneluser + "/main.cache"
with open(cpuserdatajson, 'r') as cpaneluser_data_stream:
    json_parsed_cpaneluser = json.load(cpaneluser_data_stream)
main_domain = json_parsed_cpaneluser.get('main_domain')
sub_domains = json_parsed_cpaneluser.get('sub_domains')

# If cPanel username is modified
if cpanelnewuser != cpaneluser or maindomain != main_domain:
    # Remove domains associated with the user
    silentremove(installation_path+"/domain-data/"+main_domain)
    silentremove(nginx_dir+main_domain+".conf")
    silentremove(nginx_dir+main_domain+".include")
    for domain_in_subdomains in sub_domains:
        if domain_in_subdomains.startswith("*"):
            domain_in_subdomains = "_wildcard_."+domain_in_subdomains.replace('*.', '')
        silentremove(installation_path+"/domain-data/"+domain_in_subdomains)
        silentremove(nginx_dir+domain_in_subdomains+".conf")
        silentremove(nginx_dir+domain_in_subdomains+".include")
    print("1 nDeploy:olddomain:"+main_domain+":newdomain:"+maindomain+":olduser:"+cpaneluser+":newuser:"+cpanelnewuser)
else:
    print("1 nDeploy::skiphook::accountModify::pre")
