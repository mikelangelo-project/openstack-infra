#!/bin/bash
set -e

VERSION_PREFIX="2015.1+git+"
BUILD_DIR="/tmp/nova-docker"

# Install Build Tools
apt-get -y install python-stdeb

## Checkout Python Module
git clone https://github.com/gwdg/nova-docker.git $BUILD_DIR
cd $BUILD_DIR
git checkout stable/juno

## Create Debian Package Source
python setup.py --command-packages=stdeb.command debianize
SHA_1="$(git show-ref --heads --tags stable/juno -s10)"

# Change debian/changelog
sed -i "s/nova-docker (.*)/nova-docker ($VERSION_PREFIX$SHA_1)/g" "$BUILD_DIR/debian/changelog"

# Add to debian/rules:
sed -i "s/%:/export PYBUILD_NAME=nova-docker\n\n%:/g" "$BUILD_DIR/debian/rules"

# Change debian/compat:
echo "9" > "$BUILD_DIR/debian/compat"

cat > "$BUILD_DIR/debian/pydist-overrides" << EOF
docker-py python-docker
oslo.concurrency_ python-oslo.concurrency
EOF

## Build - after this step you find the deb file in the parent directory
dpkg-buildpackage -rfakeroot -uc -b
