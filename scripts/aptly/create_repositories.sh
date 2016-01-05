#!/bin/bash
#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

APTLY_DEFAULT_FLAGS="-architectures=amd64"

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

create_repository () {
	local _name=$1
    local _aptly_flags=$2

    $APTLY repo create $APTLY_DEFAULT_FLAGS $_aptly_flags $_name
}

WHICH="/usr/bin/which"

find_local_executable APTLY aptly

create_repository "$LOCAL_REPOSITORY" ""
