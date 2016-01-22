#!/bin/bash

# Get auth data
source /root/openrc

DEBUG=false
OUTPUT_FILE="/tmp/output.txt"

USER="test1"
USER_PASSWORD="test"
USER_EMAIL="maik.srba@gwdg.de"
USER_TENANT=$USER

USER_NETWORK_NAME_PREFIX="private"
USER_NETWORK_CIDR="10.254.1.0/24"
USER_NETWORK_DNS_SERVER="134.76.10.46 134.76.33.21"
USER_ROUTER_NAME_PREFIX="router"

PUBLIC_NETWORK_NAME="public"

# neutron quotas
NEUTRON_QUOTA_FLOATING_IP=3
NEUTRON_QUOTA_NETWORK=1
NEUTRON_QUOTA_PORT=20
NEUTRON_QUOTA_ROUTER=1
NEUTRON_QUOTA_SUBNET=1

# Cinder quotas
CINDER_QUOTA_VOLUMES=3
CINDER_QUOTA_SNAPSHOTS=3
CINDER_QUOTA_GIGABYTES=$((CINDER_QUOTA_VOLUMES * 50))

# Nova quotas
NOVA_QUOTA_INSTANCES=3
NOVA_QUOTA_CORES=$(($NOVA_QUOTA_INSTANCES * 4))
NOVA_QUOTA_RAM=$((NOVA_QUOTA_INSTANCES * 8 * 1024))
NOVA_QUOTA_METADATA_ITEMS=128
NOVA_QUOTA_INJECTED_FILE_CONTENT_BYTES=10240
NOVA_QUOTA_KEY_PAIRS=10
NOVA_QUOTA_SECURITY_GROUP_RULES=50
NOVA_QUOTA_INJECTED_FILES=5
NOVA_QUOTA_FIXED_IPS=-1                             # Maybe unnecessary (-> neutron)
NOVA_QUOTA_FLOATING_IPS=$NEUTRON_QUOTA_FLOATING_IP  # Maybe unnecessary (-> neutron)
NOVA_QUOTA_INJECTED_FILE_PATH_BYTES=255
NOVA_QUOTA_SECURITY_GROUPS=10

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

echo "* Creating new tenant '$USER_TENANT'"
TENANT_ID=$(get_id keystone tenant-create --name $USER_TENANT)
cat $OUTPUT_FILE

echo "* Creating user '$USER'"
USER_ID=$(get_id keystone $KEYSTONE_OPT user-create --name=$USER --pass=$USER_PASSWORD --tenant-id $TENANT_ID --email=$USER_EMAIL)
cat $OUTPUT_FILE

ROLE_MEMBER_ID=$(keystone $KEYSTONE_OPT role-list   | tee $OUTPUT_FILE  | grep " Member "   | awk '{ print $2 }')
cat $OUTPUT_FILE

ROLE_ADMIN_ID=$(keystone $KEYSTONE_OPT role-list    | tee $OUTPUT_FILE  | grep " admin "    | awk '{ print $2 }')
cat $OUTPUT_FILE

echo "* Assigning 'Member' role to user '$USER' in tenant '$USER_TENANT'"
USER_MEMBER_ROLE_ID=($get_id keystone $KEYSTONE_OPT user-role-add --tenant-id $TENANT_ID --user-id $USER_ID --role-id $ROLE_MEMBER_ID)
#cat $OUTPUT_FILE

# Does not work. Probably due to some token invalidation effect. Also not really necessary / should not be done!
#echo "* Assigning 'admin' role to user 'admin'  in tenant '$USER_TENANT'"
#ADMIN_USER_ID=$(keystone $KEYSTONE_OPT user-list    | tee $OUTPUT_FILE  | grep " admin "    | awk '{ print $2 }')
#cat $OUTPUT_FILE
#ADMIN_MEMBER_ROLE_ID=($get_id keystone $KEYSTONE_OPT user-role-add --tenant-id $TENANT_ID --user-id $ADMIN_USER_ID --role-id $ROLE_ADMIN_ID)
#cat $OUTPUT_FILE

# Create private network for tenant
USER_NETWORK_NAME="$USER_NETWORK_NAME_PREFIX-$TENANT_ID"
echo "* Creating private L2 network '$USER_NETWORK_NAME' for user"
USER_NETWORK_ID=$(get_id neutron $NEUTRON_OPT net-create --tenant-id $TENANT_ID $USER_NETWORK_NAME)
cat $OUTPUT_FILE

# Create private subnet for tenant
echo "* Creating private L3 ip space '$USER_NETWORK_CIDR' for user"
USER_SUBNET_ID=$(get_id neutron $NEUTRON_OPT subnet-create --tenant-id $TENANT_ID $USER_NETWORK_NAME $USER_NETWORK_CIDR --dns_nameservers list=true $USER_NETWORK_DNS_SERVER)
cat $OUTPUT_FILE

