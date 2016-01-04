class cloud::role::mongodb inherits ::cloud::role::base {

    class { '::mongodb::globals':
#        manage_package_repo => true,
    }                                                       ->
    class { '::mongodb::server': }                          ->
    class { '::mongodb::client': }                          ->
    class { '::mongodb::replset': }

#    class { '::cloud::database::nosql::mongodb::mongod': }
}
