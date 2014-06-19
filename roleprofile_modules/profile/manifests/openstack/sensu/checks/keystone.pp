class profile::openstack::sensu::checks::keystone {

  $subscriberbase = hiera('sensu::subscriber_base')
  $auth_protocol  = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host      = 'localhost'
  $auth_url       = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user     = hiera('identity::admin_user', 'keystone')
  $admin_password = hiera('identity::admin_password', 'keystone')
  $db_connection  = hiera('identity::keystone_sql_connection')
  $db_user        = regsubst($db_connection, '^mysql:\/\/([^:\/]+):.*$', '\1')
  $db_pass        = regsubst($db_connection, '^mysql:\/\/[^:]+:([^@]+)@.*$', '\1')
  $db_host        = regsubst($db_connection, '^mysql:\/\/[^:]+:[^@]+@([^:\/]+)(:\d+\/|\/).*$', '\1')
  $db_name        = regsubst($db_connection, '^mysql:\/\/[^:]+:[^@]+@[^:\/]+(:\d+\/|\/)([^\?]+)(\?.+)?$', '\2')

  sensu::check {'keystone_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/keystone-all -C 1",
    subscribers => "${subscriberbase}_keystone",
  }

  sensu::check {'ldap_haproxy':
    command     => "/etc/sensu/plugins/check-haproxy.rb -A",
    subscribers => "${subscriberbase}_keystone",
  }

  sensu::check {'keystone_api':
    command     => "/etc/sensu/plugins/check_keystone-api.rb -u ${auth_url} -U ${admin_user} -P '${admin_password}' -T openstack",
    subscribers => "${subscriberbase}_keystone",
  }

  sensu::check {'keystone_tokens':
    command     => "/etc/sensu/plugins/keystone-token-metrics.rb -h ${db_host} -u ${db_user} -p ${db_pass} -d ${db_name}",
    type        => 'metric',
    subscribers => "${subscriberbase}_keystone",
    handlers    => [ 'default' ],
  }

}

