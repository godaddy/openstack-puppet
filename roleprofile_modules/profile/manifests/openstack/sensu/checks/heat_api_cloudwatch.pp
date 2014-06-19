class profile::openstack::sensu::checks::heat_api_cloudwatch {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'heat_api_cloudwatch_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/heat-api-cloudwatch -C 1",
    subscribers => "${subscriberbase}_heat_api_cloudwatch",
  }

}

