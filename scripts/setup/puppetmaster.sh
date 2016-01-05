#!/bin/bash
#export DEBIAN_FRONTEND=noninteractive #fix dpkg-preconfigure: unable to re-open stdin: No such file or directory

DOMAIN="dev.cloud.gwdg.de"


source /vagrant/environment/config.sh
# Derive nameserver IP from yaml
NAMESERVER_PREFIX="10.${ENVIRONMENT}"
NAMESERVER="${NAMESERVER_PREFIX}.1.2"

locale-gen de_DE.utf8

# Disable gro
apt-get install ethtool
ethtool -K eth0 gro off
ethtool -K eth1 gro off
ethtool -K eth2 gro off
ethtool -K eth3 gro off
ethtool -K eth4 gro off
ethtool -K eth5 gro off

# Update distro
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Downgrade / ping facter to 1.7.x to fix following error message:
# Could not evaluate: Could not retrieve information from environment cloud source(s) puppet://puppetmaster.cloud.gwdg.de/pluginfacts
apt-get -y --force-yes install facter=1.7.5-1puppetlabs1
apt-mark hold facter

# Some fancy stuff
cp /vagrant/files/.vimrc /root/

# Setup hosts file
#cp -av /etc/hosts /etc/hosts.orig

#HOSTNAME="$(hostname).cloud.gwdg.de"
#HOST_IP=$(cat /vagrant/files/hosts | grep puppetmaster | cut -d' ' -f1)

#cat /etc/hosts.orig | grep -v $HOSTNAME > /etc/hosts
#echo "$HOST_IP $HOSTNAME $(hostname)" >> /etc/hosts

#cat /vagrant/files/hosts | grep -v $HOSTNAME >> /etc/hosts

# ------------------------------------------------------------------------------------------------
# Setup puppetmaster

MODULE_NAME='compute-cloud'
ENVIRONMENT_NAME='cloud'

PUPPET_ENVIRONMENT="/etc/puppet/environments/$ENVIRONMENT_NAME"

apt-get -y install puppetmaster

mkdir /var/lib/puppet/state/graphs
chown puppet:puppet /var/lib/puppet/state/graphs

# Configure puppetmaster

#remove templatedir
sed -i 's/templatedir/#templatedir/g' /etc/puppet/puppet.conf

# Setup directory environments
echo 'environmentpath = $confdir/environments'      >> /etc/puppet/puppet.conf
echo "environment = $ENVIRONMENT_NAME"              >> /etc/puppet/puppet.conf
echo 'autosign = true'                              >> /etc/puppet/puppet.conf
echo 'storeconfigs = true'                          >> /etc/puppet/puppet.conf

# Disable caching (seems not to work though)
echo 'ignorecache = true'                           >> /etc/puppet/puppet.conf
echo 'usecacheonfailure = false'                    >> /etc/puppet/puppet.conf

# Link puppet modules directly from vagrant directory
mkdir -p $PUPPET_ENVIRONMENT/manifests
ln -s /vagrant/$MODULE_NAME $PUPPET_ENVIRONMENT/modules

# Also link hiera data
ln -s /vagrant/files/hiera $PUPPET_ENVIRONMENT/hiera

# Fix problems with parameter providers and environments:
rmdir /etc/puppet/modules
ln -s $PUPPET_ENVIRONMENT/modules /etc/puppet/modules

# Remove example environment
rm -Rfv /etc/puppet/environments/example_env

# Setup site.pp
ln -s /vagrant/files/site.pp $PUPPET_ENVIRONMENT/manifests/

# Setup hiera.yaml (via link)
ln -s /vagrant/files/hiera/hiera.yaml /etc/puppet/hiera.yaml

# Fix Error 400 on SERVER: invalid byte sequence in US-ASCII at ... https://tickets.puppetlabs.com/browse/PUP-1386
echo "LANG=de_DE.utf8" >> /etc/default/puppetmaster

# Restart puppetmaster
service puppetmaster restart

# ------------------------------------------------------------------------------------------------
# Setup puppetdb + apt-cacher-ng (via puppet)

puppet apply /vagrant/files/puppetmaster.pp  --modulepath /etc/puppet/environments/$ENVIRONMENT_NAME/modules --debug --graph

# Setup local puppet agent
cat >> /etc/puppet/puppet.conf << EOF

[agent]
server              = puppetmaster.$DOMAIN
environment         = cloud

ignorecache         = true
usecacheonfailure   = false
EOF

# Adapt dns resolution
cat > /etc/resolvconf/resolv.conf.d/head << EOF
# Managed by puppet
#
nameserver $NAMESERVER
search $DOMAIN
EOF

/sbin/resolvconf -u

# Restart puppetmaster to prevent it from being confused with facts when running puppet agent on the same host
service puppetmaster restart
