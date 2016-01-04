#
class cloud::role::storage inherits ::cloud::role::base {

    # NFS setup (packages are also needed for cinder volume to mount nfs share)
    include ::nfs::client

    class { '::cloud::storage::rbd': }                  ->
#    class { '::cloud::storage::rbd::pools': }           ->

    class { '::cloud::volume::storage': }               ->

    class { '::cloud::auth_file': }

}
