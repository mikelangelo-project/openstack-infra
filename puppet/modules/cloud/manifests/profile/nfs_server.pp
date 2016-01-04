#
class cloud::profile::nfs_server (

  $server = '',
  $clients = [], 
) {

  include ::nfs::server

  # Shared storage for live migrations
  nfs::server::export { '/storage/instances':
    nfstag  => 'instances',
    ensure  => 'mounted',
    server  => $server,
    clients => $clients,
#    owner   => 'nova',
#    group   => 'nova',
    mount   => '/var/lib/nova/instances',
  }

  # Glance storage for images
  nfs::server::export { '/storage/images':
    nfstag  => 'images',
    ensure  => 'mounted',
    server  => $server,
    clients => $clients,
    mount   => '/var/lib/glance/images',
  }

  # Glance storage for image-cache
  nfs::server::export { '/storage/image-cache':
    nfstag  => 'image-cache',
    ensure  => 'mounted',
    server  => $server,
    clients => $clients,
    mount   => '/var/lib/glance/image-cache',
  }

  # Cinder volume storage
  nfs::server::export { '/storage/volumes':
    nfstag  => 'cinder',
    ensure  => 'mounted',
    server  => $server,
    clients => $clients,
#   mount   => '/var/lib/nova/instances',
  }
}
