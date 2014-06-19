class profile::openstack::sensu::checks::glance_api {

  $subscriberbase   = hiera('sensu::subscriber_base')
  $auth_protocol    = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $auth_host        = hiera('identity::keystone_host')
  $auth_url         = "${auth_protocol}://${auth_host}:35357/v2.0/"
  $admin_user       = hiera('identity::admin_user', 'keystone')
  $admin_password   = hiera('identity::admin_password', 'keystone')
  $ssl_cert         = hiera('image::ssl_cert', '')
  $real_servers_ssl = hiera('image::real_servers::ssl', '')

  if hiera('image::real_servers::ssl', '') == false or $ssl_cert == '' { $protocol = 'http' } else { $protocol = 'https' }

  $api_workers = hiera('image::api_workers', 1)
  sensu::check {'glance_api_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/glance-api -C ${api_workers}",
    subscribers => "${subscriberbase}_glance_api",
  }

  sensu::check {'glance_api':
    command     => "/etc/sensu/plugins/check_glance --auth_url ${auth_url} --username ${admin_user} --password '${admin_password}' --tenant openstack --glance_url ${protocol}://localhost:9292 --host localhost --req_count 1",
    subscribers => "${subscriberbase}_glance_api",
  }

}

