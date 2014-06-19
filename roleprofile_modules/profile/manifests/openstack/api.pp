class profile::openstack::api inherits profile::base {

  require profile::openstack::novabase
  include profile::openstack::nova::policy

  $spice_proxy_ssl = hiera('api::spice_proxy_ssl', false)
  $spice_proxy_cert = hiera('api::spice_proxy_cert', '')

  $ssl_cert = hiera('api::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $enabled_ssl_apis = ''
      $protocol = 'http'
      $require = [ ]
    }
    default: {
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      $enabled_ssl_apis = "ec2,osapi_compute"
      $protocol = 'https'
      realize Sslcert[$ssl_cert]
      $require = [ Sslcert[$ssl_cert] ]
    }
  }

  class {
    'nova::api':
      enabled => true,
      admin_password    => hiera('api::password'),
      admin_user        => hiera('api::user', 'nova'),
      enabled_apis      => "ec2,osapi_compute",
      enabled_ssl_apis  => $enabled_ssl_apis,
      auth_host         => hiera('identity::keystone_host'),
      auth_protocol     => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
      ssl_cert_file     => $real_ssl_cert,
      ssl_key_file      => $real_ssl_key,
      workers           => hiera('api::workers', 40),
      require           => $require
  }

  class {
    'nova::cert':
      enabled => true
  }

  class {
    'nova::conductor':
      enabled => true
  }

  class {
    'nova::consoleauth':
      enabled => true
  }

  class {
    'nova::scheduler':
      enabled => true
  }

  if $spice_proxy_ssl {

    realize Sslcert[$spice_proxy_cert]
    
    class {
      'nova::spicehtml5proxy':
        enabled => true,
        host  => hiera('compute::spicehost'),
        ssl => $spice_proxy_ssl,
        cert  => "${ssl_path}/certs/${spice_proxy_cert}.crt",
        key => "${ssl_path}/private/${spice_proxy_cert}.key",
        require => Sslcert[$spice_proxy_cert],
    }

  } else {
    class {
      'nova::spicehtml5proxy':
        enabled => true,
        host  => hiera('compute::spicehost'),
    }
  }

  # Custom spicehtml5proxy init script for logging
  file { '/etc/rc.d/init.d/openstack-nova-spicehtml5proxy':
    ensure    => present,
    source    => "puppet:///modules/profile/openstack-nova-spicehtml5proxy.init",
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
    #require   => Class['nova::spicehtml5proxy'],
    notify    => Service['nova-spicehtml5proxy'],
  }

  # Disable setting root password
  nova_config {
    'DEFAULT/enable_instance_password': value => hiera('compute::libvirt_inject_password');
  }

  class {
    'nova::keystone::auth':
      auth_name         => hiera('api::user', 'nova'),
      password          => undef,
      email             => '',
      public_address    => hiera('api::public_address'),
      admin_address     => hiera('api::admin_address'),
      internal_address  => hiera('api::internal_address'),
      public_protocol   => $protocol,
      admin_protocol    => $protocol,
      internal_protocol => $protocol,
      region            => hiera('region'),
      # Hack so nova_volume service and endpoint are not added
      cinder            => true,
  }

  # Go Daddy specific Nova config
  nova_config {
    'godaddy/ldap_dn':                         value => hiera('api::godaddy::ldap_dn');
    'godaddy/ldap_password':                   value => hiera('api::godaddy::ldap_password'), secret => true;
    'godaddy/ldap_url':                        value => hiera('api::godaddy::ldap_url');
    'godaddy/ldap_base':                       value => hiera('api::godaddy::ldap_base');
    'godaddy/ldap_filter':                     value => hiera('api::godaddy::ldap_filter');
    'godaddy/server_name_regex':               value => hiera('api::godaddy::server_name_regex');
    'godaddy/server_name_max_length':          value => hiera('api::godaddy::server_name_max_length', 15);
    'godaddy/server_name_ldap_check_enabled':  value => hiera('api::godaddy::server_name_ldap_check_enabled');
  }

  # Enforce unique naming for VMs
  nova_config {
    'DEFAULT/osapi_compute_unique_server_name_scope': value => 'global';
  }

  # Increase number of workers for conductor
  nova_config {
    'conductor/workers':    value => hiera('api::workers', 40);
  }

  include profile::openstack::elsopenstackintegrations

  if hiera('network::provider') != 'neutron' {

    # Nova networking
    nova_config {
      'DEFAULT/network_manager': value => 'nova.network.manager.FlatDHCPManager';
    }

    # This is here instead of in the network profile because the network(s)
    # need to be created on the machine that's running nova-api

    # Set up the networks
    $networks = hiera('network::networks', [ ])
    $vlan_interface = hiera('network::vlan_interface', 'bond0')

    each($networks) | $cidr, $params | {

      nova::network::setup {
        $cidr:
          vlan    => $networks[$cidr]['vlan'],
          gateway   => $networks[$cidr]['gateway'],
          hardware_router => $networks[$cidr]['hardware_router'],
          vlan_interface  => $vlan_interface,
          dns1    => $networks[$cidr]['dns1'],
          dns2    => $networks[$cidr]['dns2'],
          reserved_ips  => $networks[$cidr]['reserved_ips'],
          host => $networks[$cidr]['host'],
          require   => Class['nova::api']
      }
    }
  }

  $dsrvip = hiera('dsrvip', '')

  if $dsrvip != '' {
    l23network::l3::ifconfig { "dsrvip_${dsrvip}":
      interface => 'dummy0',
      ipaddr => $dsrvip,
      netmask => '255.255.255.255',
    }
  }

}
