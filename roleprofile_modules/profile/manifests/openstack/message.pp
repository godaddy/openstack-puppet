class profile::openstack::message inherits profile::base {

  $rabbit_user = hiera('message::username')
  $rabbit_password = hiera('message::password')

  $ssl_cert = hiera('message::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $require = [ ]
    }
    default: {
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      realize Sslcert[$ssl_cert]
      if $::profile::sslcerts::cacert_file != '' {
        realize Sslcert::Cacert['cacert']
        $require = [ Sslcert[$ssl_cert], Sslcert::Cacert['cacert'] ]
      } else {
        $require = [ Sslcert[$ssl_cert] ]
      }
    }
  }

  class {
    'rabbitmq':
      config_cluster            => true,
      cluster_nodes             => hiera('message::cluster_nodes'),
      wipe_db_on_cookie_change  => true,
      delete_guest_user         => hiera('message::keep_guest_user', 'false') ? { true => false, default => true },
      manage_repos              => false,
      ssl                       => hiera('message::ssl', false),
      ssl_only                  => hiera('message::ssl_only', false),
      ssl_cert                  => $real_ssl_cert,
      ssl_key                   => $real_ssl_key,
      ssl_cacert                => $::profile::sslcerts::cacert_file,
      ssl_management_port       => '15672',
      environment_variables     => { 'RABBITMQ_NODE_PORT' => 'UNSET' },
      require                   => $require
  }

  rabbitmq_user {
    $rabbit_user:
      admin   => true,
      password  => $rabbit_password,
      provider => 'rabbitmqctl'
  }

  rabbitmq_user_permissions {
    "${rabbit_user}@/":
      configure_permission  => '.*',
      read_permission   => '.*',
      write_permission  => '.*',
      require     => Rabbitmq_user[$rabbit_user]
  }

  exec {
    'rabbitmq_ha_policy':
      command => "/usr/sbin/rabbitmqctl set_policy ha-all \".*\" '{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}'",
      unless  => "/usr/sbin/rabbitmqctl list_policies | grep -E '^\\/[[:space:]]+ha-all[[:space:]]+all[[:space:]]+\\.\\*[[:space:]]+{\"ha-mode\":\"all\",\"ha-sync-mode\":\"automatic\"}[[:space:]]+[0-9]+'",
      require => Class['rabbitmq'],
  }

}

