class cloud::profile::aptly(
  $vhost = undef,
) {

  # ----- Setup apache for serving apt repos managed by aptly

  class { 'apache':
    default_mods    => false,
    default_vhost   => false,
    purge_configs   => true,
  }

  apache::vhost { "$vhost":
    port          => '80',
    docroot       => '/var/lib/aptly/public',
  }
}
