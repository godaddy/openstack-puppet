class profile::openstack::sensu::checks::glance_registry {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'glance_registry_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/glance-registry -C 1",
    subscribers => "${subscriberbase}_glance_registry",
  }

}