# Create private router for tenant
USER_ROUTER_NAME="$USER_ROUTER_NAME_PREFIX-$TENANT_ID"
echo "* Creating private router '$USER_ROUTER_NAME' for user"
USER_ROUTER_ID=$(get_id neutron $NEUTRON_OPT router-create --tenant-id $TENANT_ID $USER_ROUTER_NAME)
cat $OUTPUT_FILE

# Add link to private tenant subnet
echo "* Attaching private user L2 network to private user router"
neutron $NEUTRON_OPT router-interface-add $USER_ROUTER_ID $USER_SUBNET_ID

# Add link to subnet with public floating ips
echo "* Attaching public network as gateway to private user router"
PUBLIC_NETWORK_ID=$(neutron $NEUTRON_OPT net-list -- --router:external=True | tee $OUTPUT_FILE   | grep " $PUBLIC_NETWORK_NAME " | awk '{ print $2 }')
cat $OUTPUT_FILE
neutron $NEUTRON_OPT router-gateway-set $USER_ROUTER_ID $PUBLIC_NETWORK_ID

# Allocate floating IPs to project
echo "* Allocating [$NEUTRON_QUOTA_FLOATING_IP] floating ips to tenant"
for (( i=1; i<=$NEUTRON_QUOTA_FLOATING_IP; i++ ))
do
    neutron $NEUTRON_OPT floatingip-create --tenant-id $TENANT_ID $PUBLIC_NETWORK_NAME
done

# Set neutron quotas
echo "* Setting neutron quotas"
neutron $NEUTRON_OPT quota-update --tenant_id $TENANT_ID    --network       $NEUTRON_QUOTA_NETWORK      \
                                                            --subnet        $NEUTRON_QUOTA_SUBNET       \
                                                            --port          $NEUTRON_QUOTA_PORT --      \
                                                            --floatingip    $NEUTRON_QUOTA_FLOATING_IP  \
                                                            --router        $NEUTRON_QUOTA_ROUTER

neutron $NEUTRON_OPT quota-show --tenant_id $TENANT_ID

# Set nova quotas
echo "* Setting nova quotas"
nova $NOVA_OPT quota-update $TENANT_ID      --instances                     $NOVA_QUOTA_INSTANCES                   \
                                            --cores                         $NOVA_QUOTA_CORES                       \
                                            --ram                           $NOVA_QUOTA_RAM                         \
                                            --floating-ips                  $NOVA_QUOTA_FLOATING_IPS                \
                                            --fixed-ips                     $NOVA_QUOTA_FIXED_IPS                   \
                                            --metadata-items                $NOVA_QUOTA_METADATA_ITEMS              \
                                            --injected-files                $NOVA_QUOTA_INJECTED_FILES              \
                                            --injected-file-content-bytes   $NOVA_QUOTA_INJECTED_FILE_CONTENT_BYTES \
                                            --injected-file-path-bytes      $NOVA_QUOTA_INJECTED_FILE_PATH_BYTES    \
                                            --key-pairs                     $NOVA_QUOTA_KEY_PAIRS                   \
                                            --security-groups               $NOVA_QUOTA_SECURITY_GROUPS             \
                                            --security-group-rules          $NOVA_QUOTA_SECURITY_GROUP_RULES

nova $NOVA_OPT quota-show --tenant $TENANT_ID

# Set cinder quotas
echo "* Setting cinder quotas"
cinder $CINDER_OPT quota-update $TENANT_ID  --volumes $CINDER_QUOTA_VOLUMES     \
                                            --snapshots $CINDER_QUOTA_SNAPSHOTS \
                                            --gigabytes $CINDER_QUOTA_GIGABYTES

cinder $CINDER_OPT quota-show $TENANT_ID

# Switch to user tenant for auth
unset OS_SERVICE_TOKEN
unset OS_SERVICE_ENDPOINT
export OS_TENANT_NAME=$USER_TENANT
export OS_USERNAME=$USER
export OS_PASSWORD=$USER_PASSWORD

# Add rules for ssh, icmp to default security group
echo "* Adding default security group rules (ssh, icmp)"
neutron $NEUTRON_OPT security-group-rule-create --remote-ip-prefix "0.0.0.0/0" --tenant-id $TENANT_ID --protocol icmp --direction ingress default
neutron $NEUTRON_OPT security-group-rule-create --remote-ip-prefix "0.0.0.0/0" --tenant-id $TENANT_ID --protocol tcp --port-range-min 22 --port-range-max 22 --direction ingress default

neutron $NEUTRON_OPT security-group-rule-list 

