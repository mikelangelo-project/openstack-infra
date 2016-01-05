#!/bin/bash

#Basic
apt-get -y install 'openjdk-7-jre-headless'

#Logstash
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | apt-key add -
echo "deb http://packages.elasticsearch.org/logstash/1.5/debian stable main" > /etc/apt/sources.list.d/logstash.list

apt-get update
apt-get -y install logstash

cp /vagrant/files/logstash/10_elasticsearch.conf /etc/logstash/conf.d/.
cp /vagrant/files/logstash/logstash.init.d /etc/init.d/logstash

/opt/logstash/bin/plugin install logstash-filter-translate

#Kibana
mkdir -p /opt/kibana

wget -O /tmp/kibana.tar.gz https://download.elasticsearch.org/kibana/kibana/kibana-4.0.1-linux-x64.tar.gz
tar xvf /tmp/kibana.tar.gz -C /opt/kibana --strip-components=1

cp /vagrant/files/logstash/kibana.init.d /etc/init.d/kibana

service logstash start
sleep 2
service kibana start
