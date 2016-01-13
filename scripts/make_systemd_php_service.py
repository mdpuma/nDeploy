#!/usr/bin/env python

import subprocess
import yaml
import argparse
import os


__author__ = "Anoop P Alias"
__copyright__ = "Copyright 2014, PiServe Technologies Pvt Ltd , India"
__license__ = "GPL"
__email__ = "anoop.alias@piserve.com"


installation_path = "/opt/nDeploy"  # Absolute Installation Path
backend_config_file = installation_path+"/conf/backends.yaml"
systemd_path = "/etc/systemd/system"

backend_data_yaml = open(backend_config_file, 'r')
backend_data_yaml_parsed = yaml.safe_load(backend_data_yaml)
backend_data_yaml.close()
if "PHP" in backend_data_yaml_parsed:
    php_backends_dict = backend_data_yaml_parsed["PHP"]
    for php_version in list(php_backends_dict.keys()):
        print "Make "+systemd_path+"/"+php_version+".service"
        template_file = open(installation_path + "/conf/php-fpm.service.tmpl", 'r')
        service_file = open(systemd_path+"/"+php_version+".service", 'w')
        for line in template_file:
            line = line.replace('{PHPVERSION}', php_version)
            line = line.replace('{PHPPATH}', php_backends_dict[php_version])
            service_file.write(line)
        template_file.close()
        service_file.close()