#!/usr/bin/env python3


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
theaddon = mydict["domain"]
conversionstatus = mydict["status"]

if conversionstatus == 1:
    # we find the associated subdomain from /etc/userdatadomains.json copied in pre script
    with open(installation_path+"/lock/"+theaddon, 'r') as userdatadomains:
        userdatadom = json.load(userdatadomains)
    addondata = userdatadom.get(theaddon)
    addonconfigdom = addondata[3]
    silentremove(installation_path+"/domain-data/"+addonconfigdom)
    silentremove(nginx_dir+addonconfigdom+".conf")
    silentremove(nginx_dir+addonconfigdom+".include")
    #silentremove(nginx_dir+addonconfigdom+".nxapi.wl")
    subprocess.Popen("/opt/nDeploy/scripts/reload_nginx.sh", shell=True)
    silentremove(installation_path+"/lock/"+theaddon)
    print(("1 nDeploy:cPaneltrigger:ConvertAddon:"+addonconfigdom))
else:
    silentremove(installation_path+"/lock/"+theaddon)
    print(("0 nDeploy:SkipHook:ConvertAddon:"+addonconfigdom))
