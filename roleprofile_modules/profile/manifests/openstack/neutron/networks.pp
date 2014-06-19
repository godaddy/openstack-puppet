class profile::openstack::neutron::networks inherits profile::base {

  include profile::openstack::neutron::base

  $networks = hiera('network::networks')

  each($networks) | $netname, $netparams | {

    # TODO: Figure out how to make this work for multiple networks
    class { 'neutron::plugins::ml2':
      type_drivers => [ 'flat', 'vlan' ],
      tenant_network_types => [ 'vlan' ],
      mechanism_drivers => [ 'openvswitch', 'linuxbridge' ],
      flat_networks => [ $netname ],
      network_vlan_ranges => [ ]
    }

  }

}
