#!/bin/bash

# Create a snapshot of all mirrors by appending a suffix

#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

SUFFIX=$(date +"%Y%m%d")

if (( $# > 0 ))
then
    LOCAL_REPOSITORY=$1
    if (( $# == 2 ))
    then
        SUFFIX=$2
    fi
else
    die "At least one paramtere needed: LOCAL_REPOSITORY [SUFFIX]!"
fi

#
# Create snapshots for all defined aptly mirrors
#

create_snapshots () {

    for mirror in $($APTLY mirror list -raw) ; do
        echo ">>> Creating snapshot for mirror '$mirror'..."
        $APTLY snapshot create "$mirror-$SUFFIX" from mirror $mirror
    done 

    echo ">>> Creating snapshot for repo '$repo'..."
    $APTLY snapshot create "$LOCAL_REPOSITORY-$SUFFIX" from repo "$LOCAL_REPOSITORY"
}

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable APTLY aptly

create_snapshots

