#!/usr/bin/env python

import subprocess
import json
import os
import jinja2
import codecs


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
    cpanel_ip_list.append(theip)
    mainaddr_status = myip.get('mainaddr')
    if mainaddr_status == 1:
        mainip = theip

# Get server hostname
p = subprocess.Popen(['/usr/local/cpanel/bin/whmapi1', 'gethostname', '--output=json'], stdout=subprocess.PIPE)
out, err = p.communicate()
hostname_json = json.loads(out)
data_dict = hostname_json.get('data')
hostname = data_dict.get('hostname')

if os.path.isfile('/var/cpanel/ssl/cpanel/mycpanel.pem'):
    cpsrvdsslfile = '/var/cpanel/ssl/cpanel/mycpanel.pem'
else:
    cpsrvdsslfile = '/var/cpanel/ssl/cpanel/cpanel.pem'

# Initiate Jinja2 templateEnv
templateLoader = jinja2.FileSystemLoader(installation_path + "/conf/templates")
templateEnv = jinja2.Environment(loader=templateLoader)
templateVars = {"HOSTNAME": hostname,
                "MAINIP": mainip,
                "CPIPLIST": cpanel_ip_list,
                "CPSRVDSSL": cpsrvdsslfile
                }

# Generate default_server.conf
default_server_template = templateEnv.get_template('default_server.conf.j2')
default_server_config = default_server_template.render(templateVars)
with codecs.open('/etc/nginx/conf.d/default_server.conf', 'w', 'utf-8') as default_server_config_file:
    default_server_config_file.write(default_server_config)

# Generate cpanel_services.conf
cpanel_services_template = templateEnv.get_template('cpanel_services.conf.j2')
cpanel_services_config = cpanel_services_template.render(templateVars)
with codecs.open('/etc/nginx/conf.d/cpanel_services.conf', 'w', 'utf-8') as cpanel_services_config_file:
    cpanel_services_config_file.write(cpanel_services_config)

# Generate httpd_mod_remoteip.include
httpd_mod_remoteip_template = templateEnv.get_template('httpd_mod_remoteip.include.j2')
httpd_mod_remoteip_config = httpd_mod_remoteip_template.render(templateVars)

post_virtualhost_global_template = templateEnv.get_template('post_virtualhost_global.conf.j2')
post_virtualhost_global_config = post_virtualhost_global_template.render(templateVars)

if os.path.isdir("/etc/apache2"):
    with codecs.open('/etc/apache2/conf.d/includes/httpd_mod_remoteip.include', 'w', 'utf-8') as httpd_mod_remoteip_config_file:
        httpd_mod_remoteip_config_file.write(httpd_mod_remoteip_config)
    with codecs.open('/etc/apache2/conf.d/includes/post_virtualhost_global.conf', 'w+', 'utf-8') as httpd_post_virtualhost_global:
        httpd_post_virtualhost_global.write(post_virtualhost_global_config)
else:
    with codecs.open('/etc/httpd/conf/includes/httpd_mod_remoteip.include', 'w', 'utf-8') as httpd_mod_remoteip_config_file:
        httpd_mod_remoteip_config_file.write(httpd_mod_remoteip_config)
    with codecs.open('/etc/httpd/conf/includes/post_virtualhost_global.conf', 'w+', 'utf-8') as httpd_post_virtualhost_global:
        httpd_post_virtualhost_global.write(post_virtualhost_global_config)