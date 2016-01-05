#!/bin/bash
#set -x

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/base.sh

APTLY_VERSION="0.9.5"
APTLY_INSTALL_PATH="/usr/local/bin/"
APTLY_REPO="/var/lib/aptly"

# Find needed local executables
WHICH="/usr/bin/which"

find_local_executable WGET  wget
find_local_executable SED   sed

$WGET https://dl.bintray.com/smira/aptly/0.9.5/debian-squeeze-x64/aptly -O $APTLY_INSTALL_PATH/aptly
chmod a+x "$APTLY_INSTALL_PATH/aptly"

$WGET https://github.com/aptly-dev/aptly-bash-completion/raw/master/aptly -O /etc/bash_completion.d/aptly

mkdir -p $APTLY_REPO

# Create config

cat > /etc/aptly.conf << EOF
{
  "rootDir": "$APTLY_REPO",
  "downloadConcurrency": 4,
  "downloadSpeedLimit": 0,
  "architectures": [],
  "dependencyFollowSuggests": false,
  "dependencyFollowRecommends": false,
  "dependencyFollowAllVariants": false,
  "dependencyFollowSource": false,
  "gpgDisableSign": false,
  "gpgDisableVerify": false,
  "downloadSourcePackages": false,
  "ppaDistributorID": "ubuntu",
  "ppaCodename": "",
  "S3PublishEndpoints": {},
  "SwiftPublishEndpoints": {}
}
EOF

exit 0
