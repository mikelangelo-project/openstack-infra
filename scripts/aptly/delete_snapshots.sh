#!/bin/bash

# Create a snapshot of all mirrors by appending a suffix

#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

#
# Delete snapshots for all defined aptly mirrors and local repos
#

delete_snapshots () {

    for snapshot in $($APTLY snapshot list -raw) ; do
        echo ">>> Deleting snapshot '$snapshot'..."
        $APTLY snapshot drop -force  "$snapshot"
    done 
}

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable APTLY aptly

delete_snapshots

