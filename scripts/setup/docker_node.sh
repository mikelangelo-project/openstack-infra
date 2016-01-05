#!/bin/bash

INSTALL_DIR='/opt/nova-docker/'
TEMP_DIR='/tmp/'

apt-get update

### Install Docker
wget -qO- https://get.docker.com/ | sh

### Nova get access to Docker Socket
usermod -a -G docker nova
service nova-compute restart

### Install Nova-Docker-Plugin

## Install deb package
apt-get -y install python-nova-docker

## Change /etc/nova/nova-compute.conf
sed -i 's/compute_driver.*/compute_driver=novadocker.virt.docker.DockerDriver/g' /etc/nova/nova-compute.conf

## create docker.filters in /etc/nova/rootwrap.d/
cat >> /etc/nova/rootwrap.d/docker.filters << EOF
# nova-rootwrap command filters for setting up network in the docker driver
# This file should be owned by (and only-writeable by) the root user

[Filters]
# nova/virt/docker/driver.py: 'ln', '-sf', '/var/run/netns/.*'
ln: CommandFilter, /bin/ln, root
EOF

### Restart Nova Service
service nova-compute restart
