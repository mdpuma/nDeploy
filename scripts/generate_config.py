#!/usr/bin/env python

import codecs
import yaml
import argparse
import subprocess
import os
import signal
import time
import sys
import pwd
import grp
import shutil
import jinja2
import json
from lxml import etree


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
nginx_dir = "/etc/nginx/"
control_script = installation_path+"/scripts/init_backends.php"

# Function defs

def railo_vhost_add_tomcat(domain_name, document_root, *domain_aname_list):
    """Add a vhost to tomcat and restart railo-tomcat app server"""
    tomcat_conf = "/opt/railo/tomcat/conf/server.xml"
    s1='<Host name="'+domain_name+'" appBase="webapps"><Context path="" docBase="'+document_root+'/" />'
    s2=''
    for domain in domain_aname_list:
        s2=s2+'<Alias>'+domain+'</Alias>'
    s3='</Host>'
    if s2:
        xmlstring = s1+s2+s3
    else:
        xmlstring = s1+s3
            
    new_xml_element=etree.fromstring(xmlstring)
    xml_data_stream = etree.parse(tomcat_conf)
    xml_root = xml_data_stream.getroot()
    for node1 in xml_root.iter('Service'):
        for node2 in node1.iter('Engine'):
            for node3 in node2.iter('Host'):
                if domain_name in list(node3.attrib.values()):
                    node2.remove(node3)
        node2.append(new_xml_element)
    xml_data_stream.write(tomcat_conf, xml_declaration=True, encoding='utf-8', pretty_print=True)
    subprocess.call('/opt/railo/railo_ctl restart', shell=True)
    return


def railo_vhost_add_resin(user_name, domain_name, document_root, *domain_aname_list):
    """Add a vhost to resin and restart railo-resin app server"""
    resin_conf_dir = "/var/resin/hosts/"
    if not os.path.exists(document_root+"/WEB-INF"):
        os.mkdir(document_root+"/WEB-INF", 0o770)
    if not os.path.exists(document_root+"/log"):
        os.mkdir(document_root+"/log", 0o770)
    uid_user = pwd.getpwnam(user_name).pw_uid
    uid_nobody = pwd.getpwnam("nobody").pw_uid
    gid_nobody = grp.getgrnam("nobody").gr_gid
    os.chown(document_root+"/WEB-INF", uid_user, gid_nobody)
    os.chown(document_root+"/log", uid_user, gid_nobody)
    os.chmod(document_root+"/WEB-INF", 0o770)
    os.chmod(document_root+"/log", 0o770)
    nsm = {None: "http://caucho.com/ns/resin"}
    mydict = { 'id': "/",'root-directory':document_root }
    page = etree.Element('host', nsmap=nsm)
    doc = etree.ElementTree(page)
    host_name = etree.SubElement(page, 'host-name')
    host_name.text = domain_name
    for domain in domain_aname_list:
        host_alias = etree.SubElement(page, 'host-alias')
        host_alias.text = domain
    web_app = etree.SubElement(page, 'web-app', mydict)
    if not os.path.exists(resin_conf_dir+domain_name):
        os.mkdir(resin_conf_dir+domain_name, 0o755)
    os.chown(resin_conf_dir+domain_name, uid_nobody, gid_nobody)
    host_xml_file = resin_conf_dir+domain_name+"/host.xml"
    outFile = open(host_xml_file, 'w')
    doc.write(host_xml_file, method='xml', pretty_print=True)
    outFile.close()
    os.chown(host_xml_file, uid_nobody, gid_nobody)
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


def nginx_server_reload():
    """Function to reload nginX config"""
    subprocess.call("/opt/nDeploy/scripts/reload_nginx.sh", shell=True)
    return


def php_backend_add(user_name, domain_home, phpversion, php_path, reload='1'):
    """Function to setup php-fpm pool for user and restart the master php-fpm"""
    phppool_file = installation_path + "/conf/php-fpm.d/" + user_name + ".conf"
    phppool_link = php_path + "/etc/php-fpm.d/" + user_name + ".conf"
    if not os.path.isfile(phppool_file):
        templateLoader = jinja2.FileSystemLoader(installation_path + "/conf/templates")
        templateEnv = jinja2.Environment(loader=templateLoader)
        template = templateEnv.get_template('php-fpm.pool.j2')
        templateVars = {"CPANELUSER": user_name,
                        "HOMEDIR": domain_home
                       }
        generated_config = template.render(templateVars)
        with codecs.open(phppool_file, 'w', 'utf-8') as confout:
            confout.write(generated_config)
    if os.path.islink(phppool_link) == True:
        os.remove(phppool_link)
    os.symlink(phppool_file, phppool_link)
       
    if reload == '1':
        php_backend_reload(phpversion)


