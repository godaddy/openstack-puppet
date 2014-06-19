class profile::openstack::neutron::interfaces inherits profile::base {

  # Set up VLAN interfaces
  class {
    'l23network':
      use_ovs   => true,
  }

  # sysctl settings for proper metadata arping
  sysctl::value {
      'net.ipv4.conf.all.arp_ignore': value => '0';
      'net.ipv4.conf.all.arp_announce': value => '2';
      'net.ipv4.conf.default.arp_ignore': value => '0';
      'net.ipv4.conf.default.arp_announce': value => '2';
      'net.ipv4.conf.bond0.arp_ignore': value => '0';
      'net.ipv4.conf.bond0.arp_announce': value => '2';
      'net.ipv4.ip_forward': value => '1';
  }

  # OVS bridges
  l23network::l2::bridge { "br-int":
    require => Class['l23network::l2'];
  }
  l23network::l3::ifconfig { "br-int":
    ipaddr => 'none',
    require => L23network::L2::Bridge['br-int'];
  }

  l23network::l2::bridge { "br-ext":
    require => Class['l23network::l2'];
  }
  l23network::l3::ifconfig { "br-ext":
    ipaddr => 'none',
    require => L23network::L2::Bridge['br-ext'];
  }

  # Eth ports that are part of bond0
  # OVS now handles the bonding, so we need to configure them
  # as normal unbonded ports on the Linux side
  $bond0_ports = hiera('server::bond0ports', [ 'eth0', 'eth2' ])
  each($bond0_ports) | $ethport | {
    l23network::l3::ifconfig { $ethport:
      ipaddr            => 'none',
      use_ovs_override  => false,
    }
  }

  # Bond0/management interface
  l23network::l2::bond { "bond0":
    bridge  => 'br-ext',
    ports   => $bond0_ports,
    require => [ L23network::L2::Bridge['br-ext'], L23network::L3::Ifconfig[$bond0_ports] ],
  }
  l23network::l3::ifconfig { "bond0":
    ipaddr      => 'none',
    bridge      => 'br-ext',
    bond_ifaces => join($bond0_ports, ' '),
    ovs_extra   => inline_template('<% @bond0_ports.each do |ethport| %>set interface <%= ethport %> other-config:enable-vlan-splinters=true -- <% end %>'),
    require     => L23network::L2::Bond['bond0'];
  }
  l23network::l3::ifconfig { "mgmt0":
    ipaddr        => hiera('server::ip_address', $::ipaddress),
    netmask       => hiera('server::netmask', $::netmask),
    bridge        => "br-ext",
    type_override => "OVSIntPort",
    ovs_options   => "vlan_mode=native-untagged", 
    require       => L23network::L2::Bridge["br-ext"],
  }

  # Network-specific setup
  # See https://confluence.int.godaddy.com/display/CloudPatform/Openvswitch+Logical+Layout for how all this actually fits together
  $networks = hiera('network::networks', [ ])
  $vlan_interface = hiera('network::vlan_interface', 'bond0')

  each($networks) | $netname, $netparams | {
    $subnets = $networks[$netname]['subnets']

    each($subnets) | $cidr, $cidrparams | {

      $vlan = $networks[$netname]['subnets'][$cidr]['vlan']

      l23network::l2::bridge { "br${vlan}":
        require => Class['l23network::l2'];
      }

      l23network::l3::ifconfig {
        # Bridge interface
        "br${vlan}":
          ipaddr  => 'none',
          routes  => "${cidr} dev br${vlan}",
          require => L23network::L2::Bridge["br${vlan}"];

        # External port from br<vlan> bridge
        "br${vlan}-ext":
          ipaddr        => 'none',
          type_override => 'OVSIntPort',
          bridge        => "br${vlan}",
          ovs_extra     => "set interface br${vlan}-ext type=patch -- set interface br${vlan}-ext options:peer=ext-vlan-${vlan}",
          require       => L23network::L3::Ifconfig["br${vlan}"];

        # Tagged port from br-ext bridge
        "ext-vlan-${vlan}":
          ipaddr        => 'none',
          type_override => 'OVSIntPort',
          bridge        => 'br-ext',
          ovs_options   => "tag=${vlan}",
          ovs_extra     => "set interface ext-vlan-${vlan} type=patch -- set interface ext-vlan-${vlan} options:peer=br${vlan}-ext",
          require       => L23network::L3::Ifconfig['br-ext'];
      }

      # Metadata arp settings
      sysctl::value {
        "net.ipv4.conf.br${vlan}.arp_ignore": value => '0';
        "net.ipv4.conf.br${vlan}.arp_announce": value => '2';
      }

    }

  }

  # NOZEROCONF stuff to get rid of link-local routes
  file_line { 'nozeroconf':
    line => 'NOZEROCONF=yes',
    match => '^NOZEROCONF=',
    path => '/etc/sysconfig/network';
  }

  # If we change NOZEROCONF setting, need to down/up all the interfaces for it to take affect
  File_line['nozeroconf'] -> L23network::L3::Ifconfig<||>

}
