class profile::openstack::neutron::networknode inherits profile::base {

  require profile::openstack::neutron::base
  require profile::openstack::neutron::interfaces
  require profile::openstack::neutron::ipv6

  include profile::openstack::openstackkernel

  $ssl_cert = hiera('network::neutron::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $protocol = 'http'
      $require = [ ]
    }
    default: {
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      $protocol = 'https'
      realize Sslcert[$ssl_cert]
      $require = [ Sslcert[$ssl_cert] ]
    }
  }

  # Additional setup for OVS plugin
  class { 'neutron::plugins::ovs': }

  neutron_config {
    'DEFAULT/log_dir': value => "/var/log/neutron";
  }

  neutron_plugin_ovs {
    'ovs/local_ip': value => hiera('server::ip_address', $::ipaddress);
    'agent/root_helper': value => 'sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf';
    'securitygroup/firewall_driver': value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
  }

  # TODO: Make this work for multiple networks/subnets
  $networks = hiera('network::networks', [ ])

  each($networks) | $netname, $netparams | {
    $subnets = $networks[$netname]['subnets']

    # dhcp_agent.ini
    $dhcp_domain = $networks[$netname]['dhcp_domain']
    file { '/etc/neutron/dhcp_agent.ini':
      ensure => present,
      content => template("${module_name}/dhcp_agent.ini"),
      owner => root,
      group => neutron,
      mode => '0640',
      notify => Service['openstack-neutron-dhcp-agent'];
    }

    each($subnets) | $cidr, $cidrparams | {

      $vlan = $networks[$netname]['subnets'][$cidr]['vlan']

      neutron_plugin_ovs {
        'ovs/bridge_mappings': value => "${netname}:br${vlan}";
      }
    }
  }

  # Fix up OVS agent init script
  file_line {
    'ovs-agent-init':
      line => "daemon_args='--config-file=/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini --config-file=/etc/neutron/neutron.conf'",
      match => '^daemon_args=',
      path => '/etc/rc.d/init.d/openstack-neutron-openvswitch-agent',
      require => Class['profile::openstack::neutron::base'];
  }

  # Services that need to be run/enabled
  service {
    [ 'openstack-neutron-openvswitch-agent', 'openstack-neutron-dhcp-agent' ]:
      ensure => running,
      enable => true;

    'openstack-neutron-ovs-cleanup':
      enable => true;
  }

  # Restart services if config changes
  Neutron_config<||> ~> Service['openstack-neutron-openvswitch-agent']
  Neutron_config<||> ~> Service['openstack-neutron-dhcp-agent']
  Neutron_plugin_ovs<||> ~> Service['openstack-neutron-openvswitch-agent']
  Neutron_plugin_ovs<||> ~> Service['openstack-neutron-dhcp-agent']

  # dnsmasq
  package { [ 'dnsmasq', 'dnsmasq-utils' ]:
    ensure => present;
  }
}
