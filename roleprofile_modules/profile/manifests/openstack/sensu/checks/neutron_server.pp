class profile::openstack::sensu::checks::neutron_server {

  $subscriberbase = hiera('sensu::subscriber_base')
  $auth_protocol  = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host      = hiera('identity::keystone_host')
  $auth_url       = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user     = hiera('identity::admin_user', 'keystone')
  $admin_password = hiera('identity::admin_password', 'keystone')
  $protocol       = hiera('network::neutron::ssl_cert', '') ? { '' => 'http', default => 'https' }

  $api_workers = hiera('network::neutron::api_workers', 1)
  sensu::check {'neutron_server_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/neutron-server -C ${api_workers}",
    subscribers => "${subscriberbase}_neutron_server",
  }

  sensu::check {'neutron_agent_status':
    command     => "/etc/sensu/plugins/neutron-agent-status.py --auth-url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack",
    subscribers => "${subscriberbase}_neutron_server",
  }

  sensu::check {'neutron_api':
    command     => "/etc/sensu/plugins/check_neutron-api.py --auth-url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack --bypass ${protocol}://localhost:9696",
    subscribers => "${subscriberbase}_neutron_server",
  }

}

