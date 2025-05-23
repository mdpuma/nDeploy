#!/usr/bin/python3
import os
import socket
import sys
import yaml
import cgi
import cgitb
import jinja2


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
backend_config_file = installation_path+"/conf/backends.yaml"


cgitb.enable()


def close_cpanel_liveapisock():
    """We close the cpanel LiveAPI socket here as we dont need those"""
    cp_socket = os.environ["CPANEL_CONNECT_SOCKET"]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(cp_socket)
    sock.sendall(str.encode('<cpanelxml shutdown="1" />'))
    sock.close()


close_cpanel_liveapisock()
form = cgi.FieldStorage() 


print('Content-Type: text/html')
print('')
if form.getvalue('domain') and form.getvalue('custom'):
    mydomain = form.getvalue('domain')
    customconf = form.getvalue('custom')
    profileyaml = installation_path + "/domain-data/" + mydomain
    if os.path.isfile(profileyaml):
        profileyaml_data_stream = open(profileyaml, 'r')
        yaml_parsed_profileyaml = yaml.safe_load(profileyaml_data_stream)
        profileyaml_data_stream.close()
        backend_category = yaml_parsed_profileyaml.get('backend_category')
        backend_version = yaml_parsed_profileyaml.get('backend_version')
        if os.path.isfile(backend_config_file):
            backend_data_yaml = open(backend_config_file, 'r')
            backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
            backend_data_yaml.close()
            
            # Initiate Jinja2 templateEnv
            templateLoader = jinja2.FileSystemLoader(installation_path + "/nDeploy_cp/templates")
            templateEnv = jinja2.Environment(loader=templateLoader)
            
            with open('/etc/nginx/sites-enabled/'+mydomain+'.include', 'r') as content_file:
                content = content_file.read()
            content_file.close()
            
            server_template = templateEnv.get_template('autoconfig.j2')
            templateVars = {"DOMAIN": mydomain,
                        "BACKEND_CATEGORY": backend_category,
                        "BACKEND_VERSION": backend_version,
                        "BACKENDS": backend_data_yaml_parsed.keys(),
                        "CUSTOMCONF": customconf,
                        "CONF_CONTENT": content,
                        }
            print(server_template.render(templateVars))
        else:
            print('ERROR : nDeploy backend defs file i/o error')
    else:
        print('ERROR : domain-data file i/o error')
else:
    print('ERROR : Forbidden')
