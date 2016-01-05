#!/bin/bash

mkfs.ext4 -F -v /dev/sdb
mkdir -p /storage

# Add fstab entry
cat >> /etc/fstab <<EOF

# Local storage for NFS
/dev/sdb	/storage	ext4	defaults	0 0
EOF

mount /storage

mkdir -p /storage/instances
mkdir -p /storage/volumes
mkdir -p /storage/images
mkdir -p /storage/image-cache
