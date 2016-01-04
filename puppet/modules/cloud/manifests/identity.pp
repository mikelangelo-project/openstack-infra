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
# == Class: cloud::identity
#
# Install Identity Server (Keystone)
#
# === Parameters:
#
# [*identity_roles_addons*]
#   (optional) Extra keystone roles to create
#   Defaults to ['SwiftOperator', 'ResellerAdmin']
#
# [*keystone_db_host*]
#   (optional) Hostname or IP address to connect to keystone database
#   Defaults to '127.0.0.1'
#
# [*keystone_db_user*]
#   (optional) Username to connect to keystone database
#   Defaults to 'keystone'
#
# [*keystone_db_password*]
#   (optional) Password to connect to keystone database
#   Defaults to 'keystonepassword'
#
# [*keystone_db_idle_timeout*]
#   (optional) Timeout before idle SQL connections are reaped.
#   Defaults to 5000
#
# [*memcache_servers*]
#   (optionnal) Memcached servers used by Keystone. Should be an array.
#   Defaults to ['127.0.0.1:11211']
#
# [*ks_admin_email*]
#   (optional) Email address of admin user in Keystone
#   Defaults to 'no-reply@keystone.openstack'
#
# [*ks_admin_password*]
#   (optional) Password of admin user in Keystone
#   Defaults to 'adminpassword'
#
# [*ks_admin_tenant*]
#   (optional) Admin tenant name in Keystone
#   Defaults to 'admin'
#
# [*ks_admin_token*]
#   (required) Admin token used by Keystone.
#
# [*trove_password*]
#   (optional) Password used by Trove to connect to Keystone API
#   Defaults to 'trovepassword'
#
# [*ceilometer_password*]
#   (optional) Password used by Ceilometer to connect to Keystone API
#   Defaults to 'ceilometerpassword'
#
# [*swift_password*]
#   (optional) Password used by Swift to connect to Keystone API
#   Defaults to 'swiftpassword'
#
# [*nova_password*]
#   (optional) Password used by Nova to connect to Keystone API
#   Defaults to 'novapassword'
#
# [*neutron_password*]
#   (optional) Password used by Neutron to connect to Keystone API
#   Defaults to 'neutronpassword'
#
# [*heat_password*]
#   (optional) Password used by Heat to connect to Keystone API
#   Defaults to 'heatpassword'
#
# [*glance_password*]
#   (optional) Password used by Glance to connect to Keystone API
#   Defaults to 'glancepassword'
#
# [*cinder_password*]
#   (optional) Password used by Cinder to connect to Keystone API
#   Defaults to 'cinderpassword'
#
# [*ks_swift_dispersion_password*]
#   (optional) Password of the dispersion tenant, used for swift-dispersion-report
#   and swift-dispersion-populate tools.
#   Defaults to 'dispersion'
#
# [*api_eth*]
#   (optional) Which interface we bind the Keystone server.
#   Defaults to '127.0.0.1'
#
# [*region*]
#   (optional) OpenStack Region Name
#   Defaults to 'RegionOne'
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
# [*token_driver*]
#   (optional) Driver to store tokens
#   Defaults to 'keystone.token.persistence.backends.sql.Token'
#
# [*token_expiration*]
#   (optional) Amount of time a token should remain valid (in seconds)
#   Defaults to '3600' (1 hour)
#
# [*cinder_enabled*]
#   (optional) Enable or not Cinder (Block Storage Service)
#   Defaults to true
#
# [*trove_enabled*]
#   (optional) Enable or not Trove (Database as a Service)
#   Experimental feature.
#   Defaults to false
#
# [*swift_enabled*]
#   (optional) Enable or not OpenStack Swift (Stockage as a Service)
#   Defaults to true
#
# [*ks_token_expiration*]
#   (optional) Amount of time a token should remain valid (seconds).
#   Defaults to 3600 (1 hour).
#
# [*firewall_settings*]
#   (optional) Allow to add custom parameters to firewall rules
#   Should be an hash.
#   Default to {}
#
# [*keystone_master_name*]
#   Hostname of the keystone master node from which ssl certs are copied (needed 
#   for HA).
#
class cloud::identity (
  $swift_enabled                = true,
  $cinder_enabled               = true,
  $trove_enabled                = false,
  $identity_roles_addons        = ['SwiftOperator', 'ResellerAdmin'],
  $keystone_db_host             = '127.0.0.1',
  $keystone_db_user             = 'keystone',
  $keystone_db_password         = 'keystonepassword',
  $keystone_db_idle_timeout     = 5000,
  $memcache_servers             = ['127.0.0.1:11211'],
  $ks_admin_email               = 'no-reply@keystone.openstack',
  $ks_admin_password            = 'adminpassword',
  $ks_admin_tenant              = 'admin',
  $ks_admin_token               = undef,

  $ceilometer_public_url        = undef,
  $ceilometer_internal_url      = undef,
  $ceilometer_admin_url         = undef,

  $ceilometer_password          = 'ceilometerpassword',

  $cinder_v1_public_url         = undef,
  $cinder_v1_internal_url       = undef,
  $cinder_v1_admin_url          = undef,

  $cinder_v2_public_url         = undef,
  $cinder_v2_internal_url       = undef,
  $cinder_v2_admin_url          = undef,

  $cinder_password              = 'cinderpassword',

  $glance_public_url            = undef,
  $glance_internal_url          = undef,
  $glance_admin_url             = undef,

  $glance_password              = 'glancepassword',

  $heat_public_url              = undef,
  $heat_internal_url            = undef,
  $heat_admin_url               = undef,

  $heat_cfn_public_url          = undef,
  $heat_cfn_internal_url        = undef,
  $heat_cfn_admin_url           = undef,

  $heat_password                = 'heatpassword',

  $keystone_public_url          = undef,
  $keystone_internal_url        = undef,
  $keystone_admin_url           = undef,

  $ks_keystone_public_port      = undef,
  $ks_keystone_admin_port       = undef,
  $ssh_port                     = hiera('cloud::global::ssh_port'),

  $neutron_public_url           = undef,
  $neutron_internal_url         = undef,
  $neutron_admin_url            = undef,

  $neutron_password             = 'neutronpassword',

  $nova_v2_public_url           = undef,
  $nova_v2_internal_url         = undef,
  $nova_v2_admin_url            = undef,

  $nova_v3_public_url           = undef,
  $nova_v3_internal_url         = undef,
  $nova_v3_admin_url            = undef,

  $nova_ec2_public_url          = undef,
  $nova_ec2_internal_url        = undef,
  $nova_ec2_admin_url           = undef,

  $nova_password                = 'novapassword',

  $swift_public_url             = undef,
  $swift_internal_url           = undef,
  $swift_admin_url              = undef,

  $ks_swift_dispersion_password = 'dispersion',
  $swift_password               = 'swiftpassword',

  $trove_public_url             = undef,
  $trove_internal_url           = undef,
  $trove_admin_url              = undef,

  $trove_password               = 'trovepassword',

  $api_eth                      = '127.0.0.1',
  $region                       = 'RegionOne',
  $verbose                      = true,
  $debug                        = true,
  $log_facility                 = 'LOG_LOCAL0',
  $use_syslog                   = true,
  $ks_token_expiration          = 3600,
  $token_driver                 = 'keystone.token.persistence.backends.sql.Token',
  $firewall_settings            = {},

  # New stuff
  $keystone_master_name         = undef,
  $use_ldap                     = false,
){

  $encoded_user     = uriescape($keystone_db_user)
  $encoded_password = uriescape($keystone_db_password)

  include 'mysql::client'

  # Configure logging for cinder
  class { '::keystone::logging':
    use_syslog                      => $use_syslog,
    log_facility                    => $log_facility,
    verbose                         => $verbose,
    debug                           => $debug,

    logging_context_format_string   => '%(process)d: %(levelname)s %(name)s [%(request_id)s %(user_identity)s] %(instance)s%(message)s',
    logging_default_format_string   => '%(process)d: %(levelname)s %(name)s [-] %(instance)s%(message)s',
    logging_debug_format_suffix     => '%(funcName)s %(pathname)s:%(lineno)d',
    logging_exception_prefix        => '%(process)d: TRACE %(name)s %(instance)s',
  }

#
# Configure Keystone:
#
# Commented out vars are set directly from hiera
#
  class { 'keystone':
    enabled               => true,
    admin_token           => $ks_admin_token,
#    compute_port          => $::cloud::global::api::ports::nova,
    database_idle_timeout => $keystone_db_idle_timeout,
    database_connection   => "mysql://${encoded_user}:${encoded_password}@${keystone_db_host}/keystone?charset=utf8",
    token_provider        => 'keystone.token.providers.uuid.Provider',
    public_bind_host      => $api_eth,
    admin_bind_host       => $api_eth,
#    public_port           => $ks_keystone_public_port,
#    admin_port            => $ks_keystone_admin_port,
    token_driver          => $token_driver,
    token_expiration      => $ks_token_expiration,
    admin_endpoint        => $keystone_admin_url,
    public_endpoint       => $keystone_public_url,
  }

  keystone_config {
    'ec2/driver':       value => 'keystone.contrib.ec2.backends.sql.Ec2';
  }

  # Keystone LDAP

  if $use_ldap {
    class { 'keystone::ldap':
      url                   => "ldap://ldap.dev.cloud.gwdg.de",
      user                  => 'cn=admin,dc=computecloud,dc=gwdg,dc=de',
      password              => 'OLigt,uwhF!',
      suffix                => 'dc=computecloud,dc=gwdg,dc=de',
      user_tree_dn          => 'ou=Users,dc=computecloud,dc=gwdg,dc=de', 
#      tenant_tree_dn       => 'ou=Groups,dc=computecloud,dc=gwdg,dc=de', 
      project_tree_dn       => 'ou=Groups,dc=computecloud,dc=gwdg,dc=de', 
      project_objectclass   => 'groupOfNames',

      role_tree_dn          => 'ou=Roles,dc=computecloud,dc=gwdg,dc=de',
      identity_driver       => 'keystone.identity.backends.ldap.Identity',
#      assignment_driver    => 'keystone.assignment.backends.ldap.Assignment',
    
      use_dumb_member           => true,
      user_id_attribute         => 'uid',
      user_name_attribute       => 'cn',
      user_mail_attribute       => 'mail',
      user_enabled_attribute    => 'sn',
#      user_attribute_ignore    => 'tenantId,tenants',
#      user_enabled_emulation   => false,
#      tenant_member_attribute  => 'member',
#      tenant_desc_attribute    => 'o',
#      tenant_enabled_attribute => 'description',
#      tenant_enabled_emulation => false,
      project_member_attribute  => 'member',
      project_desc_attribute    => 'o',
      project_enabled_attribute => 'description',
      project_enabled_emulation => false,
#      role_name_attribute      => 'cn',
#      role_id_attribute        => 'cn',
    }
  }

# Keystone Endpoints + Users

  class { 'keystone::roles::admin':

    email        => $ks_admin_email,
    password     => $ks_admin_password,
    admin_tenant => $ks_admin_tenant,
  }

  keystone_role { $identity_roles_addons: ensure => present }

  class {'keystone::endpoint':

    public_url   => $keystone_public_url,
    internal_url => $keystone_internal_url,
    admin_url    => $keystone_admin_url,

    region       => $region,
  }

  # TODO(EmilienM) Disable WSGI - bug #98
  #include 'apache'
  # class {'keystone::wsgi::apache':
  #   servername  => $::fqdn,
  #   admin_port  => $ks_keystone_admin_port,
  #   public_port => $ks_keystone_public_port,
  #   # TODO(EmilienM) not sure workers is useful when using WSGI backend
  #   workers     => $::processorcount,
  #   ssl         => false
  # }

  if $swift_enabled {
    class {'swift::keystone::auth':

      public_url        => $swift_public_url,
      internal_url      => $swift_internal_url,
      admin_url         => $swift_admin_url,

      password          => $swift_password,
      region            => $region
    }

    class {'swift::keystone::dispersion':
      auth_pass         => $ks_swift_dispersion_password
    }
  }

  # For keystone HA deployment all certs in /etc/keystone/ssl need to be copied from master node to slave node(s)  
  if $::hostname == $keystone_master_name {

    # Install ssh key for access from secondary keystone nodes
    ssh_authorized_key { 'keystone@controller':
      user      => 'keystone',
      type      => 'ssh-rsa',
#      key       => template('cloud/ssh/id_rsa.pub'),
      key       => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQC9JY0WdPrv9pF7mVZZ7mHPN9HnG+Cm/og0TcddFe1uV6/5wRsUPPb6fYpKNX4+sAuhGJ/hg70X08nLWbdlv6WKyYWQoIwOgP1K4VxFUOuu1aJsyL0iRcPXGaO/xXPcXLcqmhI5ORHPlohJAAp5veM3UsJbeBf14rFYXCATH9YGAhjTr1oP5GkPaeB7cEhjQKGyoGS7lorpbNjdmZ17vZX6Geklm0BtqZQgOvQquvS4L10B90PyhXzCVx/wvzd7PtWj7HTd1s5zF5+vzt1fhbOX5fIwCp2TtSeJ0Ht/gzLx+ninQxxPjVWnFhiZEfi7h7jdisQto5Mt8wxXmwY4Ie3r',
      require   => User['keystone'],
    }

    # Restrict keystone account to just scp
    package { 'rssh': }

    exec { 'keystone-change-shell-to-rssh':
      command   => "/usr/bin/chsh -s /usr/bin/rssh keystone",
      require   => [ Package['rssh'], User['keystone'] ],
    }

    exec { 'enable-rssh-scp': 
      command   => "/bin/sed -i 's/#allowscp/allowscp/g' /etc/rssh.conf",
      require   => Package['rssh'],
    }

  } else {

    file { '/var/lib/keystone/.ssh':
      ensure  => directory,
      mode    => '0700',
      owner   => 'keystone',
      group   => 'keystone',
      require => Package['keystone'],
    }

    # Deploy private ssh key
    file { '/var/lib/keystone/.ssh/id_rsa':
      ensure  => present,
      mode    => '0600',
      owner   => 'keystone',
      group   => 'keystone',
      content => template('cloud/ssh/id_rsa'),
      require => File['/var/lib/keystone/.ssh'],
    }

    # Copy files
    exec { 'keystone-copy-ssl-certs':
      command   => "/usr/bin/scp -P $ssh_port -r -o StrictHostKeyChecking=no keystone@${keystone_master_name}:/etc/keystone/ssl /etc/keystone/",
      creates   => '/etc/keystone/ssl/synced_from_master',
      user      => 'keystone',
      require   => File['/var/lib/keystone/.ssh/id_rsa'],
      notify    => Service['keystone']
    }
  }

  class {'ceilometer::keystone::auth':

    public_url          => $ceilometer_public_url,
    internal_url        => $ceilometer_internal_url,
    admin_url           => $ceilometer_admin_url,

    region              => $region,
    password            => $ceilometer_password
  }

  class { 'nova::keystone::auth':

    public_url          => $nova_v2_public_url,
    internal_url        => $nova_v2_internal_url,
    admin_url           => $nova_v2_admin_url,

    public_url_v3       => $nova_v3_public_url,
    internal_url_v3     => $nova_v3_internal_url,
    admin_url_v3        => $nova_v3_admin_url,

    ec2_public_url      => $nova_ec2_public_url,
    ec2_internal_url    => $nova_ec2_internal_url, 
    ec2_admin_url       => $nova_ec2_admin_url,

    region              => $region,
    password            => $nova_password
  }                                                                                                                                                                                                         

  class { 'neutron::keystone::auth':

    public_url          => $neutron_public_url,
    internal_url        => $neutron_internal_url,
    admin_url           => $neutron_admin_url,

    region              => $region,
    password            => $neutron_password
  }

  if $cinder_enabled {
    class { 'cinder::keystone::auth':

      public_url        => $cinder_v1_public_url,
      internal_url      => $cinder_v1_internal_url,
      admin_url         => $cinder_v1_admin_url,

      public_url_v2     => $cinder_v2_public_url,
      internal_url_v2   => $cinder_v2_internal_url,
      admin_url_v2      => $cinder_v2_admin_url,

      region            => $region,
      password          => $cinder_password
    }
  }

  class { 'glance::keystone::auth':

    public_url          => $glance_public_url,
    internal_url        => $glance_internal_url,
    admin_url           => $glance_admin_url,

    region              => $region,
    password            => $glance_password
  }

  class { 'heat::keystone::auth':

    public_url          => $heat_public_url,                                                                                                                                                                
    internal_url        => $heat_internal_url,
    admin_url           => $heat_admin_url,                                                                                                                                                                 

    region              => $region,
    password            => $heat_password
  }

  class { 'heat::keystone::auth_cfn':

    public_url          => $heat_cfn_public_url,
    internal_url        => $heat_cfn_internal_url,
    admin_url           => $heat_cfn_admin_url,

    region              => $region,
    password            => $heat_password
  }

  if $trove_enabled {
    class {'trove::keystone::auth':

      public_url        => $trove_public_url,
      internal_url      => $trove_internal_url,
      admin_url         => $trove_admin_url,

      region            => $region,
      password          => $trove_password
    }
  }

  # Purge expored tokens every days at midnight
  class { 'keystone::cron::token_flush': }

  # Note(EmilienM):
  # We check if DB tables are created, if not we populate Keystone DB.
  # It's a hack to fit with our setup where we run MySQL/Galera
  # TODO(Goneri)
  # We have to do this only on the primary node of the galera cluster to avoid race condition
  # https://github.com/enovance/puppet-openstack-cloud/issues/156
  exec {'keystone_db_sync':
    command => 'keystone-manage db_sync',
    path    => '/usr/bin',
    user    => 'keystone',
    unless  => "/usr/bin/mysql keystone -h ${keystone_db_host} -u ${encoded_user} -p${encoded_password} -e \"show tables\" | /bin/grep Tables",
    require => Package['mysql_client']
  }

  if $::cloud::manage_firewall {
    cloud::firewall::rule{ '100 allow keystone access':
      port   => $ks_keystone_public_port,
      extras => $firewall_settings,
    }
    cloud::firewall::rule{ '100 allow keystone admin access':
      port   => $ks_keystone_admin_port,
      extras => $firewall_settings,
    }
  }

  @@haproxy::balancermember{"${::fqdn}-keystone_api":
    listening_service => 'keystone_api_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_keystone_public_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

  @@haproxy::balancermember{"${::fqdn}-keystone_api_admin":
    listening_service => 'keystone_api_admin_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_keystone_admin_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

}
