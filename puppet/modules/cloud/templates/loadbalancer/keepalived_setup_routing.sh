#!/bin/bash

# Run from cli directly with:
#
# ./keepalived_setup_routing.sh INSTANCE blah {MASTER | BACKUP}

ROUTING_INTERNAL='<%= @routing_internal %>'
ROUTING_EXTERNAL='<%= @routing_public %>'

INTERNAL_GATEWAY='<%= @vip_internal_gateway %>'
EXTERNAL_GATEWAY='<%= @vip_public_gateway %>'

INTERNAL_INTERFACE='<%= @keepalived_internal_interface %>'
EXTERNAL_INTERFACE='<%= @keepalived_public_interface %>'

INTERNAL_IP='<%= @vip_internal_ip[0] %>'
INTERNAL_NETWORK='<%= @vip_internal_network %>'

EXTERNAL_IP='<%= @vip_public_ip[0] %>'
EXTERNAL_NETWORK='<%= @vip_public_network %>'

TABLE_INTERNAL_NAME="internal"
TABLE_EXTERNAL_NAME="public"

# Variables set by keepalived for 'notify'

# "INSTANCE" or "GROUP"
KEEPALIVED_TYPE=$1

# Name of instance or group
KEEPALIVED_NAME=$2

# Target state of transition, "MASTER", "BACKUP" or "FAULT"
KEEPALIVED_STATE=$3

logger "keepalived state change to ${KEEPALIVED_STATE}:"

IPROUTE2_FILE="/etc/iproute2/rt_tables"

# Get ip address from interface (not usable here as we have multiple ip addresses assigned to eth2)
# ip addr show eth2 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1

if grep -q "$TABLE_INTERNAL_NAME" $IPROUTE2_FILE
then
    # Entry found, nothing
   : 
else
    # Add entry
    echo "# Special routing for $INTERNAL_INTERFACE, so that internal access to corresponding lb vip works"
    echo "4 $TABLE_INTERNAL_NAME" >> $IPROUTE2_FILE
fi

if grep -q "$TABLE_EXTERNAL_NAME" $IPROUTE2_FILE
then
    # Entry found, nothing
   : 
else
    # Add entry
    echo "# Special routing for $EXTERNAL_INTERFACE, so that external access to corresponding lb vip works"
    echo "2 $TABLE_EXTERNAL_NAME" >> $IPROUTE2_FILE
fi


case $KEEPALIVED_STATE in
        "MASTER")
                    if [ "$ROUTING_INTERNAL" = true ] ; then

                        logger "Setting up routing for internal ip: ${INTERNAL_IP}"

                        # Set special routing rules
                        ip route flush table $TABLE_INTERNAL_NAME
                        ip route add $INTERNAL_NETWORK dev $INTERNAL_INTERFACE src $INTERNAL_IP table $TABLE_INTERNAL_NAME
                        ip route add default via $INTERNAL_GATEWAY dev $INTERNAL_INTERFACE table $TABLE_INTERNAL_NAME

                        # Can only delete one rule per call...
                        ip rule del table $TABLE_INTERNAL_NAME
                        ip rule del table $TABLE_INTERNAL_NAME

                        ip rule add from $INTERNAL_IP/32 table $TABLE_INTERNAL_NAME
                        ip rule add to $INTERNAL_IP/32 table $TABLE_INTERNAL_NAME
                    fi

                    # -----

                    if [ "$ROUTING_EXTERNAL" = true ] ; then

                        logger "Setting up routing for external ip: ${EXTERNAL_IP}"

                        # Set special routing rules
                        ip route flush table $TABLE_EXTERNAL_NAME
                        ip route add $EXTERNAL_NETWORK dev $EXTERNAL_INTERFACE src $EXTERNAL_IP table $TABLE_EXTERNAL_NAME
                        ip route add default via $EXTERNAL_GATEWAY dev $EXTERNAL_INTERFACE table $TABLE_EXTERNAL_NAME

                        # Can only delete one rule per call...
                        ip rule del table $TABLE_EXTERNAL_NAME
                        ip rule del table $TABLE_EXTERNAL_NAME

                        ip rule add from $EXTERNAL_IP/32 table $TABLE_EXTERNAL_NAME
                        ip rule add to $EXTERNAL_IP/32 table $TABLE_EXTERNAL_NAME
                    fi

                    ;;
        "BACKUP")
                    if [ "$ROUTING_INTERNAL" = true ] ; then
                        logger "Clearing up routing for internal ip: ${INTERNAL_IP}"

                        # Can only delete one rule per call...
                        ip rule del table $TABLE_INTERNAL_NAME
                        ip rule del table $TABLE_INTERNAL_NAME

                        ip route flush table $TABLE_INTERNAL_NAME
                    fi

                    # -----

                    if [ "$ROUTING_EXTERNAL" = true ] ; then
                        logger "Clearing up routing for external ip: ${EXTERNAL_IP}"

                        # Can only delete one rule per call...
                        ip rule del table $TABLE_EXTERNAL_NAME
                        ip rule del table $TABLE_EXTERNAL_NAME

                        ip route flush table $TABLE_EXTERNAL_NAME
                    fi

                    ;;
        "FAULT")
                    logger "Something went wrong!"

                    ;;

        *)          logger "Unknown state"
                    exit 1

                    ;;
esac

exit 0
