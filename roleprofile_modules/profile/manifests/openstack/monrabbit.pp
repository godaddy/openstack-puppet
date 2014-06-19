class profile::openstack::monrabbit inherits profile::base {

  # Install certs
  $ssl_cert = hiera('monitoring::rabbitmq::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $ssl_require = [ ]
    }
    default: {
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      realize Sslcert[$ssl_cert]
      $ssl_require = [ Sslcert[$ssl_cert] ]
    }
  }

  if $::profile::sslcerts::cacert_file != '' {
    realize Sslcert::Cacert['cacert']
    $real_ca_cert = $::profile::sslcerts::cacert_file
    $ca_require = [ Sslcert::Cacert['cacert'] ]
  } else {
    $ca_require = [ ]
  }

  $rabbit_user = hiera('monitoring::rabbitmq::admin_user', 'admin')
  $rabbit_pass = hiera('monitoring::rabbitmq::admin_pass', 'admin')

  $logstash_vhost    = hiera('logstash::mq_vhost', '/logstash')
  $logstash_user     = hiera('logstash::mq_user', 'logstash')
  $logstash_password = hiera('logstash::mq_pass', 'logstash')

  $sensu_vhost    = hiera('sensu::mq_vhost', '/sensu')
  $sensu_user     = hiera('sensu::mq_user', 'sensu')
  $sensu_password = hiera('sensu::mq_pass', 'sensu')

  class {'::rabbitmq':
    delete_guest_user        => hiera('monitoring::rabbitmq::delete_guest_user', true),
    config_cluster           => hiera('monitoring::rabbitmq::config_cluster', true),
    cluster_nodes            => hiera('monitoring::rabbitmq::cluster_nodes'),
    cluster_node_type        => hiera('monitoring::rabbitmq::cluster_node_type'),
    wipe_db_on_cookie_change => hiera('monitoring::rabbitmq::wipe_db_on_cookie_change', true),
    manage_repos             => false,
    ssl                      => hiera('monitoring::rabbitmq::ssl', false),
    ssl_only                 => hiera('monitoring::rabbitmq::ssl_only', false),
    ssl_cacert               => $real_ca_cert,
    ssl_cert                 => $real_ssl_cert,
    ssl_key                  => $real_ssl_key,
    ssl_management_port      => '15672',
    environment_variables    => { 'RABBITMQ_NODE_PORT' => 'UNSET' },
    require                  => [ $ssl_require, $ca_require ],
  }

  user { 'rabbitmq':
    ensure  => present,
    groups  => 'openstack',
    require => Group['openstack'],
  }


  # RabbitMQ admin user and permissions
  rabbitmq_user {
    $rabbit_user:
      password  => $rabbit_pass,
      admin     => true,
      provider  => 'rabbitmqctl',
  }

  rabbitmq_user_permissions {
    "${rabbit_user}@/":
      configure_permission  => '.*',
      read_permission   => '.*',
      write_permission  => '.*',
      require     => Rabbitmq_user[$rabbit_user]
  }


  # Logstash user, vhost, and permissions
  rabbitmq_user {
    $logstash_user:
      password  => $logstash_password,
      provider => 'rabbitmqctl'
  }

  rabbitmq_vhost {
    $logstash_vhost:
      ensure => present,
  }

  rabbitmq_user_permissions {
    "${logstash_user}@${logstash_vhost}":
      configure_permission  => '.*',
      read_permission       => '.*',
      write_permission      => '.*',
      require               => [ Rabbitmq_user[$logstash_user], Rabbitmq_vhost[$logstash_vhost] ],
  }

  rabbitmq_user_permissions {
    "${rabbit_user}@${logstash_vhost}":
      configure_permission  => '.*',
      read_permission       => '.*',
      write_permission      => '.*',
      require               => [ Rabbitmq_vhost[$logstash_vhost], Rabbitmq_user[$rabbit_user] ],
  }


  # Sensu user, vhost, and permissions
  rabbitmq_user {
    $sensu_user:
      password  => $sensu_password,
      provider => 'rabbitmqctl'
  }

  rabbitmq_vhost {
    $sensu_vhost:
      ensure => present,
  }

  rabbitmq_user_permissions {
    "${sensu_user}@${sensu_vhost}":
      configure_permission  => '.*',
      read_permission       => '.*',
      write_permission      => '.*',
      require               => [ Rabbitmq_user[$sensu_user], Rabbitmq_vhost[$sensu_vhost] ],
  }

  rabbitmq_user_permissions {
    "${rabbit_user}@${sensu_vhost}":
      configure_permission  => '.*',
      read_permission       => '.*',
      write_permission      => '.*',
      require               => [ Rabbitmq_vhost[$sensu_vhost], Rabbitmq_user[$rabbit_user] ],
  }


  $dsrvip = hiera('monitoring::rabbitmq::vip', '')

  if $dsrvip != '' {
    l23network::l3::ifconfig { "dsrvip_${dsrvip}":
      interface => 'dummy0',
      ipaddr => $dsrvip,
      netmask => '255.255.255.255',
    }
  }

}
