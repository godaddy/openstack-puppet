class profile::openstack::sensu::checks::neutron_dhcp_agent {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'neutron_dhcp_agent_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/neutron-dhcp-agent -C 1",
    subscribers => "${subscriberbase}_neutron_dhcp_agent",
  }

}

