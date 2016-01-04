# ==Define: cloud::volume::qos::associate
#
# Associate qos with the volume type.
#
# === Parameters
#
# [*os_password*]
#   (required) The keystone tenant:username password.
#
# [*qos_name*]
#   (required) Accepts single name of qos to associate.
#
# [*volume_type*]
#   (required) the associated volume_type for the qos.
#
# [*os_tenant_name*]
#   (optional) The keystone tenant name. Defaults to 'admin'.
#
# [*os_username*]
#   (optional) The keystone user name. Defaults to 'admin.
#
# [*os_auth_url*]
#   (optional) The keystone auth url. Defaults to 'http://127.0.0.1:5000/v2.0/'.
#
# [*os_region_name*]
#   (optional) The keystone region name. Default is unset.
#
# Author: Maik Srba <msrba@gwdg.de>


define cloud::volume::qos::associate (
  $qos_name,
  $volume_type,
  $os_password,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/',
  $os_region_name = undef,
  ) {

  $qos_env = [
    "OS_TENANT_NAME=${os_tenant_name}",
    "OS_USERNAME=${os_username}",
    "OS_PASSWORD=${os_password}",
    "OS_AUTH_URL=${os_auth_url}",
  ]

  if $os_region_name {
    $region_env = ["OS_REGION_NAME=${os_region_name}"]
  }
  else {
    $region_env = []
  }

  exec {"cinder qos-associate ${qos_name} associate with ${volume_type}":
    path        => ['/usr/bin', '/bin'],
    command     => "cinder qos-associate \$(cinder qos-list | awk '{if (\$4 == \"${qos_name}\") print \$2}') \$(cinder type-list | awk '{if (\$4 == \"${volume_type}\") print \$2}')",
    unless      => "cinder qos-get-association \$(cinder qos-list | awk '{if (\$4 == \"${qos_name}\") print \$2}') | grep -Eq '\\bvolume_type\\b.*\\b${volue_type}\\b'",
    environment => concat($qos_env, $region_env),
    require     => Package['python-cinderclient']
  }
}
