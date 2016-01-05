#!/bin/bash

# Delete publish of all snapshots

#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

DISTRO="trusty"

if (( $# == 2 ))
then
    ENDPOINT=$1
    TARGET_SNAPSHOT=$2
else
    die "Two parameters needed: ENDPOINT TARGET_SNAPSHOT!"
fi

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable APTLY aptly

$APTLY publish drop $DISTRO $ENDPOINT

exit 0
