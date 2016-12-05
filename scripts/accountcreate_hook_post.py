#!/usr/bin/env python


import sys
import json
import subprocess
import os


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
cluster_config_file = installation_path+"/conf/ndeploy_cluster.yaml"
cpjson = json.load(sys.stdin)
mydict = cpjson["data"]
cpaneluser = mydict["user"]

subprocess.call(installation_path+"/scripts/generate_config.py "+cpaneluser, shell=True)
subprocess.call(installation_path+"/scripts/apache_php_config_generator.py "+cpaneluser, shell=True)
print("1 nDeploy:accountcreate:"+cpaneluser)