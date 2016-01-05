#!/bin/bash

SOURCE_DIR='/opt/rally/'

#Prepare Installation
apt-get update -q
apt-get -y install git

#Get Source Code
git clone https://github.com/gwdg/rally $SOURCE_DIR
cd $SOURCE_DIR
git checkout liberty
./install_rally.sh --verbose --yes --system

#Configure Rally
#. /root/openrc admin admin
#rally deployment create --fromenv --name=existing
#rally deployment check
echo "you can now create an deployment"
echo "edit /vagrant/rally/rally_deployment_bare.json - you find some parameters in /root/openrc"
echo "and than use 'rally deployment create --file /vagrant/rally/rally_deployment_bare.json --name bare_metal_with_users'"
