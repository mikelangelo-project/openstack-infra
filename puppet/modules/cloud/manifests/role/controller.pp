#
class cloud::role::controller inherits ::cloud::role::base {

    class { '::cloud::database::nosql::memcached': }    ->
    class { '::cloud::messaging': }                     ->
    class { '::cloud::identity': }                      ->
    class { '::cloud::image::registry': }               ->
    class { '::cloud::image::api': }                    ->

    class { '::cloud::volume': }                        ->
    class { '::cloud::volume::scheduler': }             ->
    class { '::cloud::volume::api': }                   ->

    class { '::cloud::compute::conductor': }            ->
    class { '::cloud::compute::cert': }                 ->
    class { '::cloud::compute::consoleauth': }          ->
    class { '::cloud::compute::consoleproxy': }         ->
    class { '::cloud::compute::api': }                  ->
    class { '::cloud::compute::scheduler': }            ->

    class { '::cloud::network::controller': }           ->
    class { '::cloud::dashboard': }                     ->
    class { '::cloud::orchestration::api': }            ->
    class { '::cloud::telemetry::api': }                ->

    class { '::cloud::auth_file': }

}
