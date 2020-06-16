#!/bin/bash

# This script will install and configure Cuckoo Sandbox
# on an Ubuntu 18.04 system running as a Proxmox guest.
#
# Prerequisites:
#
# - Ubuntu 18.04 guest VM with the following configuration:
#   - User account "cuckoo"
#   - 8 GB RAM
#   - 160 GB HDD
#
# This script should be run with sudo

# Install updates
apt-get update && apt-get upgrade

# Install dependencies
apt-get install python python-pip python-dev libffi-dev libssl-dev python-virtualenv python-setuptools libjpeg-dev zlib1g-dev swig mongodb postgresql libpq-dev virtualbox tcpdump apparmor-utils

# Create a host only network for Virtualbox
vboxmanage hostonlyif create

#onfigure Virtualbox user
usermod -a -G vboxusers cuckoo

#Disable built-in tcpdump
sudo aa-disable /usr/sbin/tcpdump

# Configure pcap user
groupadd pcap
usermod -a -G pcap cuckoo
chgrp pcap /usr/sbin/tcpdump
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

# Download volatility - used to generate memdumps
wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip
unzip volatility_2.6_lin64_standalone.zip

#Install m2crypto
pip install m2crypto

#Setup Python virtual environments
wget https://raw.githubusercontent.com/mostly-hrmless/Cuckoo-Setup/master/python_virtual_env.sh
chmod +x python_virtual_env.sh
./python_virtual_env.sh

# Activate Python virtual environments
source ~/.bashrc
mkvirtualenv -p python2.7 cuckoo

# Install Cuckoo - This is done inside the python virtual environment
pip install -U pip setuptools
pip install -U cuckoo

Download a sample Windows 7 ISO from Cuckoo
wget https://cuckoo.sh/win7ultimate.iso
mkdir /mnt/win7
chown cuckoo:cuckoo /mnt/win7/
mount -o ro,loop win7ultimate.iso /mnt/win7

# Install VMCloak	
pip install -U vmcloak
vmcloak init --verbose --win7x64 win7x64base --cpus 2 --ramsize 2048
vmcloak clone win7x64base win7x64cuckoo

# Configure Cuckoo
cuckoo init
cuckoo community --force

# Configure networking
sysctl -w net.ipv4.conf.vboxnet0.forwarding=1
sysctl -w net.ipv4.conf.ens18.forwarding=1
cuckoo rooter --sudo --group cuckoo
