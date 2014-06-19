class profile::openstack::sensu::checks::neutron_openvswitch_agent {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'neutron_openvswitch_agent_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/neutron-openvswitch-agent -C 1",
    subscribers => "${subscriberbase}_neutron_openvswitch_agent",
  }

}

