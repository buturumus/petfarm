#!/usr/bin/python3
# run_remotely.py arg
# arg is a command to be executed on the remote host(s)
# or a script to be executed in a Screen session

import os
import sys
from pathlib import Path
import re
import fabric
from farm_creds import RMT_USERNAME

sys.tracebacklimit = 0
RMT_BASEDIR = '/home/' + RMT_USERNAME

# data to set rmt hosts
PROVS = 'do'
LOCS = 'sg in'
VM_IDS = '0 1 2'
# PROVS = 'az'
# LOCS = 'br in kr'
# VM_IDS = '0 1 2'

if len(sys.argv) < 2:
    print('no rmt script/command')
    exit()

all_args = ' '.join(sys.argv[1:])
for prov in PROVS.split():
    for loc in LOCS.split():
        for vm_id in VM_IDS.split():
            try:
                conn = fabric.Connection(f'{RMT_USERNAME}@{prov}{loc}{vm_id}')
            except:
                print(f'Error connectiong to {prov}{loc}{vm_id}\n')
                continue
            if Path(all_args).is_file():
                print(f'Copying script {all_args} to {prov}{loc}{vm_id}...')
                conn.put(all_args)
                # if arg is a script run it in a Screen session not just run
                rmt_cmd = (
                    'screen -dmS '
                    + re.findall(r'[a-zA-Z0-9\-\.]+$', all_args)[-1]
                    + ' ' + RMT_BASEDIR + '/' + os.path.basename(all_args)
                )
                print('running...')
            else:
                rmt_cmd = all_args
                print(f'Running "{all_args}" on {prov}{loc}{vm_id}...')
            try:
                res = conn.run(rmt_cmd, hide='both', warn=True,)
            except:
                print(f'Error on remote cmd with {prov}{loc}{vm_id}\n')
                continue
            print(res)

