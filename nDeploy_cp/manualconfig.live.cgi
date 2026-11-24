#!/usr/bin/python3
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
backend_config_file = installation_path+"/conf/backends.yaml"
profile_config_file = installation_path+"/conf/profiles.yaml"


cgitb.enable()


def domain_belongs_to_user(domain):
    """SECURITY: confirm the requested domain belongs to the authenticated
    cPanel user before its config is read or written, and reject any path
    separator so a crafted value cannot escape the domain-data directory."""
    if not domain or '/' in domain or domain in ('.', '..'):
        return False
    cpaneluser = os.environ.get("USER", "")
    cpuserdatayaml = "/var/cpanel/userdata/" + cpaneluser + "/main"
    if not os.path.isfile(cpuserdatayaml):
        return False
    with open(cpuserdatayaml, 'r') as udf:
        ud = yaml.safe_load(udf) or {}

    def norm(d):
        if d and d.startswith('*.'):
            return "_wildcard_." + d.replace('*.', '')
        return d
    allowed = set()
    if ud.get('main_domain'):
        allowed.add(norm(ud.get('main_domain')))
    for sd in (ud.get('sub_domains') or []):
        allowed.add(norm(sd))
    return domain in allowed


def close_cpanel_liveapisock():
    """We close the cpanel LiveAPI socket here as we dont need those"""
    cp_socket = os.environ["CPANEL_CONNECT_SOCKET"]
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(cp_socket)
    sock.sendall(str.encode('<cpanelxml shutdown="1" />'))
    sock.close()
    return

def update_custom_profile(profile_yaml, value):
    """Function to set custom profile status in domain data yaml"""
    yaml_data_stream_toupdate = open(profile_yaml, 'r')
    yaml_profile_datadict = yaml.safe_load(yaml_data_stream_toupdate)
    yaml_data_stream_toupdate.close()
    yaml_profile_datadict["customconf"] = str(value)
    with open(profile_yaml, 'w') as yaml_file:
        yaml_file.write(yaml.dump(yaml_profile_datadict, default_flow_style=False))
    yaml_file.close()
    return

def update_config_test_status(profile_yaml, value):
    """Function to set custom profile status in domain data yaml"""
    yaml_data_stream_toupdate = open(profile_yaml, 'r')
    yaml_profile_datadict = yaml.safe_load(yaml_data_stream_toupdate)
    yaml_data_stream_toupdate.close()
    yaml_profile_datadict["testconf"] = str(value)
    with open(profile_yaml, 'w') as yaml_file:
        yaml_file.write(yaml.dump(yaml_profile_datadict, default_flow_style=False))
    yaml_file.close()
    return




close_cpanel_liveapisock()
form = cgi.FieldStorage() 


print('Content-Type: text/html')
print('') 
print('<html>')
print('<head>')
print('<title>nDeploy</title>')
print('</head>')
print('<body>')
print('<a href="ndeploy.live.cgi"><img border="0" src="nDeploy.png" alt="nDeploy"></a>')
print('<HR>')
if form.getvalue('domain') and form.getvalue('custom'):
    mydomain = form.getvalue('domain')
    if not domain_belongs_to_user(mydomain):
        print('ERROR : Forbidden')
        sys.exit(0)
    customconf = form.getvalue('custom')
    profileyaml = installation_path + "/domain-data/" + mydomain
    if os.path.isfile(profileyaml):
        profileyaml_data_stream = open(profileyaml, 'r')
        yaml_parsed_profileyaml = yaml.safe_load(profileyaml_data_stream)
        profileyaml_data_stream.close()
        backend_category = yaml_parsed_profileyaml.get('backend_category')
        backend_version = yaml_parsed_profileyaml.get('backend_version')
        print(('<p style="background-color:LightGrey">CONFIGURE:  '+mydomain+'</p>'))
        print('<HR>')
        if customconf == '1':
            print('<form action="update.live.cgi" method="post">')
            print('<textarea name="textcontent" cols="120" rows="50">')
            with open('/etc/nginx/sites-enabled/'+mydomain+'.include', 'r') as content_file:
                content = content_file.read()
            content_file.close()
            print(content)
            print('</textarea>')
            print('<HR>')
            print('<input type="submit" value="Submit" />')
            print(('<input style="display:none" name="domain" value="'+mydomain+'">'))
            print('</form>')
            print('<HR>')
            print('<p style="background-color:LightGrey">(!) You can use FASTCGICACHE as the cache zone with fastcgi_cache directive</p>')
            print('<p style="background-color:LightGrey">(!) You can use PROXYCACHE as the cache zone with proxy_cache directive</p>')
        elif customconf == '0':
            print('<HR>')
            update_custom_profile(profileyaml, 0)
            print(('<p style="background-color:LightGrey">(!) config mode reset .You are using ' + backend_category + ' as backend and '+ backend_version + ' as type/version </p>')) 
        else:
            print('ERROR : Invalid POST data') 

    else:
        print('ERROR : domain-data file i/o error')
else:
    print('ERROR : Forbidden')
print('</body>')
print('</html>')
