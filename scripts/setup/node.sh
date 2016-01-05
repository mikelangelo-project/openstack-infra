#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

DOMAIN="dev.cloud.gwdg.de"

source /vagrant/environment/config.sh
# Derive nameserver IP from yaml
IP_PREFIX="10.${ENVIRONMENT}"
NAMESERVER="${IP_PREFIX}.1.2"

locale-gen de_DE.utf8

# Disable gro
apt-get install ethtool
ethtool -K eth0 gro off
ethtool -K eth1 gro off
ethtool -K eth2 gro off
ethtool -K eth3 gro off
ethtool -K eth4 gro off
ethtool -K eth5 gro off

# Fix kernel to last known working combination with openvswitch
#apt-mark hold linux-image-3.8.0-32-generic
#apt-get -y purge linux-image-$(uname -r)
#apt-get -y install linux-image-3.8.0-32-generic
#apt-get -y install linux-headers-3.8.0-32-generic

# Update distro
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade

# Downgrade / ping facter to 1.7.x to fix following error message:
# Could not evaluate: Could not retrieve information from environment cloud source(s) puppet://puppetmaster.cloud.gwdg.de/pluginfacts
apt-get -y --force-yes install facter=1.7.5-1puppetlabs1
apt-mark hold facter

# Some fancy stuff
cp /vagrant/files/.vimrc /root/

# Setup hosts file
cp -av /etc/hosts /etc/hosts.orig

#HOSTNAME="$(hostname).cloud.gwdg.de"
#HOST_IP=$(cat /vagrant/files/hosts | grep $(hostname) | cut -d' ' -f1)

cat /etc/hosts.orig | grep -v $(hostname) > /etc/hosts
#echo "$HOST_IP $HOSTNAME $(hostname)" >> /etc/hosts

#cat /vagrant/files/hosts | grep -v $HOSTNAME >> /etc/hosts

# Setup puppet.conf 

mv /etc/puppet/puppet.conf /etc/puppet/puppet.conf.orig

#remove templatedir
#sed -i 's/templatedir/#templatedir/g' /etc/puppet/puppet.conf

cat > /etc/puppet/puppet.conf << EOF
[main]
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
#templatedir=\$confdir/templates

# Will be supported in newer puppet versions instead of configtimeout
#http_read_timeout       = 5m
#http_connect_timeout    = 5m

# Increase configtimeout to prevent failures when catalog compilation takes too long
configtimeout           = 5m

[master]
# These are needed when the puppetmaster is run by passenger
# and can safely be removed if webrick is used.
ssl_client_header = SSL_CLIENT_S_DN 
ssl_client_verify_header = SSL_CLIENT_VERIFY

[agent]
server              = puppetmaster.$DOMAIN
environment         = cloud

ignorecache         = true
usecacheonfailure   = false
EOF

echo "* Deployed new /etc/puppet/puppet.conf:"
diff -Naur /etc/puppet/puppet.conf.orig /etc/puppet/puppet.conf

# Adapt dns resolution
cat > /etc/resolvconf/resolv.conf.d/head << EOF
# Managed by puppet
#
nameserver $NAMESERVER
search $DOMAIN
EOF

/sbin/resolvconf -u

# Wait for cert
puppet agent -vt --noop --graph --debug --waitforcert 3

#Logstash - Rsyslog
echo "*.* @@$IP_PREFIX.1.3:514" > /etc/rsyslog.d/10-logstash.conf
service rsyslog restart

exit 0
