Host VM
* Ubuntu 16.04 desktop
* 8 GB RAM
* 160 GB HDD
* user called cuckoo

Useful info:
* https://hatching.io/blog/cuckoo-sandbox-setup/
* https://www.youtube.com/watch?v=QlQS4gk_lFU
* https://www.youtube.com/watch?v=FsF56772ZvU

Install Ubuntu and run apt upgrade

Install dependencies

```
sudo apt-get install python python-pip python-dev libffi-dev libssl-dev python-virtualenv python-setuptools libjpeg-dev zlib1g-dev swig mongodb postgresql libpq-dev virtualbox tcpdump apparmor-utils
```

Create host only network for vbox
```
vboxmanage hostonlyif create
```

Configure VBox user
```
sudo usermod -a -G vboxusers cuckoo
```

Disable built in tcpdump
```
sudo aa-disable /usr/sbin/tcpdump
```

Configure pcap user
```
sudo groupadd pcap
sudo usermod -a -G pcap cuckoo
sudo chgrp pcap /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
```

Download volatility - to generate memdumps
```
wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip
unzip volatility_2.6_lin64_standalone.zip
```

Install m2crypto
```
sudo pip install m2crypto
```

Setup Python virtual environments
```
#!/bin/bash
sudo apt-get update && sudo apt-get -y install virtualenv
sudo apt-get -y install virtualenvwrapper
echo "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh" >> ~/.bashrc
sudo apt-get -y install python3-pip
pip3 completion --bash >> ~/.bashrc
pip3 install --user virtualenvwrapper
echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" >> ~/.bashrc
echo "source ~/.local/bin/virtualenvwrapper.sh" >> ~/.bashrc
export WORKON_HOME=~/.virtualenvs
echo "export WORKON_HOME=~/.virtualenvs" >> ~/.bashrc
echo "export PIP_VIRTUALENV_BASE=~/.virtualenvs" >> ~/.bashrc 
source ~/.bashrc
```
Activate virtualenv
```
source ~/.bashrc
mkvirtualenv -p python2.7 cuckoo
```

Install Cuckoo - done inside virtualenv
```
(cuckoo)$ pip install -U pip setuptools
(cuckoo)$ pip install -U cuckoo
```

Download a win7 iso (change later)
```
wget https://cuckoo.sh/win7ultimate.iso
sudo mkdir /mnt/win7
sudo chown cuckoo:cuckoo /mnt/win7/
sudo mount -o ro,loop win7ultimate.iso /mnt/win7
```

Install VM Cloak	
```
pip install -U vmcloak
vmcloak init --verbose --win7x64 win7x64base --cpus 2 --ramsize 2048
vmcloak clone win7x64base win7x64cuckoo
```

Install some stuff in the sandbox VM
```
vmcloak install win7x64cuckoo adobepdf pillow dotnet java flash vcredist vcredist.version=2015u3 wallpaper
```

Create multiple snapshots
```
vmcloak snapshot --count 4 win7x64cuckoo 192.168.56.101
```

Configure Cuckoo
```
cuckoo init
cuckoo community --force
while read -r vm ip; do cuckoo machine --add $vm $ip; done < <(vmcloak list vms)
```

Note: Open $CWD/conf/virtualbox.conf and remove the entries in the machines = cuckoo1 line.

Configure networking
```
sudo sysctl -w net.ipv4.conf.vboxnet0.forwarding=1
sudo sysctl -w net.ipv4.conf.ens18.forwarding=1
cuckoo rooter --sudo --group cuckoo
```

Note: Edit $CWD/conf/routing.conf to tell Cuckoo what our outgoing interface is. Open routing.conf and change internet = none to internet = ens18 (or whatever your interface name is)

Enable Mongo Reporting
Edit $CWD/conf/reporing.conf and change the following:
```
[mongodb]
enabled = yes
```

Start the web interface
```
cuckoo
cuckoo web --host 0.0.0.0 --port 8080
```


