1. When account is removed, there exists change that same php-fpm config exists in 2 versions


[2017-10-20 23:33:27 +0300] info [xml-api] Script hook returned an invalid response: 
[2017-10-20 23:33:27 +0300] info [xml-api]    script: /opt/nDeploy/scripts/accountremove_hook_pre.py
[2017-10-20 23:33:27 +0300] info [xml-api]  response: Reload successful php-5.4.45 (pid=184015)
[2017-10-20 23:33:27 +0300] info [xml-api]  -- End Garbage output -- 
[2017-10-20 23:33:28 +0300] info [xml-api] rebuild_files: working on domain (dinca.md)
[2017-10-20 23:33:28 +0300] info [xml-api] php-fpm: rebuild_files: restart fpm services for Apache
[2017-10-20 23:33:28 +0300] info [xml-api] php-fpm: fpm services restarted

2. If custom nginx config exists, generate_config.py will not generate (:D) php-fpm.d symlink and file