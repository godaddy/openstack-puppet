class profile::openstack::sensu::checks::heat_api_cfn {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'heat_api_cfn_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/heat-api-cfn -C 1",
    subscribers => "${subscriberbase}_heat_api_cfn",
  }

}

