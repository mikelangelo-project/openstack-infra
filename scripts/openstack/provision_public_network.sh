#!/bin/bash

# Get auth data
source /root/openrc

DEBUG=false
OUTPUT_FILE="/tmp/output.txt"

PUBLIC_NETWORK_NAME="public"
PUBLIC_NETWORK_CIDR="141.5.112.0/23"
PUBLIC_NETWORK_GATEWAY="141.5.112.1"
PUBLIC_NETWORK_POOL="start=141.5.113.1,end=141.5.113.254"

# Set additional cmdline options for DEBUG
if $DEBUG ; then
    NEUTRON_OPT="$NEUTRON_OPT -v --debug"
fi

echo "* Creating public network"
neutron $NEUTRON_OPT -v --debug net-create public --router:external --provider:physical_network public --provider:network_type flat 

echo "* Creating subnet for public network"
neutron $NEUTRON_OPT -v --debug subnet-create --allocation-pool $PUBLIC_NETWORK_POOL --gateway $PUBLIC_NETWORK_GATEWAY --enable_dhcp=False $PUBLIC_NETWORK_NAME $PUBLIC_NETWORK_CIDR
neutron $NEUTRON_OPT -v --debug subnet-create --allocation-pool $PUBLIC_NETWORK_POOL --gateway $PUBLIC_NETWORK_GATEWAY --enable_dhcp=False $PUBLIC_NETWORK_NAME $PUBLIC_NETWORK_CIDR