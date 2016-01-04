#
class cloud::profile::dns_forwarder(

  $forwarders   = [],
  $zones        = {},
  $records      = {},

) {

  include dns::server

  # Forwarders
  dns::server::options { '/etc/bind/named.conf.options':
    forwarders => $forwarders,
  }

  create_resources('dns::zone',         $zones)
  create_resources('dns::record::a',    $records)

}
