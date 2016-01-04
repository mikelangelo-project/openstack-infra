#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Configure RBD backend for Cinder
#
#
# === Parameters
#
# [*rbd_pool*]
#   (required) Specifies the pool name for the block device driver.
#
# [*rbd_user*]
#   (required) A required parameter to configure OS init scripts and cephx.
#
# [*volume_backend_name*]
#   Allows for the volume_backend_name to be separate of $name.
#
# [*rbd_ceph_conf*]
#   (optional) Path to the ceph configuration file to use
#   Defaults to '/etc/ceph/ceph.conf'
#
# [*rbd_flatten_volume_from_snapshot*]
#   (optional) Enable flatten volumes created from snapshots.
#   Defaults to false
#
# [*rbd_secret_uuid*]
#   (optional) A required parameter to use cephx.
#   Defaults to false
#
# [*volume_tmp_dir*]
#   (optional) Location to store temporary image files if the volume
#   driver does not write them directly to the volume
#   Defaults to false
#
# [*rbd_max_clone_depth*]
#   (optional) Maximum number of nested clones that can be taken of a
#   volume before enforcing a flatten prior to next clone.
#   A value of zero disables cloning
#   Defaults to '5'
#
define cloud::volume::backend::rbd (
  $rbd_pool,
  $rbd_user,
  $rbd_key,
  $volume_backend_name              = $name,
  $rbd_ceph_conf                    = '/etc/ceph/ceph.conf',
  $rbd_flatten_volume_from_snapshot = false,
  $rbd_secret_uuid                  = false,
  $rbd_max_clone_depth              = '5',
  $qos = undef,
) {

  # Create ceph.conf on node
  include cloud::storage::rbd

  cinder::backend::rbd { $volume_backend_name:
    rbd_pool                         => $rbd_pool,
    rbd_user                         => $rbd_user,
    rbd_secret_uuid                  => $rbd_secret_uuid,
    rbd_ceph_conf                    => $rbd_ceph_conf,
    rbd_flatten_volume_from_snapshot => $rbd_flatten_volume_from_snapshot,
    rbd_max_clone_depth              => $rbd_max_clone_depth,
    volume_tmp_dir                   => '/tmp'
  }

  # If Cinder & Nova reside on the same node, we need a group
  # where nova & cinder users have read permissions.
  #
  # pete: won't happen in our deployment, so disable for now
#  ensure_resource('group', 'cephkeyring', {
#    ensure => 'present'
#  })

#  ensure_resource ('exec','add-cinder-to-group', {
#    'command' => 'usermod -a -G cephkeyring cinder',
#    'path'    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
#    'unless'  => 'groups cinder | grep cephkeyring'
#  })

  # Configure Ceph keyring
#  Ceph::Key <<| title == $rbd_user |>>

  ceph::key { "client.${rbd_user}":
    secret          => $rbd_key,
    user            => 'cinder',
    group           => 'cinder',
    keyring_path    => "/etc/ceph/ceph.client.${rbd_user}.keyring"
  }

#  concat { $rbd_ceph_conf:
#    ensure => present,
#  }

#  $clients = [$rbd_user]
#  concat::fragment { 'ceph-cinder-client-os':
#    target  => $rbd_ceph_conf,
#    order   => '95',
#    content => template('cloud/storage/ceph/ceph-client.conf.erb')
#  }


#  ensure_resource('file', "/etc/ceph/ceph.client.${rbd_user}.keyring", {
#    owner => 'root',
#    group => 'cephkeyring',
#    mode => '0440',
#    require => Ceph::Key[$rbd_user],
# })

  Concat::Fragment <<| title == 'ceph-client-os' |>>

  @cinder::type { $volume_backend_name:
    set_key   => 'volume_backend_name',
    set_value => $volume_backend_name,
    notify    => Service['cinder-volume']
  }

  if $qos and has_key($qos, 'frontend') {
    Cinder::Type[$volume_backend_name] ->
    cloud::volume::qos::create { "qos_${volume_backend_name}":
      properties => $qos['frontend'],
      consumer => 'front-end',
    }->

    #associate with volume type
    cloud::volume::qos::associate { "association_qos_${volume_backend_name}": 
      qos_name => "qos_${volume_backend_name}",
      volume_type => $volume_backend_name
    }
  }
}
