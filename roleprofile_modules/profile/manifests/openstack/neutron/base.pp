class profile::openstack::neutron::base inherits profile::base {

  $rabbit_ssl = hiera('message::ssl', false)

  class { '::neutron':
    enabled => true,
    bind_host => hiera('network::neutron::bind_host', '0.0.0.0'),
    core_plugin => hiera('role') ? {
      'role::openstack::compute' => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
      'role::openstack::network' => 'neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2',
      default => 'neutron.plugins.ml2.plugin.Ml2Plugin'
    },
    service_plugins => [ 'neutron.services.l3_router.l3_router_plugin.L3RouterPlugin' ],
    rabbit_hosts => [ hiera('message::vip') ],
    rabbit_user => hiera('message::username'),
    rabbit_ssl => $rabbit_ssl,
    rabbit_port => $rabbit_ssl ? { true => '5671', default => '5672' },    
    rabbit_password => hiera('message::password'),
    verbose => hiera('network::neutron::verbose', false),
    debug => hiera('network::neutron::debug', false),
    dhcp_lease_duration => hiera('network::dhcp_lease_time'),
    base_mac => '',
    allow_overlapping_ips => true,
  }

	file_line { 'neutron_sudoers':
		path    => '/etc/sudoers',
		match   => '^neutron ALL = \(root\) NOPASSWD: /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf \*$',
		line    => "neutron ALL = (root) NOPASSWD: /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf *",
	}

  # HA rabbitmq settings (http://docs.openstack.org/high-availability-guide/content/_configure_openstack_services_to_use_rabbitmq.html)
  neutron_config {
    'DEFAULT/rabbit_retry_interval':   value => 1;
    'DEFAULT/rabbit_retry_backoff':    value => 2;
    'DEFAULT/rabbit_max_retries':      value => 0;
  }

  # DB pools
  neutron_config {
    'database/min_pool_size':       value => hiera('network::neutron::sql_min_pool_size', 5);
    'database/max_pool_size':       value => hiera('network::neutron::sql_max_pool_size', 40);
    'database/max_overflow':        value => hiera('network::neutron::sql_max_overflow', 20);
  }

}
