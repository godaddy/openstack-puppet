class profile::openstack::network inherits profile::base {

  require profile::openstack::novabase
  require profile::openstack::cluster
  require profile::openstack::interfaces

  # Set up nova-network for FlatDHCPManager
  # Make sure fixed_range = '', which means nova will go to
  # the database for all network info
  class {
    'nova::network':
      network_manager   => 'nova.network.manager.FlatDHCPManager',
      public_interface  => '',
      create_networks   => false,
      fixed_range   => '',
      # corosync handles starting the service
      # TODO: include some logic here to enable the service if we're not doing corosync
      enabled => false,
  }

  nova_config {
    'DEFAULT/dnsmasq_config_file':  value => '/etc/dnsmasq-nova.conf';
    'DEFAULT/send_arp_for_ha':  value => True;
    'DEFAULT/dhcp_lease_time': value => hiera('network::dhcp_lease_time', 3600);
  }

  # All nova-network nodes need to have the same 'host' setting
  nova_config {
    'DEFAULT/host':
      value => hiera('network::host')
  }

  # sysctl settings for proper metadata arping
  sysctl::value {
      'net.ipv4.conf.all.arp_ignore': value => '0';
      'net.ipv4.conf.all.arp_announce': value => '2';
      'net.ipv4.conf.default.arp_ignore': value => '0';
      'net.ipv4.conf.default.arp_announce': value => '2';
      'net.ipv4.conf.bond0.arp_ignore': value => '0';
      'net.ipv4.conf.bond0.arp_announce': value => '2';
  }

  # Failover IP for nova-network.  Eventually we will do this stuff per network
  # as different network nodes manage different networks
  $failover_ip = hiera('network::failover_ip')
  $failover_ip_netmask = hiera('network::failover_ip_netmask')
  $failover_ip_nic = hiera('network::failover_ip_nic')
  corosync::resource::ip {
    $failover_ip:
      cidr_netmask => $failover_ip_netmask,
      nic => $failover_ip_nic,
      interval => '10s',
  }

  # Failover IP for metadata (169.254.169.254).  This needs to follow where nova-network is running.
  corosync::resource::ip {
    '169.254.169.254':
      cidr_netmask => 32,
      nic => 'lo',
      interval => '10s',
  }

  # Nova-network service
  $rabbit_ssl = hiera('message::ssl', false)
  corosync::resource::nova_network {
    'p_nova_network':
      amqp_server_port => $rabbit_ssl ? { true => '5671', default => '5672' },
      require => Class['nova::network'],
  }

  # Cluster constraints here
  # TODO: Implement this as corosync::constraint::{order,colocation,etc.} someday
  exec {
    'nova_network-failover-ip-start-order-constraint':
      command => "/usr/sbin/pcs constraint order start ip-${failover_ip} then start nova_network-p_nova_network",
      unless => "/usr/sbin/pcs constraint order show | grep 'start ip-${failover_ip} then start nova_network-p_nova_network'",
      require => [ Corosync::Resource::Ip[$failover_ip], Corosync::Resource::Nova_network['p_nova_network'] ];

    'nova-network-failover-ip-stop-order-constraint':
      command => "/usr/sbin/pcs constraint order stop nova_network-p_nova_network then stop ip-${failover_ip}",
      unless => "/usr/sbin/pcs constraint order show | grep 'stop nova_network-p_nova_network then stop ip-${failover_ip}'",
      require => [ Corosync::Resource::Ip[$failover_ip], Corosync::Resource::Nova_network['p_nova_network'] ];

    'nova_network-metadata-ip-start-order-constraint':
      command => "/usr/sbin/pcs constraint order start ip-169.254.169.254 then start nova_network-p_nova_network",
      unless => "/usr/sbin/pcs constraint order show | grep 'start ip-169.254.169.254 then start nova_network-p_nova_network'",
      require => [ Corosync::Resource::Ip['169.254.169.254'], Corosync::Resource::Nova_network['p_nova_network'] ];

    'nova-network-metadata-ip-stop-order-constraint':
      command => "/usr/sbin/pcs constraint order stop nova_network-p_nova_network then stop ip-169.254.169.254",
      unless => "/usr/sbin/pcs constraint order show | grep 'stop nova_network-p_nova_network then stop ip-169.254.169.254'",
      require => [ Corosync::Resource::Ip['169.254.169.254'], Corosync::Resource::Nova_network['p_nova_network'] ];

    'nova-network-failover-ip-colocation-constraint':
      command => "/usr/sbin/pcs constraint colocation add nova_network-p_nova_network ip-${failover_ip}",
      unless => "/usr/sbin/pcs constraint colocation show | grep 'nova_network-p_nova_network with ip-${failover_ip}'",
      require => [ Corosync::Resource::Ip[$failover_ip], Corosync::Resource::Nova_network['p_nova_network'] ];

    'nova-network-metadata-ip-colocation-constraint':
      command => "/usr/sbin/pcs constraint colocation add nova_network-p_nova_network ip-169.254.169.254",
      unless => "/usr/sbin/pcs constraint colocation show | grep 'nova_network-p_nova_network with ip-169.254.169.254'",
      require => [ Corosync::Resource::Ip['169.254.169.254'], Corosync::Resource::Nova_network['p_nova_network'] ];

    'failover-ip-metadata-ip-colocation-constraint':
      command => "/usr/sbin/pcs constraint colocation add ip-${failover_ip} ip-169.254.169.254",
      unless => "/usr/sbin/pcs constraint colocation show | grep '${failover_ip} with ip-169.254.169.254'",
      require => [ Corosync::Resource::Ip['169.254.169.254'], Corosync::Resource::Ip[$failover_ip] ];
  }

  # Build dnsmasq-nova.conf
  $networks = hiera('network::networks', [ ])
  $vlan_interface = hiera('network::vlan_interface', 'bond0')

  each($networks) | $cidr, $params | {

    $underscored = regsubst($cidr, "[./]", '_', 'G')
    $vlan = $networks[$cidr]['vlan']
    $label = $vlan ? { 0 => $underscored, default => "${underscored}_vlan${vlan}" }
    $hwrouter = $networks[$cidr]['hardware_router']
    $dns1 = $networks[$cidr]['dns1']
    $dns2 = $networks[$cidr]['dns2']

    file_line {
      "dnsmasq-nova-${label}-router":
        line => "dhcp-option=tag:${label},option:router,${hwrouter}",
        match => "^dhcp-option=tag:${label},option:router",
        path => "/etc/dnsmasq-nova.conf",
        require => File["/etc/dnsmasq-nova.conf"];

      "dnsmasq-nova-${label}-dns":
        line => "dhcp-option=tag:${label},option:dns-server,${dns1},${dns2}",
        match => "^dhcp-option=tag:${label},option:dns-server",
        path => "/etc/dnsmasq-nova.conf",
        require => File["/etc/dnsmasq-nova.conf"];
    }

    # Need dnsmasq config in place before nova-network starts
    File_line["dnsmasq-nova-${label}-router"] -> Class['nova::network']
    File_line["dnsmasq-nova-${label}-dns"] -> Class['nova::network']

    # Metadata arp settings
    sysctl::value {
      # sysctl command line can't handle components containing dots (e.g. bond0.1711)
      #"net.ipv4.conf.${vlan_interface}.${vlan}.arp_ignore": value => 0;
      "net.ipv4.conf.br${vlan}.arp_ignore": value => '0';
      #"net.ipv4.conf.${vlan_interface}.${vlan}.arp_announce": value => 2;
      "net.ipv4.conf.br${vlan}.arp_announce": value => '2';
    }

  }

  file { '/etc/dnsmasq-nova.conf':
    ensure => present,
    owner => root,
    group => root,
    mode => 0644,
  }
}
