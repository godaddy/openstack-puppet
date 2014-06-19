class profile::openstack::sensu::checks::heat_api {

  $subscriberbase = hiera('sensu::subscriber_base')
  $auth_protocol  = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host      = hiera('identity::keystone_host')
  $auth_url       = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user     = hiera('identity::admin_user', 'keystone')
  $admin_password = hiera('identity::admin_password', 'keystone')
  $protocol       = hiera('orchestration::ssl_cert', '') ? { '' => 'http', default => 'https' }

  sensu::check {'heat_api_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/heat-api -C 1",
    subscribers => "${subscriberbase}_heat_api",
  }

  sensu::check {'heat_engine_corosync':
    command     => "/etc/sensu/plugins/check_crm",
    subscribers => "${subscriberbase}_heat_api",
  }

  sensu::check {'heat_api':
    command     => "/etc/sensu/plugins/check_heatapi --auth_url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack --endpoint '${protocol}://localhost:8004/v1/%(tenant_id)s'",
    subscribers => "${subscriberbase}_heat_api",
  }

}

