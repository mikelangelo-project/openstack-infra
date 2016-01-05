#!/bin/bash
#set -x

#
# Print error message and die
#
die () {
    echo >&2 "Fatal error: $@"
    exit 1
}

#
# Warn
#
warn() {
    echo >&2 "Warning: $@"
}

#
# Find absolute path to specified executable (locally). Die if the executable is not available.
#
# $1: global var to use for executable
# $2: executable name
#
find_local_executable () {

    local _executable_var=$1
    local _executable=$($WHICH $2)
    [ -z "$_executable" ] && die "'$2' command not found!"
    eval $_executable_var="'$_executable'"
}

