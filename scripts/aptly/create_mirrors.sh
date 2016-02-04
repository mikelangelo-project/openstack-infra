#!/bin/bash
#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

APTLY_DEFAULT_FLAGS="-architectures=amd64"
KEYSERVER="keys.gnupg.net"
#KEYSERVER="key.ip6.li"

#
# Create aptly mirror from url / ppa
#
# $1: mirror name
# $2: url
# $3: distro / components to mirror
# $4: id of the key
# $5: additional aptly flags to pass on
#

create_mirror () {

    local _name=$1
    local _source=$2
    local _selection=$3
    local _key_id=$4
    local _aptly_flags=$5
    local _aptly_filter=$6

    # Import key
    $GPG --no-default-keyring --keyring trustedkeys.gpg --keyserver $KEYSERVER --recv-keys $_key_id

    # Create mirror
    if [[ "$_source" =~ "^ppa\:" ]]; then
        # PPA mirror
        if [[ !  -z  $_aptly_filter  ]]; then
            $APTLY mirror create $APTLY_DEFAULT_FLAGS $_aptly_flags "$_aptly_filter" $_name $_source
        else
            $APTLY mirror create $APTLY_DEFAULT_FLAGS $_aptly_flags $_name $_source
        fi
    else
        # URL mirror
        if [[ !  -z  $_aptly_filter  ]]; then
            $APTLY mirror create $APTLY_DEFAULT_FLAGS $_aptly_flags "$_aptly_filter" $_name $_source $_selection
        else    
            $APTLY mirror create $APTLY_DEFAULT_FLAGS $_aptly_flags $_name $_source $_selection
        fi
    fi
}


# Find needed local executables

WHICH="/usr/bin/which"

find_local_executable APTLY aptly
find_local_executable GPG   gpg

# Configure mirrors

create_mirror   "mariadb"       "http://mirrors.n-ix.net/mariadb/repo/10.0/ubuntu"                      "trusty"                        "1BB943DB"  ""

# OpenStack mirror
create_mirror   "liberty-staging"   "http://ppa.launchpad.net/ubuntu-cloud-archive/liberty-staging/ubuntu"    "trusty main"                   "9F68104E"  ""
#create_mirror   "liberty"       "http://ubuntu-cloud.archive.canonical.com/ubuntu"                      "trusty-updates/liberty main"   "EC4926EA"  ""

create_mirror   "puppetlabs"    "http://apt.puppetlabs.com"                                             "trusty"                        "4BD6EC30"  ""

# Using package directly as this repo gets updated with instable versions
#create_mirror   "rabbitmq"      "http://www.rabbitmq.com/debian"                                       "testing"                       "056E8E56"  "" 

# Use openvswitch directly from ubuntu cloud archive for now
#create_mirror   "openvswitch"   "ppa:vshn/openvswitch"                                                 ""                              "19617013"  ""

create_mirror   "haproxy"       "ppa:vbernat/haproxy-1.5"                                               ""                              "1C61B9CD"  ""

create_mirror   "mongodb"       "http://downloads-distro.mongodb.org/repo/ubuntu-upstart"               "dist 10gen"                    "7F0CEB10"  "-filter-with-deps=true" "-filter=mongodb-org (>= 2.6.11)"

create_mirror   "logstash"      "http://packages.elasticsearch.org/logstash/1.5/debian"                 "stable main"                   "D88E42B4"  ""

create_mirror   "ceph"          "http://ceph.com/debian-hammer/"                                        "trusty main"                   "460F3994"  ""

