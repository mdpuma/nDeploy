#!/usr/bin/env python
# 
# This script will disable cpanel backups for customer which have plan named like Unlimited*
# 
# Add this in crontab
# 0 0 * * 0 /root/disable_backups.py
#

import yaml
import argparse
import subprocess
import os
import sys
import json
import re

def toggle_backups(user, state):
    p = subprocess.Popen(['/usr/local/cpanel/bin/whmapi1', 'toggle_user_backup_state', 'user='+user, 'legacy=0', '--output=json'], stdout=subprocess.PIPE)
    out, err = p.communicate()
    out_json = json.loads(out)
    data_dict = out_json.get('data')
    users = data_dict.get('acct')
    result = data_dict.get('toggle_status')
    if result!=state:
        toggle_backups(user, state)
    
def should_ignore(user):
    
    try:
        if excluded_users[user] == 'ignore':
            print("Should enable backup for "+user+" due exclude_users.txt file");
            toggle_backups(user, 1)
            return True
    
    except:
        return False


# load exceptions
excluded_users={}
try:

    f = open('exclude_users.txt', 'r')
    c = f.readlines()
    f.close()
    for i in c:
        i = i.strip()
        excluded_users[i] = 'ignore'
except:
    print("missing exclude_users.txt file, ignoring\n")
    
print("following exception found:\n")
print(excluded_users)


# get username, backup-state, hosting-plan
# /usr/local/cpanel/bin/whmapi1 listaccts want=user,backup,plan
p = subprocess.Popen(['/usr/local/cpanel/bin/whmapi1', 'listaccts', 'want=user,backup,plan,diskused', '--output=json'], stdout=subprocess.PIPE)
out, err = p.communicate()
out_json = json.loads(out)
data_dict = out_json.get('data')
users = data_dict.get('acct')

for i in users:
    user = i.get('user')
    backup = i.get('backup')
    plan = i.get('plan')
    diskused = i.get('diskused')
    backup_storage=10000
    
    if should_ignore(user) == True:
        continue
    
    if re.match("^Unlimited", plan):
        if plan == 'Unlimited_Full':
            backup_storage=60000
        elif plan == 'Unlimited_One':
            backup_storage=15000
        
        #print "user="+user+"; plan="+plan+"; diskused="+diskused
        du = re.search('\d+', diskused)
        if int(du.group(0))*4 > backup_storage and backup == 1:
            print "Disable backups for "+user+" due "+str(int(du.group(0))*4)+" > "+str(backup_storage)
            toggle_backups(user, 0)
        elif int(du.group(0))*4 < backup_storage and backup == 0:
            print "Enable backups for "+user+" due "+str(int(du.group(0))*4)+" < "+str(backup_storage)
            toggle_backups(user, 1)
    else:
        if backup==0:
            print "Enable backups for "+user
toggle_backups(user, 1) 
