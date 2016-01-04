#
class cloud::role::galera inherits ::cloud::role::base {

    class { '::cloud::database::sql::mysql': }
}
