#
class cloud::role::aptly inherits ::cloud::role::base {

    class { '::cloud::profile::aptly': }
}
