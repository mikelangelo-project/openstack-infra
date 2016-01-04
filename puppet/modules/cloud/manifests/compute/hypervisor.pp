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
# == Class: cloud::compute::hypervisor
#
# Hypervisor Compute node
#
# === Parameters:
#
# [*server_proxyclient_address*]
#   (optional) The IP address of the server running the console proxy client
#   Defaults to '127.0.0.1'
#
# [*libvirt_virt_type*]
#   (optional) Libvirt domain type. Options are: kvm, lxc, qemu, uml, xen
#   Replaces libvirt_type
#   Defaults to 'kvm'
#
# [*nova_ssh_public_key*]
#   (optional) Install public key in .ssh/authorized_keys for the 'nova' user.
#   Note: this parameter use the 'content' provider of Puppet, in consequence
#   you must provide the entire ssh public key in this parameter.
#   Defaults to undef
#
# [*nova_ssh_private_key*]
#   (optional) Install private key into .ssh/id_rsa.
#   Note: this parameter use the 'content' provider of Puppet, in consequence
#   you must provide the entire ssh privatekey in this parameter.
#   Defaults to undef
#
# [*console*]
#   (optional) Nova's console type (spice or novnc)
#   Defaults to 'novnc'
#
# [*novnc_port*]
#   (optional) TCP port to connect to Nova vncproxy service.
#   Defaults to '6080'
#
# [*spice_port*]
#   (optional) TCP port to connect to Nova spicehtmlproxy service.
#   Defaults to '6082'
#
# [*cinder_rbd_user*]
#   (optional) The RADOS client name for accessing rbd volumes.
#   Defaults to 'cinder'
#
# [*nova_rbd_pool*]
#   (optional) The RADOS pool in which rbd volumes are stored.
#   Defaults to 'vms'
#
# [*nova_rbd_secret_uuid*]
#   (optional) The libvirt uuid of the secret for the cinder_rbd_user.
#   Defaults to undef
#
# [*vm_rbd*]
#   (optional) Enable or not ceph capabilities on compute node to store
#   nova instances on ceph storage.
#   Default to false.
#
# [*volume_rbd*]
#   (optional) Enable or not ceph capabilities on compute node to attach
#   cinder volumes backend by ceph on nova instances.
#   Default to false.
#
# [*manage_tso*]
#   (optional) Allow to manage or not TSO issue.
#   Default to true.
#
# [*nfs_enabled*]
#   (optional) Store (or not) instances on a NFS share.
#   Defaults to false
#
# [*nfs_server*]
#   (optional) NFS device to mount
#   Example: 'nfs.example.com:/vol1'
#   Required when nfs_enabled is at true.
#   Defaults to false
#
# [*nfs_options*]
#   (optional) NFS mount options
#   Example: 'nfsvers=3,noacl'
#   Defaults to 'defaults'
#
# [*filesystem_store_datadir*]
#   (optional) Full path of data directory to store the instances.
#   Don't modify this parameter if you don't know what you do.
#   You may have side effects (SElinux for example).
#   Defaults to '/var/lib/nova/instances'
#
# [*nova_shell*]
#   (optional) Full path of shell to run for nova user.
#   To disable live migration & resize, set it to '/bin/nologin' or false.
#   Otherwise, set the value to '/bin/bash'.
#   Need to be a valid shell path.
#   Defaults to false
#
# [*include_vswitch*]
#   (optional) Should the class cloud::network::vswitch should be included.
#   Defaults to true
#
# [*firewall_settings*]
#   (optional) Allow to add custom parameters to firewall rules
#   Should be an hash.
#   Default to {}
#
class cloud::compute::hypervisor(
  $server_proxyclient_address = '127.0.0.1',
  $libvirt_virt_type          = 'kvm',
  $nova_ssh_private_key       = undef,
  $nova_ssh_public_key        = undef,
  $console                    = 'novnc',
  $novnc_port                 = '6080',
  $spice_port                 = '6082',
  $manage_tso                 = true,
  $nova_shell                 = false,
  $firewall_settings          = {},
  $include_vswitch            = true,

  # Ceph storage backend
  $ceph_fsid                  = undef,
  $cinder_rbd_user            = 'cinder',
  $cinder_rbd_key             = undef,
  $nova_rbd_pool              = 'vms',
  $nova_rbd_secret_uuid       = undef,
  $vm_rbd                     = false,
  $volume_rbd                 = false,

  # NFS storage backend
  $nfs_enabled                = false,
  $nfs_server                 = false,
  $nfs_share                  = undef,
  $nfs_options                = 'defaults',
  $filesystem_store_datadir   = '/var/lib/nova/instances',
) inherits cloud::params {

  include 'cloud::compute'
  include 'cloud::params'
  include 'cloud::telemetry'
  include 'cloud::network'

  if $include_vswitch {
    include 'cloud::network::vswitch'
  }

  if $libvirt_virt_type == 'kvm' and ! $::vtx {
    fail('libvirt_virt_type is set to KVM and VTX seems to be disabled on this node.')
  }

  if $nfs_enabled {
    if ! $vm_rbd {
      # There is no NFS backend in Nova.
      # We mount the NFS share in filesystem_store_datadir to fake the
      # backend.

      if $nfs_server {

        # FIXME (Piotr): Use the nfs module to mount the necessary nfs shares
        include ::nfs::client

        nfs::client::mount { '/var/lib/nova/instances':

          mount     => '/var/lib/nova/instances',

          server    => $nfs_server,
          share     => "${nfs_share}/instances",
          options   => $nfs_options,

          owner     => 'nova',
          group     => 'nova',

          require   => User['nova'],
        }

        nova_config { 'DEFAULT/instances_path': value => $filesystem_store_datadir; }

        # Not using /var/lib/nova/instances may cause side effects.
        if $filesystem_store_datadir != '/var/lib/nova/instances' {
          warning('filesystem_store_datadir is not /var/lib/nova/instances so you may have side effects (SElinux, etc)')
        }
      } else {
        fail('When running NFS backend, you need to provide nfs_server parameter.')
      }
    } else {
      fail('When running NFS backend, vm_rbd parameter cannot be set to true.')
    }
  }

  file{ '/var/lib/nova/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'nova',
    group   => 'nova',
    require => Class['nova']
  } ->
  file{ '/var/lib/nova/.ssh/id_rsa':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => $nova_ssh_private_key
  } ->
  file{ '/var/lib/nova/.ssh/authorized_keys':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => $nova_ssh_public_key
  } ->
  file{ '/var/lib/nova/.ssh/config':
    ensure  => present,
    mode    => '0600',
    owner   => 'nova',
    group   => 'nova',
    content => "
Host *
    StrictHostKeyChecking no
"
  }

  if $nova_shell {
    ensure_resource ('user', 'nova', {
      'ensure'     => 'present',
      'system'     => true,
      'home'       => '/var/lib/nova',
      'managehome' => false,
      'shell'      => $nova_shell,
    })
  }

  case $console {
    'spice': {
      $vnc_enabled = false
      class { 'nova::compute::spice':
        server_listen              => '0.0.0.0',
        server_proxyclient_address => $server_proxyclient_address,
        proxy_host                 => $ks_console_public_host,
        proxy_protocol             => $ks_console_public_proto,
        proxy_port                 => $spice_port,
      }
    }
    'novnc': {
      $vnc_enabled = true
    }
    default: {
      fail("unsupported console type ${console}")
    }
  }
  class { 'nova::compute':
    enabled                       => true,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $server_proxyclient_address,

    # Set directly in nova modul through hiera (nova::vncproxy::common::vncproxy_base_url)
#    vncproxy_host                 => $ks_console_public_host,
#    vncproxy_protocol             => $ks_console_public_proto,
#    vncproxy_port                 => $novnc_port,

    virtio_nic                    => false,
    neutron_enabled               => true,
    default_availability_zone     => $::cloud::compute::availability_zone,
  }

  if $::osfamily == 'RedHat' {
    file { '/etc/libvirt/qemu.conf':
      ensure => file,
      source => 'puppet:///modules/cloud/qemu/qemu.conf',
      owner  => root,
      group  => root,
      mode   => '0644',
      notify => Service['libvirtd']
    }
    if $vm_rbd and ($::operatingsystemmajrelease < 7) {
      fail("RBD image backend in Nova is not supported in RHEL ${::operatingsystemmajrelease}.")
    }
  }

  # Disabling TSO/GSO/GRO
  if $manage_tso {
    if $::osfamily == 'Debian' {
      ensure_resource ('exec','enable-tso-script', {
        'command' => '/usr/sbin/update-rc.d disable-tso defaults',
        'unless'  => '/bin/ls /etc/rc*.d | /bin/grep disable-tso',
        'onlyif'  => '/usr/bin/test -f /etc/init.d/disable-tso'
      })
    } elsif $::osfamily == 'RedHat' {
      ensure_resource ('exec','enable-tso-script', {
        'command' => '/usr/sbin/chkconfig disable-tso on',
        'unless'  => '/bin/ls /etc/rc*.d | /bin/grep disable-tso',
        'onlyif'  => '/usr/bin/test -f /etc/init.d/disable-tso'
      })
    }
    ensure_resource ('exec','start-tso-script', {
      'command' => '/etc/init.d/disable-tso start',
      'unless'  => '/usr/bin/test -f /var/run/disable-tso.pid',
      'onlyif'  => '/usr/bin/test -f /etc/init.d/disable-tso'
    })
  }

  if $::osfamily == 'Debian' {
    service { 'dbus':
      ensure => running,
      enable => true,
      before => Class['nova::compute::libvirt'],
    }
  }

  Service<| title == 'dbus' |> { enable => true }

  Service<| title == 'libvirt-bin' |> { enable => true }

  class { 'nova::compute::neutron': }

  if $vm_rbd or $volume_rbd {

    include 'cloud::storage::rbd'

    $libvirt_disk_cachemodes_real = ['network=writeback']

    # when nova uses ceph for instances storage
    if $vm_rbd {
      class { 'nova::compute::rbd':
        libvirt_rbd_user        => $cinder_rbd_user,
        libvirt_images_rbd_pool => $nova_rbd_pool
      }
    } else {
      # when nova only needs to attach ceph volumes to instances
      nova_config {
        'libvirt/rbd_user': value => $cinder_rbd_user;
      }
    }
    # we don't want puppet-nova manages keyring
    nova_config {
      'libvirt/rbd_secret_uuid': value => $nova_rbd_secret_uuid;
    }

    # Create key for rbd user
    ceph::key { "client.${cinder_rbd_user}":
      secret          => $cinder_rbd_key,
      user            => 'nova',
      group           => 'nova',
      keyring_path    => "/etc/ceph/ceph.client.${cinder_rbd_user}.keyring"
    }

    file { '/etc/ceph/secret.xml':
      content => template('cloud/storage/ceph/secret-compute.xml.erb'),
      tag     => 'ceph_compute_secret_file',
    }

    if $::osfamily == 'RedHat' {
      $libvirt_package_name = 'libvirt'
    } else {
      $libvirt_package_name = 'libvirt-bin'
    }

    Exec {
      path => '/bin:/sbin:/usr/bin:/usr/sbin'
    }

    exec { 'get_or_set_virsh_secret':
      command => 'virsh secret-define --file /etc/ceph/secret.xml',
      unless  => "virsh secret-list | tail -n +3 | cut -f1 -d' ' | grep -sq ${ceph_fsid}",
      tag     => 'ceph_compute_get_secret',
      require => [Package[$libvirt_package_name], File['/etc/ceph/secret.xml']],
      notify  => Exec['set_secret_value_virsh'],
    }

    exec { 'set_secret_value_virsh':
      command     => "virsh secret-set-value --secret ${ceph_fsid} --base64 ${cinder_rbd_key}",
      tag         => 'ceph_compute_set_secret',
      refreshonly =>  true,
    } ~> Service['nova-compute']

#    File <<| tag == 'ceph_compute_secret_file' |>>
#    Exec <<| tag == 'get_or_set_virsh_secret' |>>

    # After setting virsh key, we need to restart nova-compute
    # otherwise nova will fail to connect to RADOS.
#    Exec <<| tag == 'set_secret_value_virsh' |>> ~> Service['nova-compute']

    # If Cinder & Nova reside on the same node, we need a group
    # where nova & cinder users have read permissions.
    #
    # pete: not relevant for our deplyoment
#    ensure_resource('group', 'cephkeyring', {
#      ensure => 'present'
#    })

#    ensure_resource ('exec','add-nova-to-group', {
#      'command' => 'usermod -a -G cephkeyring nova',
#      'path'    => ['/usr/sbin', '/usr/bin', '/bin', '/sbin'],
#      'unless'  => 'groups nova | grep cephkeyring'
#    })

    # Configure Ceph keyring
#    Ceph::Key <<| title == $cinder_rbd_user |>>
#    ensure_resource(
#      'file',
#      "/etc/ceph/ceph.client.${cinder_rbd_user}.keyring", {
#        owner   => 'root',
#        group   => 'cephkeyring',
#        mode    => '0440',
#        require => Ceph::Key[$cinder_rbd_user],
#        notify  => Service['nova-compute'],
#      }
#    )

#    Concat::Fragment <<| title == 'ceph-client-os' |>>
  } else {
    $libvirt_disk_cachemodes_real = []
  }

  class { 'nova::compute::libvirt':
    libvirt_virt_type        => $libvirt_virt_type,
    # Needed to support migration but we still use Spice:
    vncserver_listen         => '0.0.0.0',
    migration_support        => true,
    libvirt_disk_cachemodes  => $libvirt_disk_cachemodes_real,
    libvirt_service_name     => $::cloud::params::libvirt_service_name,
    libvirt_inject_key       => false,
    libvirt_inject_partition => '-2',
  }

  # Extra config for nova-compute
  nova_config {
    'libvirt/live_migration_flag':  value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST';
    'libvirt/block_migration_flag': value => 'VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_NON_SHARED_INC';

    # Use interal API when communicating with cinder
#    'cinder/catalog_info':          value => 'volume:cinder:internalURL';
  }

  class { 'ceilometer::agent::compute': }

  if $::cloud::manage_firewall {
    cloud::firewall::rule{ '100 allow instances console access':
      port   => '5900-5999',
      extras => $firewall_settings,
    }
    cloud::firewall::rule{ '100 allow instances migration access':
      port   => ['16509', '49152-49215'],
      extras => $firewall_settings,
    }
  }

}
