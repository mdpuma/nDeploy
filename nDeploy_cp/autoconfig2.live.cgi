#!/usr/bin/python
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
profile_config_file = installation_path+"/conf/profiles.yaml"


cgitb.enable()


def close_cpanel_liveapisock():
    """We close the cpanel LiveAPI socket here as we dont need those"""
    cp_socket = os.environ["CPANEL_CONNECT_SOCKET"]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(cp_socket)
    sock.sendall('<cpanelxml shutdown="1" />')
    sock.close()
    return


close_cpanel_liveapisock()
form = cgi.FieldStorage() 


print('Content-Type: text/html')
print('') 
if form.getvalue('domain') and form.getvalue('backend'):
    mydomain = form.getvalue('domain')
    mybackend = form.getvalue('backend')
    profileyaml = installation_path + "/domain-data/" + mydomain
    if os.path.isfile(profileyaml):
        profileyaml_data_stream = open(profileyaml, 'r')
        yaml_parsed_profileyaml = yaml.safe_load(profileyaml_data_stream)
        profileyaml_data_stream.close()
        redirecttossl = yaml_parsed_profileyaml.get('redirecttossl')
        http2 = yaml_parsed_profileyaml.get('http2')
        testcookie = yaml_parsed_profileyaml.get('testcookie')
        if os.path.isfile(backend_config_file) and os.path.isfile(profile_config_file):
            backend_data_yaml = open(backend_config_file, 'r')
            backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
            backend_data_yaml.close()
            profile_data_yaml = open(profile_config_file,'r')
            profile_data_yaml_parsed = yaml.safe_load(profile_data_yaml)
            profile_data_yaml.close()
            
            profile_branch_dict = profile_data_yaml_parsed[mybackend]
            backends_branch_dict = backend_data_yaml_parsed[mybackend]
            
            # Initiate Jinja2 templateEnv
            templateLoader = jinja2.FileSystemLoader(installation_path + "/nDeploy_cp/templates")
            templateEnv = jinja2.Environment(loader=templateLoader)
            
            server_template = templateEnv.get_template('autoconfig2.j2')
            templateVars = {"DOMAIN": mydomain,
                        "BACKEND": mybackend,
                        "PROFILES": profile_branch_dict,
                        "BACKENDS": backends_branch_dict,
                        "REDIRECTTOSSL": redirecttossl,
                        "HTTP2": http2,
                        "TESTCOOKIE": testcookie,
                        }
            print(server_template.render(templateVars))
        else:
            print('ERROR : nDeploy backend defs file i/o error')
    else:
        print('ERROR : domain-data file i/o error')
else:
    print('ERROR : Forbidden')
