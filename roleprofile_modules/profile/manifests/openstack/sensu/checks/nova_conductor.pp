class profile::openstack::sensu::checks::nova_conductor {

  $subscriberbase = hiera('sensu::subscriber_base')

  $api_workers = hiera('api::workers', 1)
  sensu::check {'nova_conductor_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-conductor -C ${api_workers}",
    subscribers => "${subscriberbase}_nova_conductor",
  }

}

