class profile::openstack::metadata inherits profile::base {

  require profile::openstack::novabase

  nova::generic_service { 'api':
    enabled        => false,
    ensure_package => present,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
  }

  service {
    'openstack-nova-metadata-api':
      ensure => running,
      enable => true,
      require => Nova::Generic_service['api'];
  }
  Nova_config<| |> ~> Service['openstack-nova-metadata-api']

  # Additional config for Neutron
  if hiera('network::provider') == 'neutron' {
    $neutronproto = hiera('network::neutron::ssl_cert', '') ? { '' => 'http', default => 'https' }
    $neutronhost = hiera('network::neutron::public_address')

    $keystoneproto = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
    $keystonehost = hiera('identity::keystone_host')

    nova_config {
      'DEFAULT/metadata_host': value => '127.0.0.1';
    }

    # Corosync managed link local IP binding
    require profile::openstack::cluster
    include profile::openstack::neutron::interfaces

    corosync::resource::ip {
      "lo_169.254.169.254":
        ip_addr => '169.254.169.254',
        cidr_netmask => 32,
        nic => "lo",
        interval => '10s',
     }

    service { 'openstack-nova-network':
      ensure => stopped,
      enable => false,
    }

    service { 'iptables':
      enable => true,
      notify => [ Service['openstack-nova-metadata-api'], Service['openstack-neutron-openvswitch-agent'], Service['openstack-neutron-dhcp-agent'] ],
    }

    file { '/etc/sysconfig/iptables':
      content => template('profile/iptables.sysconfig-metadata.erb'),
      owner => 'root',
      group => 'root',
      mode => '0644',
      notify => Service['iptables'],
    }

    # Roundabout way to get dhcp_domain for nova.conf
    # TODO: Make this work for multiple networks/subnets
    $networks = hiera('network::networks', [ ])
    each($networks) | $netname, $netparams | {
      $dhcp_domain = $networks[$netname]['dhcp_domain']
      nova_config {
        'DEFAULT/dhcp_domain': value => $dhcp_domain, notify => Service['openstack-nova-metadata-api'];
      }
    }

  } # endif

}
