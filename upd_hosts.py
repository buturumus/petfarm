#!/usr/bin/python3
# upd_hosts.py

import os
import re

HOSTS_FILE = "/etc/hosts"
HOSTS_EXCL_MASK = '# farm'


class Prov:
    dirname = ''

    def __init__(self):
        self.dirpath = '/base/' + self.dirname


class TerrAzure(Prov):

    def __init__(self):
        self.dirname = 'terrazure'
        super().__init__()

    def get_tf_hosts(self):
        tf_output = os.popen(
            'terraform -chdir=' + self.dirpath + ' show'
        ).read()  # .splitlines()
        tf_hosts = re.findall(
            r'(computer_name[^"]+"[^"]+")'
            + r'|(public_ip_address[^e][^"]+"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")',
            tf_output
        )
        hosts_lines = []
        curr_pair = []
        count = 0
        for line in tf_hosts:
            for word in line:
                if word:
                    curr_pair.insert(
                        0,
                        re.findall('"[^"]+"', word)[0].replace('"', '')
                    )
                    if count:
                        hosts_lines.append(curr_pair)
                        curr_pair = []
                        count = 0
                    else:
                        count = 1
        return hosts_lines


class TerraDocean(Prov):

    def __init__(self):
        self.dirname = 'terradocean'
        super().__init__()

    def get_tf_hosts(self):
        tf_output = os.popen(
            'terraform -chdir=' + self.dirpath + ' show'
        ).read()  # .splitlines()
        tf_hosts = re.findall(
            r'(ipv4_address[^_][^\"]+\"[0-9\.]+\")'
            + r'|(name[^\"]+\"[0-9a-z\.]+\")',
            tf_output
        )
        tf_hosts.pop(0)
        hosts_lines = []
        curr_pair = []
        count = 0
        for line in tf_hosts:
            for word in line:
                if word:
                    curr_pair.append(
                        re.findall('"[^"]+"', word)[0].replace('"', '')
                    )
                    if count:
                        hosts_lines.append(curr_pair)
                        curr_pair = []
                        count = 0
                    else:
                        count = 1
        return hosts_lines


# get list of tf-registered farm addrs to add them later to hosts file
tf_hosts_lines = []
for cls in (TerrAzure, TerraDocean):
    hosts_adder = cls()
    tf_hosts_lines += hosts_adder.get_tf_hosts()

# current content of hosts file exept farm addrs
with open(HOSTS_FILE, 'r') as hosts_file:
    hosts_lines = hosts_file.read().splitlines()
    not_farm_hosts_lines = []
    for line in hosts_lines:
        if line.find(HOSTS_EXCL_MASK) == -1:
            not_farm_hosts_lines.append(line)
# write addrs to hosts file back
with open(HOSTS_FILE, 'w') as hosts_file:
    try:
        for line in not_farm_hosts_lines:
            hosts_file.write(line + '\n')
        for line_words in tf_hosts_lines:
            hosts_file.write(
                line_words[0] + ' ' + line_words[1]
                + ' ' + HOSTS_EXCL_MASK + '\n'
            )
        hosts_file.truncate()
    except:
        print("write error")

