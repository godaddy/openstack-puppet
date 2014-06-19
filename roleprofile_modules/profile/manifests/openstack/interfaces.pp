class profile::openstack::interfaces inherits profile::base {

  # Set up VLAN interfaces
  class {
    'l23network':
      use_ovs   => false,
  }

  $networks = hiera('network::networks', [ ])
  $vlan_interface = hiera('network::vlan_interface', 'bond0')

  each($networks) | $cidr, $params | {
    l23network::l3::ifconfig {

      # Bridge interface
      "br${networks[$cidr]['vlan']}":
        ipaddr => 'none';

      # VLAN interface
      "${vlan_interface}.${networks[$cidr]['vlan']}":
        ipaddr  => 'none',
        bridge => "br${networks[$cidr]['vlan']}",
        require => L23network::L3::Ifconfig["br${networks[$cidr]['vlan']}"]

    }
  }

  # Make sure OVS stuff is gone
  file {
    '/etc/modprobe.d/ovs.conf':
      ensure  => absent,
  }

}
