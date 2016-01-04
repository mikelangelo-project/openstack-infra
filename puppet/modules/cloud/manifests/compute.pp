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
# == Class: cloud::compute
#
# Common class for compute nodes
#
# === Parameters:
#
# [*nova_db_host*]
#   (optional) Hostname or IP address to connect to nova database
#   Defaults to '127.0.0.1'
#
# [*nova_db_use_slave*]
#   (optional) Enable slave connection for nova, this assume
#   the haproxy is used and mysql loadbalanced port for read operation is 3307
#   Defaults to false
#
# [*nova_db_user*]
#   (optional) Username to connect to nova database
#   Defaults to 'nova'
#
# [*nova_db_password*]
#   (optional) Password to connect to nova database
#   Defaults to 'novapassword'
#
# [*nova_db_idle_timeout*]
#   (optional) Timeout before idle SQL connections are reaped.
#   Defaults to 5000
#
# [*rabbit_hosts*]
#   (optional) List of RabbitMQ servers. Should be an array.
#   Defaults to ['127.0.0.1:5672']
#
# [*rabbit_password*]
#   (optional) Password to connect to nova queues.
#   Defaults to 'rabbitpassword'
#
# [*ks_glance_internal_host*]
#   (optional) Internal Hostname or IP to connect to Glance API
#   Defaults to '127.0.0.1'
#
# [*ks_glance_internal_proto*]
#   (optional) Internal protocol to connect to Glance API
#   Defaults to 'http'
#
# [*glance_api_port*]
#   (optional) TCP port to connect to Glance API
#   Defaults to '9292'
#
# [*verbose*]
#   (optional) Set log output to verbose output
#   Defaults to true
#
# [*debug*]
#   (optional) Set log output to debug output
#   Defaults to true
#
# [*use_syslog*]
#   (optional) Use syslog for logging
#   Defaults to true
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines
#   Defaults to 'LOG_LOCAL0'
#
# [*neutron_endpoint*]
#   (optional) Host running auth service.
#   Defaults to '127.0.0.1'
#
# [*neutron_protocol*]
#   (optional) Protocol to connect to Neutron service.
#   Defaults to 'http'
#
# [*neutron_password*]
#   (optional) Password to connect to Neutron service.
#   Defaults to 'neutronpassword'
#
# [*neutron_region_name*]
#   (optional) Name of the Neutron Region.
#   Defaults to 'RegionOne'
#
# [*memcache_servers*]
#   (optionnal) Memcached servers used by Keystone. Should be an array.
#   Defaults to ['127.0.0.1:11211']
#
# [*availability_zone*]
#   (optional) Name of the default Nova availability zone.
#   Defaults to 'RegionOne'
#
class cloud::compute(
  $nova_db_host             = '127.0.0.1',
  $nova_db_use_slave        = false,
  $nova_db_user             = 'nova',
  $nova_db_password         = 'novapassword',
  $nova_db_idle_timeout     = 5000,
  $rabbit_hosts             = ['127.0.0.1:5672'],
  $rabbit_password          = 'rabbitpassword',
  $ks_glance_internal_host  = '127.0.0.1',
  $ks_glance_internal_proto = 'http',
  $glance_api_port          = 9292,
  $verbose                  = true,
  $debug                    = true,
  $use_syslog               = true,
  $log_facility             = 'LOG_LOCAL0',
  $neutron_endpoint         = '127.0.0.1',
  $neutron_protocol         = 'http',
  $neutron_password         = 'neutronpassword',
  $neutron_region_name      = 'RegionOne',
  $memcache_servers         = ['127.0.0.1:11211'],
  $availability_zone        = 'RegionOne',
) {

  if !defined(Resource['nova_config']) {
    resources { 'nova_config':
      purge => true;
    }
  }

  # Configure logging for nova
  class { '::nova::logging':
    use_syslog                      => $use_syslog,
    log_facility                    => $log_facility,
    verbose                         => $verbose,
    debug                           => $debug,

    logging_context_format_string   => '%(process)d: %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s',
    logging_default_format_string   => '%(process)d: %(levelname)s %(name)s [-] %(instance)s%(message)s',
    logging_debug_format_suffix     => '%(funcName)s %(pathname)s:%(lineno)d',
    logging_exception_prefix        => '%(process)d: TRACE %(name)s %(instance)s',
  }

  $encoded_user     = uriescape($nova_db_user)
  $encoded_password = uriescape($nova_db_password)

  if $nova_db_use_slave {
    $slave_connection_url = "mysql://${encoded_user}:${encoded_password}@${nova_db_host}:3307/nova?charset=utf8"
  } else {
    $slave_connection_url = undef
  }

  class { 'nova::db':
    database_connection   => "mysql://${encoded_user}:${encoded_password}@${nova_db_host}/nova?charset=utf8",
    slave_connection      => $slave_connection_url,
    database_idle_timeout => $nova_db_idle_timeout,
  }

  class { 'nova':
    rabbit_userid       => 'nova',
    rabbit_hosts        => $rabbit_hosts,
    rabbit_password     => $rabbit_password,
    glance_api_servers  => "${ks_glance_internal_proto}://${ks_glance_internal_host}:${glance_api_port}",
    memcached_servers   => $memcache_servers,
    cinder_catalog_info => 'volumev2:cinderv2:internalURL',
#    nova_shell         => '/bin/bash',
  }

  class { 'nova::network::neutron':
      neutron_admin_password => $neutron_password,
      neutron_admin_auth_url => "${neutron_protocol}://${neutron_endpoint}:35357/v2.0",
      neutron_url            => "${neutron_protocol}://${neutron_endpoint}:9696",
      neutron_region_name    => $neutron_region_name
  }

  nova_config {
    'DEFAULT/resume_guests_state_on_host_boot': value => true;
    'DEFAULT/servicegroup_driver':              value => 'mc';
    'DEFAULT/glance_num_retries':               value => '10';
  }

}
