#!/usr/bin/python3
# run_rmt_in_screen.py

import os
import sys
from pathlib import Path
import fabric
from farm_creds import RMT_USERNAME

sys.tracebacklimit = 0
RMT_BASEDIR = '/home/' + RMT_USERNAME

PROVS = 'do'
LOCS = 'sg'
VM_IDS = '0'

if len(sys.argv) < 2:
    print('no rmt script/command')
    exit()

all_args = ' '.join(sys.argv[1:])
for prov in PROVS.split():
    for loc in LOCS.split():
        for vm_id in VM_IDS.split():
            try:
                conn = fabric.Connection(
                    RMT_USERNAME + '@' + prov + loc + vm_id,
                )
            except:
                print('Error connectiong to ' + prov + loc + vm_id + '\n')
                continue
            if Path(all_args).is_file():
                print(f'Copying script to {prov}{loc}{vm_id}...')
                conn.put(all_args)
                rmt_cmd = RMT_BASEDIR + '/' + os.path.basename(all_args)
                print('running...')
            else:
                rmt_cmd = all_args
                print(f'Running "{all_args}" on {prov}{loc}{vm_id}...')
            try:
                res = conn.run(rmt_cmd, hide='both', warn=True,)
            except:
                print('Error on remote cmd with ' + prov + loc + vm_id + '\n')
                continue
            print(res)
