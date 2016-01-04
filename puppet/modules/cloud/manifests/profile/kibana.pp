#
class cloud::profile::kibana {
	
  $kibana_bind_ip = hiera('cloud::logging::server::kibana_bind_ip')
  $kibana_port = hiera('cloud::logging::server::kibana_port')

  #temporary until we have a logserver provision over puppet
  @@haproxy::balancermember{"${::fqdn}-kibana":
	listening_service => 'kibana',
	server_names      => $::hostname,
	ipaddresses       => $kibana_bind_ip,
	ports             => $kibana_port,
	options           => 'check inter 2000 rise 2 fall 5'
  }
}