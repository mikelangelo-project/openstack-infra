#!/bin/bash

## Install Pip

curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py"
python /tmp/get-pip.py

## Install nova-docker

git clone https://github.com/gwdg/nova-docker /tmp/nova-docker
cd /tmp/nova-docker
git checkout stable/kilo

python ./setup.py build
python ./setup.py install

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
