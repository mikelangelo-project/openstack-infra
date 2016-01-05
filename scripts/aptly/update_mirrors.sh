#!/bin/bash
#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

#
# Update all defined aptly mirrors
#

update_mirrors () {

    for mirror in $($APTLY mirror list -raw) ; do
        echo ">>> Updating mirror '$mirror'..."
        $APTLY mirror update $mirror
    done 
}

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable APTLY aptly

update_mirrors

