#!/usr/bin/python3
# upd_silent_ids.py

import re
import os
import farm_creds

RMT_USERNAME = farm_creds.RMT_USERNAME
RMT_PW = farm_creds.RMT_PW
HOSTS_FILE = '/etc/hosts'
HOSTS_EXCL_MASK = '# farm'


# current farm addrs from hosts file
with open(HOSTS_FILE, 'r') as hosts_file:
    hosts_lines = hosts_file.read().splitlines()
    farm_addrs = []
    for line in hosts_lines:
        if line.find(HOSTS_EXCL_MASK) != -1:
            farm_addrs.append(
                re.findall('[a-z][a-z0-9_]+', line)[0]
            )

# rmt.actions for every addr.
for srv in farm_addrs:
    ssh_exec_data = [
        {
            'rmt_cmd': (
                'sshpass -p ' + RMT_PW
                + ' ssh-copy-id -o StrictHostKeyChecking=no '
                + RMT_USERNAME + '@' + srv
            ),
            'comment': 'updating ssh keys',
        },
        {
            'rmt_cmd': (
                'ssh ' + RMT_USERNAME + '@' + srv
                + ' "echo ' + RMT_PW + ' | sudo -S bash -c '
                + '\\"if ['
                + ' `grep escape /etc/screenrc &> /dev/null ; echo $?` = 1 '
                + '] ; then '
                + ' echo escape ^Bb >> /etc/screenrc ; '    # todo: escape?
                + ' echo -e \\nscreenrc-modified ; '
                + 'else '
                + ' echo -e \\nscreenrc-is-already-modified '
                + '; fi\\""'
            ),
            'comment': 'changing rmt screen hotkey',
        },
    ]
    print('\nProcessing ' + srv + ':')
    for action in ssh_exec_data:
        print('\n' + action['comment'])
        cmd_result = os.popen(action['rmt_cmd']).read()
        print(cmd_result)

