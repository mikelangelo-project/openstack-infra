#
class cloud::role::lb inherits ::cloud::role::base {

    class { '::cloud::loadbalancer': }
}