def php_backend_reload(phpversion):
    if not os.path.isfile(installation_path+'/lock/skip_php-fpm_reload'):
        subprocess.Popen([control_script, '--action=reload', '--php='+phpversion])    


def nginx_confgen(is_suspended, user_name, domain_name, reload):
    """Function that generates nginx config given a domain name"""
    # Initiate Jinja2 templateEnv
    templateLoader = jinja2.FileSystemLoader(installation_path + "/conf/templates")
    templateEnv = jinja2.Environment(loader=templateLoader)
    
    # Get all Data from cPanel userdata files
    cpdomainyaml = "/var/cpanel/userdata/" + user_name + "/" + domain_name
    if not os.path.isfile(cpdomainyaml):
        print "Not exists userdata file "+cpdomainyaml
        return
    cpaneldomain_data_stream = open(cpdomainyaml, 'r')
    yaml_parsed_cpaneldomain = yaml.safe_load(cpaneldomain_data_stream)
    cpanel_ipv4 = yaml_parsed_cpaneldomain.get('ip')
    domain_home = yaml_parsed_cpaneldomain.get('homedir')
    document_root = yaml_parsed_cpaneldomain.get('documentroot')
    domain_sname = yaml_parsed_cpaneldomain.get('servername')
    if domain_sname.startswith("*"):
        domain_aname=domain_sname
        domain_sname="_wildcard_."+domain_sname.replace('*.','')
    else:
        domain_aname = yaml_parsed_cpaneldomain.get('serveralias')
    if domain_aname:
        domain_aname_list = domain_aname.split(' ')
    else:
        domain_aname_list = []
    domain_list = domain_sname + " " + domain_aname
    if 'ipv6' in list(yaml_parsed_cpaneldomain.keys()):
        if yaml_parsed_cpaneldomain.get('ipv6'):
            ipv6_addr_list = yaml_parsed_cpaneldomain.get('ipv6').keys()
            ipv6_addr = str(ipv6_addr_list[0])
            hasipv6 = True
        else:
            hasipv6 = False
            ipv6_addr = None
    else:
        hasipv6 = False
        ipv6_addr = None
        
    hasssl = 'disabled'
    redirecttossl = False
    sslcertificatefile = None
    sslcertificatekeyfile = None
    sslcacertificatefile = None
    sslcombinedcert = None
    cpdomainyaml_ssl = "/var/cpanel/userdata/" + user_name + "/" + domain_name + "_SSL"
    if os.path.isfile(cpdomainyaml_ssl):
        cpaneldomain_ssl_data_stream = open(cpdomainyaml_ssl, 'r')
        yaml_parsed_cpaneldomain_ssl = yaml.safe_load(cpaneldomain_ssl_data_stream)
        sslcertificatefile = yaml_parsed_cpaneldomain_ssl.get('sslcertificatefile')
        sslcertificatekeyfile = yaml_parsed_cpaneldomain_ssl.get('sslcertificatekeyfile')
        sslcacertificatefile = yaml_parsed_cpaneldomain_ssl.get('sslcacertificatefile')
        if sslcertificatefile:
            if os.path.isfile(sslcertificatefile) == True and os.path.isfile(sslcertificatekeyfile) == True:
                hasssl = 'enabled'
                sslcombinedcert = "/etc/nginx/ssl/" + domain_name + ".crt"
                
                filenames = [sslcertificatefile]
                if os.path.isfile(sslcacertificatefile) == True:
                    filenames.append(sslcacertificatefile)
                with codecs.open(sslcombinedcert, 'w', 'utf-8') as outfile:
                    for fname in filenames:
                        with codecs.open(fname, 'r', 'utf-8') as infile:
                            outfile.write(infile.read()+"\n")
            #else:
                #times=5
                #while times>0:
                    #print "Some of ssl certificate files is not exists, try again.."
                    #if sslcacertificatefile and os.path.isfile(sslcertificatefile) == True and os.path.isfile(sslcertificatekeyfile) == True:
                        #hasssl = 'enabled'
                        #sslcombinedcert = "/etc/nginx/ssl/" + domain_name + ".crt"
                        #filenames = [sslcertificatefile]
                        #if os.path.isfile(sslcacertificatefile) == True:
                            #filenames.append(sslcacertificatefile)
                        #with codecs.open(sslcombinedcert, 'w', 'utf-8') as outfile:
                            #for fname in filenames:
                                #with codecs.open(fname, 'r', 'utf-8') as infile:
                                    #outfile.write(infile.read()+"\n")
                        #print "Files for ssl certificates has found"
                        #break
                    #times-=1;
                    #time.sleep(1)
        else:
            sslcertificatefile = '/var/cpanel/ssl/apache_tls/'+domain_sname+'/combined'
            if os.path.isfile(sslcertificatefile) == True:
                hasssl = 'enabled'
                sslcombinedcert = sslcertificatefile
                sslcertificatekeyfile = sslcertificatefile
                
    # Get all data from nDeploy domain-data file
    if is_suspended:
        if os.path.isfile(installation_path + "/conf/templates/domain_data.suspended_local.yaml"):
            domain_data_file = installation_path + "/conf/templates/domain_data.suspended_local.yaml"
        else:
            domain_data_file = installation_path + "/conf/templates/domain_data.suspended.yaml"
    else:
        domain_data_file = installation_path + "/domain-data/" + domain_sname
    if not os.path.isfile(domain_data_file):
        if os.path.isfile(installation_path+"/conf/templates/domain_data_default_local.yaml"):
            TEMPLATE_FILE = installation_path+"/conf/templates/domain_data_default_local.yaml"
        else:
            TEMPLATE_FILE = installation_path+"/conf/templates/domain_data_default.yaml"
        shutil.copyfile(TEMPLATE_FILE, domain_data_file)
        cpuser_uid = pwd.getpwnam(cpaneluser).pw_uid
        cpuser_gid = grp.getgrnam(cpaneluser).gr_gid
        os.chown(domain_data_file, cpuser_uid, cpuser_gid)
        os.chmod(domain_data_file, 0o660)
    with open(domain_data_file, 'r') as domain_data_stream:
        yaml_parsed_domain_data = yaml.safe_load(domain_data_stream)
    # Following are the backend details that can be changed from the UI
    backend_category = yaml_parsed_domain_data.get('backend_category', None)
    apptemplate_code = yaml_parsed_domain_data.get('apptemplate_code', None)
    backend_path = yaml_parsed_domain_data.get('backend_path', None)
    backend_version = yaml_parsed_domain_data.get('backend_version', None)
    http2 = yaml_parsed_domain_data.get('http2', None)
    hsts = yaml_parsed_domain_data.get('hsts', None)
    redirecttossl = yaml_parsed_domain_data.get('redirect_to_ssl', None)
    testcookie = yaml_parsed_domain_data.get('testcookie', None)
    fastcgi_socket = False
    
    if hasssl == 'disabled':
        redirecttossl = 'disabled'
    
    if apptemplate_code is None:
        apptemplate_code = '1000.j2'
      
    if os.path.isfile(installation_path+'/conf/templates/'+apptemplate_code) is False:
        print('No apptemplate_code ' + apptemplate_code + ' in ' + installation_path + '/conf/templates')
        return 1
    
    # Since we have all data needed, lets render the conf to a file
    if os.path.isfile(installation_path+'/conf/templates/server.conf.local.j2'):
        TEMPLATE_FILE = 'server.conf.local.j2'
    else:
        TEMPLATE_FILE = 'server.conf.j2'
    server_template = templateEnv.get_template(TEMPLATE_FILE)
    templateVars = {"SSL": hasssl,
                    "CPANELIP": cpanel_ipv4,
                    "CPIPVSIX": ipv6_addr,
                    "IPVSIX": hasipv6,
                    "HTTP2": http2,
                    "HSTS": hsts,
                    "CPANELSSLCRT": sslcombinedcert,
                    "CPANELSSLKEY": sslcertificatekeyfile,
                    "CPANELCACERT": sslcacertificatefile,
                    "DOMAINNAME": domain_sname,
                    "DOMAINLIST": domain_list,
                    "DOCUMENTROOT": document_root,
                    "REDIRECTTOSSL": redirecttossl,
                    }
    generated_config = server_template.render(templateVars)
    with codecs.open(nginx_dir + "/sites-enabled/" + domain_sname + ".conf", "w", 'utf-8') as confout:
        confout.write(generated_config)
        
    # Generate the rest of the config(domain.include) based on the application template
    if os.path.isfile(installation_path + "/conf/custom/" + domain_sname + ".include"):
        shutil.copyfile(installation_path + "/conf/custom/" + domain_sname + ".include", nginx_dir + "/sites-enabled/" + domain_sname + ".include")
    else:
        app_template = templateEnv.get_template(apptemplate_code)
        # We configure the backends first if necessary
        if backend_category == 'PROXY':
            if backend_version == 'railo_tomcat':
                railo_vhost_add_tomcat(domain_server_name, document_root, *serveralias_list)
            elif backend_version == 'railo_resin':
                railo_vhost_add_resin(user_name, domain_server_name, document_root, *serveralias_list)
        elif backend_category == 'PHP':
            fastcgi_socket = backend_path + "/var/run/" + user_name + ".sock"
            if not os.path.isfile(fastcgi_socket):
                php_backend_add(user_name, domain_home, backend_version, backend_path, reload)
        elif backend_category == 'HHVM_NOBODY':
            fastcgi_socket = backend_path
        elif backend_category == 'HHVM':
            fastcgi_socket = domain_home+"/hhvm.sock"
            if not os.path.isfile(fastcgi_socket):
                hhvm_backend_add(user_name, domain_home)
        # We generate the app config from template next
        apptemplateVars = {"CPANELIP": cpanel_ipv4,
                          "DOMAINNAME": domain_sname,
                          "SOCKETFILE": fastcgi_socket,
                          "DOCUMENTROOT": document_root,
                          "UPSTREAM_PORT": backend_path,
                          "TESTCOOKIE": testcookie,
                          "PATHTOPYTHON": backend_path,
                          "PATHTORUBY": backend_path,
                          "PATHTONODEJS": backend_path,
                          }
        generated_app_config = app_template.render(apptemplateVars)
        with codecs.open(nginx_dir + "/sites-enabled/" + domain_sname + ".include", "w", 'utf-8') as confout:
            confout.write(generated_app_config)
        
