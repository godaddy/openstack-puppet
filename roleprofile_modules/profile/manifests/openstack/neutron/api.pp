class profile::openstack::neutron::api inherits profile::base {

  include profile::openstack::neutron::base
  include profile::openstack::neutron::networks
  include profile::openstack::neutron::policy

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

  class { 'neutron::server':
    auth_host     => hiera('identity::keystone_host'),
    auth_protocol => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
    auth_user     => hiera('network::neutron::user'),
    auth_password => hiera('network::neutron::password'),
    auth_tenant   => hiera('network::neutron::tenant'),
    connection    => hiera('network::neutron::sql_connection'),
    idle_timeout  => hiera('sql_timeout', '120'), 
    max_retries   => hiera('network::neutron::sql_max_retries', -1),
    log_dir       => hiera('network::neutron::log_dir', '/var/log/neutron'),
    api_workers   => hiera('network::neturon::api_workers', 40),
    ssl_cert_file => $real_ssl_cert,
    ssl_key_file  => $real_ssl_key
  }

  neutron_plugin_ml2 {
    'securitygroup/firewall_driver': value => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver';
  }

  class { 'neutron::keystone::auth':
      auth_name         => hiera('network::neutron::user', 'neutron'),
      password          => undef,
      email             => '',
      public_address    => hiera('network::neutron::public_address'),
      admin_address     => hiera('network::neutron::admin_address'),
      internal_address  => hiera('network::neutron::internal_address'),
      public_protocol   => $protocol,
      admin_protocol    => $protocol,
      internal_protocol => $protocol,
      region            => hiera('region'),
  }

  class { 'neutron::quota':
      quota_port => hiera('network::neutron::quota::ports'),
      quota_security_group => hiera('network::neutron::quota::security_groups'),
      quota_security_group_rule => hiera('network::neutron::quota::security_group_rules')
  }

  # Actually create all the networks/subnets in Neutron
  $networks = hiera('network::networks')

  each($networks) | $netname, $netparams | {

    neutron_network { $netname:
      shared => true,
      provider_network_type => 'flat',
      provider_physical_network => $netname,
    }

    $subnets = $networks[$netname]['subnets']

    each($subnets) | $cidr, $cidrparams | {
      $underscored = regsubst($cidr, "[./]", '_', 'G')
      $vlan = $cidrparams['vlan']
      $label = $vlan ? { 0 => $underscored, default => "${underscored}_vlan${vlan}" }

      neutron_subnet { $label:
        network_name => $netname,
        cidr => $cidr,
        gateway_ip => $cidrparams['gateway'],
        allocation_pool_start => $cidrparams['start_ip'],
        allocation_pool_end => $cidrparams['end_ip'],
        dns_nameserver1 => $cidrparams['dns1'],
        dns_nameserver2 => $cidrparams['dns2'],
      }

    }

  }

}
