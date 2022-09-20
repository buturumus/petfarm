#!/usr/bin/python3
# upd_silent_ids.py

import re
import os
import fabric
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
                ' echo ' + RMT_PW + ' | sudo -S bash -c '
                + '"if ['
                + ' `grep escape /etc/screenrc &> /dev/null ; echo $?` = 1 '
                + '] ; then '
                + ' echo escape ^Bb >> /etc/screenrc ; '    # todo: escape?
                + ' echo -e \\nscreenrc-modified ; '
                + 'else '
                + ' echo -e \\nscreenrc-is-already-modified '
                + '; fi"'
            ),
            'comment': 'Changing rmt Screen hotkey',
        },
    ]
    print('\nProcessing ' + srv + ':')
    # ssh-copy-id
    print('Updating ssh keys...')
    cmd_result = os.popen(
        'sshpass -p ' + RMT_PW
        + ' ssh-copy-id -o StrictHostKeyChecking=no '
        + RMT_USERNAME + '@' + srv
    ).read()
    print(cmd_result)
    # remote ssh commands
    for action in ssh_exec_data:
        print('\n' + action['comment'])
        conn = fabric.Connection(
            f'{RMT_USERNAME}@{srv}',
            # connect_kwargs={'password': RMT_PW}
        )
        try:
            res = conn.run(action['rmt_cmd'], hide='both', warn=True)
            print(res)
        except:
            print('Error on this remote cmd\n')
            continue

