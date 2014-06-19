class profile::openstack::sensu::checks::els_openstack_integrations {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'els-log-errors':
    command     => '/etc/sensu/plugins/check-log.rb -f /var/log/els/els-notifications-consumer.log -q "\.\d+ \d+ ERROR"',
    subscribers => "${subscriberbase}_els_openstack_integrations",
  }

}

