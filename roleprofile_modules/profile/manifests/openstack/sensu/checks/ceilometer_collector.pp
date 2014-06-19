class profile::openstack::sensu::checks::ceilometer_collector {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'ceilometer_collector_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/ceilometer-collector -C 1",
    subscribers => "${subscriberbase}_ceilometer_collector",
  }

  sensu::check {'ceilometer_collector':
    command     => "/etc/sensu/plugins/check_ceilometer-collector.sh",
    subscribers => "${subscriberbase}_ceilometer_collector",
  }

}

