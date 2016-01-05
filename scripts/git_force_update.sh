#!/bin/bash

PROJECT_BRANCH="liberty"

PROJECT_TOPLEVEL_DIR=$(dirname $(readlink -f $BASH_SOURCE))/..
#echo $PROJECT_TOPLEVEL_DIR

cd $PROJECT_TOPLEVEL_DIR
git pull
git submodule update --remote --init --recursive

cd $PROJECT_TOPLEVEL_DIR/compute-cloud
git checkout $PROJECT_BRANCH; git pull; git reset --hard origin/$PROJECT_BRANCH

git submodule foreach -q --recursive 'branch="$(git config -f $toplevel/.gitmodules submodule.$name.branch)"; git checkout $branch; git reset --hard origin/liberty'
