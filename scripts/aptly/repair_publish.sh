#!/bin/bash
#set -x

#BASE_DIR="$(dirname $(readlink -f $0))"
BASE_DIR="/vagrant/scripts/aptly"

SUFFIX=$(date +"%Y%m%d")
LOCAL_REPOSITORY="liberty-local"

echo ">>> repair 'testing' repo using aptly..."

$BASE_DIR/create_mirrors.sh
$BASE_DIR/delete_publish.sh testing "testing-$SUFFIX"
$BASE_DIR/add_packages.sh $LOCAL_REPOSITORY
$BASE_DIR/update_mirrors.sh
$BASE_DIR/delete_snapshots.sh
$BASE_DIR/create_snapshots.sh $LOCAL_REPOSITORY $SUFFIX
$BASE_DIR/merge_snapshots.sh testing $LOCAL_REPOSITORY $SUFFIX
$BASE_DIR/publish.sh testing "testing-$SUFFIX"

exit 0

