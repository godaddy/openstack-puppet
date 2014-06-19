class profile::openstack::sensu::checks::nova_consoleauth {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_consoleauth_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-consoleauth -C 1",
    subscribers => "${subscriberbase}_nova_consoleauth",
  }

}

