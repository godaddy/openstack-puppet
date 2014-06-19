class profile::openstack::sensu::checks::nova_api {

  $subscriberbase = hiera('sensu::subscriber_base')

  $auth_protocol  = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host      = hiera('identity::keystone_host')
  $auth_url       = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user     = hiera('identity::admin_user', 'keystone')
  $admin_password = hiera('identity::admin_password', 'keystone')
  $protocol       = hiera('api::ssl_cert', '') ? { '' => 'http', default => 'https' }


  $api_workers = hiera('api::workers', 1)
  sensu::check {'nova_api_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-api -C ${api_workers}",
    subscribers => "${subscriberbase}_nova_api",
  }

  sensu::check {'nova_api':
    command     => "/etc/sensu/plugins/check_novaapi --auth_url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack --bypass '${protocol}://localhost:8774/v2/%(tenant_id)s'",
    subscribers => "${subscriberbase}_nova_api",
  }

  sensu::check {'nova_compute_services':
    command     => "/etc/sensu/plugins/check_nova_services --auth_url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack",
    subscribers => "${subscriberbase}_nova_api",
  }


}

