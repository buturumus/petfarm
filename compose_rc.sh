#!/bin/bash
# compose_rc.sh

# import VPN_NAME, VPN_PW, RMT_USERNAME, RMT_PW
. $(dirname "$0")/vpn.cmds
. $(dirname "$0")/vpn_creds.py

if [ ! -f /base/configs/.zshrc ] ; then
  cp /base/zshrc_min /base/configs/.zshrc
fi
ln -s /base/configs/.zshrc $(echo $HOME)/
# python lib path fix
export PYTHONPATH=/usr/local/lib/python3.9/site-packages $PYTHONPATH
# wrong docker dns fix
RESOLV_TEXT=$(cat /etc/resolv.conf | tr \\n / | sed -r 's/\//\\n'/g) \
  && echo -e "nameserver 8.8.8.8\n"$RESOLV_TEXT > /etc/resolv.conf
cp /base/update-resolv.sh $VPN_ETC_DIR
$VPN_SYSINIT_CMD
grep VPN /base/vpn_creds.py | tr = \   # show creds
$VPN_LOGIN_CMD
$VPN_CONN_CMD
$VPN_STATUS_CMD
echo 'Enter to continue' && read A
python3 /base/upd_hosts.py
python3 /base/upd_silent_ids.py
# start inter.shell 
/usr/bin/zsh