# End Function defs

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Regenerate nginX and app server configs for cpanel user")
    parser.add_argument("CPANELUSER")
    parser.add_argument('-r', '--reload', default='0')
    args = parser.parse_args()
    cpaneluser = args.CPANELUSER
    
    cpuserdatayaml = "/var/cpanel/userdata/" + cpaneluser + "/main"
    if os.path.isfile(cpuserdatayaml) == False:
       print "userdata main file is not found"
       sys.exit(0)
    cpaneluser_data_stream = open(cpuserdatayaml, 'r')
    yaml_parsed_cpaneluser = yaml.safe_load(cpaneluser_data_stream)
    
    main_domain = yaml_parsed_cpaneluser.get('main_domain')
    #parked_domains = yaml_parsed_cpaneluser.get('parked_domains')   #This data is irrelevant as parked domain list is in ServerAlias
    #addon_domains = yaml_parsed_cpaneluser.get('addon_domains')     #This data is irrelevant as addon is mapped to a subdomain
    sub_domains = yaml_parsed_cpaneluser.get('sub_domains')
    
    # Check if a user is suspended and set a flag accordingly
    if os.path.exists("/var/cpanel/users.cache/" + cpaneluser):
        with open("/var/cpanel/users.cache/" + cpaneluser) as users_file:
            json_parsed_cpusersfile = json.load(users_file)
        if json_parsed_cpusersfile.get('SUSPENDED') == 1:
            is_suspended = True
        else:
            is_suspended = False
    else:
        # If cpanel users file is not present silently exit
        sys.exit(0)
    
    # Check & make mutex
    mutex_dir = installation_path+"/lock/"+cpaneluser+".mutex";
    if os.path.isdir(mutex_dir):
        print "Can't run generate_config due mutex exists"
        sys.exit(0)
    os.mkdir(mutex_dir)
    
    nginx_confgen(is_suspended, cpaneluser, main_domain, args.reload)  #Generate conf for main domain
    
    for domain_in_subdomains in sub_domains:
        nginx_confgen(is_suspended, cpaneluser, domain_in_subdomains, args.reload)  #Generate conf for sub domains which takes care of addon as well
    
    # Remove mutex
    os.rmdir(mutex_dir)
