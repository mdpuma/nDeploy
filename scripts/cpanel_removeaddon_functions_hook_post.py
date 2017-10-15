#!/usr/bin/env python


import sys
import json
import subprocess
import os
import shutil

__author__ = "Anoop P Alias"
__copyright__ = "Copyright Anoop P Alias"
__license__ = "GPL"
__email__ = "anoopalias01@gmail.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
nginx_dir = "/etc/nginx/sites-enabled/"


# Define a function to silently remove files
def silentremove(filename):
    try:
        os.remove(filename)
    except OSError:
        pass


cpjson = json.load(sys.stdin)
mydict = cpjson["data"]
cpaneluser = mydict["user"]
hook_output = mydict["output"]
hook_output_dict = hook_output[0]
status = hook_output_dict["result"]
if status == 1:
    hookargs = mydict["args"]
    hookargs_subdomain = hookargs["subdomain"]
    conf_sub_domain = hookargs_subdomain.replace("_", ".", 1)
    silentremove(installation_path+"/domain-data/"+conf_sub_domain)
    silentremove(nginx_dir+conf_sub_domain+".conf")
    silentremove(nginx_dir+conf_sub_domain+".include")
    subprocess.Popen("/opt/nDeploy/scripts/reload_nginx.sh", shell=True)
    print(("1 nDeploy:cPaneltrigger:RemoveAddon:"+conf_sub_domain))
else:
    print(("0 nDeploy:cPaneltrigger:SkipHook"))
