class profile::openstack::sensu::checks::ceilometer_compute {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'ceilometer_agent_compute':
    command     => "/etc/sensu/plugins/check_ceilometer-agent-compute.sh",
    subscribers => "${subscriberbase}_ceilometer_compute",
    occurrences => 5,
  }

}

