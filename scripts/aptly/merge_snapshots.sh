#!/bin/bash

# Create a snapshot of all mirrors by appending a suffix

#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

SUFFIX=$(date +"%Y%m%d")

if (( $# > 1 ))
then
    TARGET_SNAPSHOT=$1
    LOCAL_REPOSITORY=$2
    if (( $# == 3 ))
    then
        SUFFIX=$3
    fi
else
    die "At least two paramtere needed: TARGET_SNAPSHOT LOCAL_REPOSITORY [SUFFIX]!"
fi

#
# Create snapshots for all defined aptly mirrors
#

merge_snapshots () {

    local _source_snapshots=()
    for mirror in $($APTLY mirror list -raw) ; do
        _source_snapshots+=($mirror-$SUFFIX)
    done

    _source_snapshots+=($LOCAL_REPOSITORY-$SUFFIX)

    $APTLY snapshot merge -latest "$TARGET_SNAPSHOT-$SUFFIX" "${_source_snapshots[@]}"
}

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable APTLY aptly

merge_snapshots

