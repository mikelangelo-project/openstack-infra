#
class cloud::role::compute inherits ::cloud::role::base {

    # Use fixed uids / gids for nova user
    User['nova'] -> Package['nova-common']

    class { '::cloud::storage::rbd': }                  ->

    class { '::cloud::network::l3': }                   ->
    class { '::cloud::network::metadata': }             ->
    class { '::cloud::compute::hypervisor': }           ->

    class { '::cloud::auth_file': }

}
