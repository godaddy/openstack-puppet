class profile::openstack::sensu::checks::ceilometer_api {

  $subscriberbase = hiera('sensu::subscriber_base')
  $auth_protocol  = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host      = hiera('identity::keystone_host')
  $auth_url       = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user     = hiera('identity::admin_user', 'keystone')
  $admin_password = hiera('identity::admin_password', 'keystone')
  $protocol       = hiera('metering::ssl_cert', '') ? { '' => 'http', default => 'https' }

  sensu::check {'ceilometer_api_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/ceilometer-api -C 1",
    subscribers => "${subscriberbase}_ceilometer_api",
  }

  sensu::check {'ceilometer_central_corosync':
    command     => "/etc/sensu/plugins/check_crm",
    subscribers => "${subscriberbase}_ceilometer_api",
  }

  sensu::check {'ceilometer_api':
    command     => "/etc/sensu/plugins/check_ceilometer-api.sh -H ${auth_url} -U ${admin_user} -P '${admin_password}' -T openstack -E ${protocol}://localhost:8777",
    subscribers => "${subscriberbase}_ceilometer_api",
    interval    => 300,
    occurrences => 4,
  }

}

