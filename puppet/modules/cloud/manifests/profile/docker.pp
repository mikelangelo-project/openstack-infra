#
class cloud::profile::docker {

  class { '::Docker': } -> Exec["docker-system-user-nova"]

  exec { "docker-system-user-nova":
    command => "/usr/sbin/usermod -aG ${::docker::params::docker_group} nova",
    unless  => "/bin/cat /etc/group | grep '^${::docker::params::docker_group}:' | grep -qw nova",
  }

}
