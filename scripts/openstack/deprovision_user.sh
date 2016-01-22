#!/bin/bash

# Get auth data
source /root/openrc

DEBUG=false
OUTPUT_FILE="/tmp/output.txt"

USER="test1"
USER_TENANT=$USER

# Additional cmdline options
NEUTRON_OPT=""
NOVA_OPT=""
CINDER_OPT=""
KEYSTONE_OPT=""

function get_id () {
    echo `"$@" | tee $OUTPUT_FILE | awk '/ id / { print $4 }'`
}

# Set additional cmdline options for DEBUG
if $DEBUG ; then
    NEUTRON_OPT="$NEUTRON_OPT -v"
    NOVA_OPT="$NOVA_OPT --debug"
    CINDER_OPT="$CINDER_OPT --debug"
    KEYSTONE_OPT="$KEYSTONE_OPT --debug"
fi

if [ -z "$USER_TENANT" ]; then
    echo "ERROR: Can not process without user!"
    exit 1
fi 

# Get tenant id
echo "* Getting tenant-id of tenant '$USER_TENANT'"
TENANT_ID=$(keystone $KEYSTONE_OPT tenant-list  | tee $OUTPUT_FILE  | grep " $USER_TENANT "    | awk '{ print $2 }')
cat $OUTPUT_FILE

if [ -z "$TENANT_ID" ]; then
    echo "ERROR: Can not find tenant id for User $USER_TENANT!"
    echo "ERROR: Can not process without tenant id!"
    exit 1
fi

#echo $TENANT_ID

# Delete all vms of tenant
echo "* Deleting all VMs of tenant-id '$TENANT_ID'"
nova $NOVA_OPT list --tenant $TENANT_ID --all-tenants |  tee $OUTPUT_FILE | grep " private-" | while read line
do
    VM_ID=$(echo $line | awk '{ print $2 }')
    VM_NAME=$(echo $line | awk '{ print $4 }')
    echo "  - deleting VM '$VM_NAME' ($VM_ID)"
    nova $NOVA_OPT delete $VM_ID
done
cat $OUTPUT_FILE


# Delete all routers of tenant
echo "* Deleting all routers of tenant-id '$TENANT_ID'"

# Get private subnet id
PRIVATE_SUBNET_ID=$(neutron $NEUTRON_OPT net-list | tee $OUTPUT_FILE  | grep "$TENANT_ID " | awk '{ print $6 }')

neutron $NEUTRON_OPT router-list |  tee $OUTPUT_FILE | grep "$TENANT_ID" | while read line
do
    ROUTER_ID=$(echo $line | awk '{ print $2 }')
    ROUTER_NAME=$(echo $line | awk '{ print $4 }')

    if [[ $ROUTER_ID ]]; then

        echo "  - deleting router '$ROUTER_NAME' ($ROUTER_ID)"
    
        # Clear gateway port
        neutron $NEUTRON_OPT router-gateway-clear $ROUTER_ID

        # Clear public ip subnet port
        neutron $NEUTRON_OPT router-interface-delete $ROUTER_ID $PRIVATE_SUBNET_ID

        # Finally delete router
        neutron $NEUTRON_OPT router-delete $ROUTER_ID
    fi
done
cat $OUTPUT_FILE

# Delete all networks of tenant
echo "* Deleting all networks of tenant-id '$TENANT_ID'"
neutron $NEUTRON_OPT net-list |  tee $OUTPUT_FILE | grep "$TENANT_ID" | while read line
do
    NETWORK_ID=$(echo $line | awk '{ print $2 }')
    NETWORK_NAME=$(echo $line | awk '{ print $4 }')

    if [[ $NETWORK_ID ]]; then

        echo "  - deleting network '$NETWORK_NAME' ($NETWORK_ID)"
        neutron $NEUTRON_OPT net-delete $NETWORK_ID
    fi
done
cat $OUTPUT_FILE

# Delete all floating ips of tenant
echo "* Deleting all floating ips of tenant-id '$TENANT_ID'"
neutron $NEUTRON_OPT floatingip-list --tenant-id "$TENANT_ID" | tee $OUTPUT_FILE | grep "$TENANT_ID" | while read line
do
    FLOATINGIP_ID=$(echo $line | awk '{ print $2 }')
    FLOATINGIP_IP=$(echo $line | awk '{ print $4 }')

    if [[ $FLOATINGIP_ID ]]; then

        echo "  - releasing floating ip '$FLOATINGIP_IP' ($FLOATINGIP_ID)"
        neutron $NEUTRON_OPT floatingip-delete $FLOATINGIP_ID
    fi
done
cat $OUTPUT_FILE

# Delete all security groups of tenant
echo "* Deleting all security groups of tenant-id '$TENANT_ID'"
neutron $NEUTRON_OPT security-group-list --tenant-id "$TENANT_ID" -c id -c name -c description -c tenant_id | tee $OUTPUT_FILE | grep "$TENANT_ID" | while read line
do
    SECURITY_GROUP_ID=$(echo $line | awk '{ print $2 }')
    SECURITY_GROUP_NAME=$(echo $line | awk '{ print $4 }')

    if [[ $SECURITY_GROUP_ID ]]; then

        echo "  - deleting security group '$SECURITY_GROUP_NAME' ($SECURITY_GROUP_ID)"
        neutron $NEUTRON_OPT security-group-delete --security-group $SECURITY_GROUP_ID
    fi
done
cat $OUTPUT_FILE

# Delete user
echo "* Deleting user '$USER'"
keystone $KEYSTONE_OPT user-delete $USER

# Delete tenant
echo "* Deleting tenant '$USER_TENANT'"
keystone $KEYSTONE_OPT tenant-delete $USER_TENANT

