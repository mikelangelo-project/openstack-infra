#
class cloud::profile::nova_docker {

  file { '/tmp/setup_nova_docker.sh':
    ensure => file,
    source => 'puppet:///modules/cloud/docker/setup_nova_docker.sh',
    owner  => root,
    group  => root,
    mode   => 'a+x',
    audit  => content,
  } 

  exec { '/tmp/setup_nova_docker.sh':
    subscribe => File['/tmp/setup_nova_docker.sh'],
  }

}