class profile::openstack::sensu::checks::nova_scheduler {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_scheduler_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-scheduler -C 1",
    subscribers => "${subscriberbase}_nova_scheduler",
  }

}

