#FROM debian:bullseye
FROM python:3.9
WORKDIR /base
COPY vpn.deb /base/
RUN \
  grep -v security /etc/apt/sources.list > /tmp/sources.list && \
  mv -f /tmp/sources.list /etc/apt/ && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install \
      aptitude apt-utils \
      gnupg2 ca-certificates \
      screen procps \
      net-tools iputils-ping traceroute bind9-host whois \
      debconf-utils dialog \
      wget curl vim \
      zsh coreutils \
      iptables openvpn openssh-client sshpass \
    && \
  echo 'deb [allow-insecure=yes] https://apt.releases.hashicorp.com '\
    ' bullseye main' >> /etc/apt/sources.list && \
  echo 'deb [allow-insecure=yes] https://packages.microsoft.com/repos/azure-cli/ '\
    ' bullseye main' >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y --allow-unauthenticated install \
      azure-cli terraform \
    && \
  echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
  echo 'resolvconf resolvconf/linkify-resolvconf boolean false' | debconf-set-selections && \
  apt-get update && \
  apt-get install -y resolvconf && dpkg -i /base/vpn.deb && \
  ssh-keygen -f /root/.ssh/id_rsa -q -N ""
