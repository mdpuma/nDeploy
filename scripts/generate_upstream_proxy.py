#!/usr/bin/env python3

import subprocess
import json
import os
import jinja2
import codecs
import re

__author__ = "Anoop P Alias"
__copyright__ = "Copyright Anoop P Alias"
__license__ = "GPL"
__email__ = "anoopalias01@gmail.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path

# Get ips list
p = subprocess.Popen(['/usr/local/cpanel/bin/whmapi1', 'listips', '--output=json'], stdout=subprocess.PIPE)
out, err = p.communicate()
iplist_json = json.loads(out)
data_dict = iplist_json.get('data')
ip_list = data_dict.get('ip')
cpanel_ip_list = []
for myip in ip_list:
    theip = myip.get('ip')
    if re.search("^(192\.168\.|10\.)", theip):
        continue
    
    cpanel_ip_list.append(theip)
    mainaddr_status = myip.get('mainaddr')
    if mainaddr_status == 1:
        mainip = theip

# Initiate Jinja2 templateEnv
templateLoader = jinja2.FileSystemLoader(installation_path + "/conf/templates")
templateEnv = jinja2.Environment(loader=templateLoader)
templateVars = {
    "MAINIP": mainip,
    "CPIPLIST": cpanel_ip_list
}

# Generate upstream.conf
upstream_server_template = templateEnv.get_template('upstream.conf.j2')
upstream_server_config = upstream_server_template.render(templateVars)
with codecs.open('/etc/nginx/conf.d/upstream.conf', 'w', 'utf-8') as upstream_server_config_file:
    upstream_server_config_file.write(upstream_server_config)
