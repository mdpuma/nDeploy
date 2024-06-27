#!/usr/bin/env python3


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

installation_path = "/opt/nDeploy"  # Absolute Installation Path

# Get the values send by cPanel in stdin
cpjson = json.load(sys.stdin)
mydict = cpjson.get('data')

# Assuming someone changed the cPanel username
cpaneluser = mydict["username"]

subprocess.call(installation_path+"/scripts/generate_config.py "+cpaneluser, shell=True)
print(("1 nDeploy:instalssl:post:"+cpaneluser))
