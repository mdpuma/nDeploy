#!/usr/bin/env python3
import os
import socket
import sys
import yaml
import cgi
import cgitb


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path


cgitb.enable()


def close_cpanel_liveapisock():
    """We close the cpanel LiveAPI socket here as we dont need those"""
    cp_socket = os.environ["CPANEL_CONNECT_SOCKET"]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(cp_socket)
    sock.sendall(str.encode('<cpanelxml shutdown="1" />'))
    sock.close()

close_cpanel_liveapisock()
cpaneluser = os.environ["USER"]
cpuserdatayaml = "/var/cpanel/userdata/" + cpaneluser + "/main"
cpaneluser_data_stream = open(cpuserdatayaml, 'r')
yaml_parsed_cpaneluser = yaml.safe_load(cpaneluser_data_stream)
cpaneluser_data_stream.close()
main_domain = yaml_parsed_cpaneluser.get('main_domain')
sub_domains = yaml_parsed_cpaneluser.get('sub_domains')


print('Content-Type: text/html')
print('') 
print('<html>')
print('<head>')
print('<title>nDeploy</title>')
print('</head>')
print('<body>')
print('<a href="ndeploy.live.cgi"><img border="0" src="nDeploy.png" alt="nDeploy"></a>')
print('<HR>')
print('<form action="selector.live.cgi" method="post">')
print('<select name="domain" size="10">')
if main_domain.startswith('*.'):
    print(('<option value="_wildcard_.'+main_domain.replace('*.','')+'">'+main_domain+'</option>'))
else:
    print(('<option value="'+main_domain+'">'+main_domain+'</option>'))

for domain_in_subdomains in sub_domains:
    if domain_in_subdomains.startswith('*.'):
        print(('<option value="_wildcard_.'+domain_in_subdomains.replace('*.','')+'">'+domain_in_subdomains+'</option>'))
    else:
        print(('<option value="'+domain_in_subdomains+'">'+domain_in_subdomains+'</option>'))
print('</select>')
print('<HR>')
print('<input type="submit" value="CONFIGURE">')
print('</form>')
print('<p style="background-color:LightGrey">(!) For Addon domain select the corresponding subdomain</p>')
print('<p style="background-color:LightGrey">(!) click on the nginx icon above to restart the configuration process anytime</p>')
print('</body>')
print('</html>')
