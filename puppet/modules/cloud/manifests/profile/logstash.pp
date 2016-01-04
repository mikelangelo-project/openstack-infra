#
class cloud::profile::logstash {

  $logstash_syslog_bind_ip = hiera('cloud::logging::server::logstash_syslog_bind_ip') 
  $logstash_syslog_port = hiera('cloud::logging::server::logstash_syslog_port') 

  #temporary until we have a logserver provision over puppet
  @@haproxy::balancermember{"${::fqdn}-logstash-syslog":
    listening_service => 'logstash_syslog',
    server_names      => $::hostname,
    ipaddresses       => $logstash_syslog_bind_ip,
    ports             => $logstash_syslog_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

  file { "/usr/bin/elasticsearch-remove-old-indices.sh":
    source => "puppet:///modules/cloud/logstash/elasticsearch-remove-old-indices.sh",
    ensure => present,
    mode   => "755"
  }

  cron { remove-older-indices:
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    command => "/usr/bin/elasticsearch-remove-old-indices.sh -i 5 -o /var/log/logstash/removed_indices.log",
    user    => root,
    hour    => 11,
    minute  => 30,
    ensure  => present
  }
  
}

