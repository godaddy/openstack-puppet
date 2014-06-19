class profile::openstack::sensu::checks::horizon {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'horizon_httpd_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/sbin/httpd -C 1",
    subscribers => "${subscriberbase}_horizon",
  }

}

