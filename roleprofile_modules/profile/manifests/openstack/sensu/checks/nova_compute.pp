class profile::openstack::sensu::checks::nova_compute {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_compute_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-compute -C 1",
    subscribers => "${subscriberbase}_nova_compute",
  }

}

