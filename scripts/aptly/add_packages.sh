#!/bin/bash
#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

APTLY_DEFAULT_FLAGS="-architectures=amd64 -remove-files=true -force-replace=true"
PACKAGE_DOWNLOAD_DIR="/tmp"
PACKAGE_DIR="$BASE_DIR/../../assets/aptly/deb/*.deb"

if (( $# == 1 ))
then
    LOCAL_REPOSITORY=$1
else
    die "Exactly one parameter needed: LOCAL_REPOSITORY!"
fi

#
# Create aptly mirror from url / ppa
#
# $1: repo name
# $2: url
# $3: distro / components to mirror
# $4: id of the key
# $5: additional aptly flags to pass on
#

add_package () {
	local _repo=$1
	local _source=$2
	local _package=$3
    local _aptly_flags=$4

    if [ -n "$_source" ]; then
        $WGET $_source -O $PACKAGE_DOWNLOAD_DIR/$_package
    fi

    $APTLY repo add $APTLY_DEFAULT_FLAGS $_aptly_flags $_repo $PACKAGE_DOWNLOAD_DIR/$_package
}

WHICH="/usr/bin/which"

find_local_executable WGET  wget
find_local_executable APTLY aptly

for f in $PACKAGE_DIR
do
    package_file=$(basename "$f") 
    cp $f $PACKAGE_DOWNLOAD_DIR/$package_file
    add_package "$LOCAL_REPOSITORY" "" "$package_file" ""
done

echo "Current content of local package repo: ${LOCAL_REPOSITORY}"
$APTLY repo show -with-packages $LOCAL_REPOSITORY

#add_package "$LOCAL_REPOSITORY" "http://www.rabbitmq.com/releases/rabbitmq-server/v3.4.4/rabbitmq-server_3.4.4-1_all.deb"  "rabbitmq-server_3.4.4-1_all.deb" ""
#add_package "$LOCAL_REPOSITORY" "http://rpc-repo.rackspace.com/downloads/rabbitmq-server_3.4.4-1_all.deb"                  "rabbitmq-server_3.4.4-1_all.deb" ""

#add_package "$LOCAL_REPOSITORY" "http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.4/rabbitmq-server_3.5.4-1_all.deb"   "rabbitmq-server_3.5.4-1_all.deb" ""

#add_package "$LOCAL_REPOSITORY" "http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.7/rabbitmq-server_3.5.7-1_all.deb"   "rabbitmq-server_3.5.7-1_all.deb"

add_package "$LOCAL_REPOSITORY" "http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.1/rabbitmq-server_3.6.1-1_all.deb"   "rabbitmq-server_3.6.1-1_all.deb"



