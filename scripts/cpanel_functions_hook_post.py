#!/usr/bin/env python3


import sys
import json
import subprocess


__author__ = "Anoop P Alias"
__copyright__ = "Copyright Anoop P Alias"
__license__ = "GPL"
__email__ = "anoopalias01@gmail.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path

cpjson = json.load(sys.stdin)
try:
	mydict = cpjson["data"]
	cpaneluser = mydict["user"]
	subprocess.call("/opt/nDeploy/scripts/generate_config.py "+cpaneluser, shell=True)  # Assuming escalateprivilege is enabled
	subprocess.call("/opt/nDeploy/scripts/reload_nginx.sh", shell=True)  # Assuming escalateprivilege is enabled
	print(("1 nDeploy:cPaneltrigger:"+cpaneluser))
except:
	print("1 nDeploy:cPaneltrigger:skipping hook due missing stdin[data[user]]")
