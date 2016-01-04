# ==Define: cloud::volume::qos::set
#
# Assigns keys after the volume type is set.
#
# === Parameters
#
# [*os_password*]
#   (required) The keystone tenant:username password.
#
# [*qos_name*]
#   (required) Accepts single name of type to set.
#
# [*key*]
#   (required) the key name that we are setting the value for.
#
# [*value*]
#   the value that we are setting. Defaults to content of namevar.
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


define cloud::volume::qos::set (
  $qos_name,
  $key            = $name,
  $os_password,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/',
  $os_region_name = undef,
  $value,
  ) {

# TODO: (xarses) This should be moved to a ruby provider so that among other
#   reasons, the credential discovery magic can occur like in neutron.

  $qos_env = [
    "OS_TENANT_NAME=${os_tenant_name}",
    "OS_USERNAME=${os_username}",
    "OS_PASSWORD=${os_password}",
    "OS_AUTH_URL=${os_auth_url}",
    "OS_VOLUME_API_VERSION=1",
  ]

  if $os_region_name {
    $region_env = ["OS_REGION_NAME=${os_region_name}"]
  }
  else {
    $region_env = []
  }

  exec {"cinder qos-key ${qos_name} set ${key}=${value}":
    path        => ['/usr/bin', '/bin'],
    command     => "cinder qos-key \$(cinder qos-list | awk '{if (\$4 == \"${qos_name}\") print \$2}') set ${key}=${value}",
    unless      => "cinder qos-list | grep -Eq '\\b${qos_name}\\b.*\\b${key}\\b.{5}\\b${value}\\b'",
    environment => concat($qos_env, $region_env),
    require     => Package['python-cinderclient']
  }
}
