class profile::openstack::novabase inherits profile::base {

  $rabbit_ssl = hiera('message::ssl', false)

  if hiera('role') == 'role::openstack::compute' {

    # Glance config.  Support special situations where the compute nodes hit the glance
    # servers directly, through a list of URLs, rather than the published API endpoint
    $glance_protocol = hiera('image::real_servers::ssl', '') ? { false => "http", default => "https" }

    # Look for custom glance "real servers", and if not specified, then just hit the regular internal address for glance
    # Prefix each with the appropriate protocol, and join the array to generate a url list string
    $glance_internal_address = hiera('image::internal_address')
    $glance_servers = join(sort(suffix(prefix(keys(hiera('image::real_servers', { "${glance_internal_address}" => '' })), "${glance_protocol}://"), ":9292")), ',')

  } else {

    $glance_protocol = hiera('image::ssl_cert', false) ? { false => "http", default => "https" }
    $glance_address = hiera('image::internal_address')
    $glance_servers = "${glance_protocol}://${glance_address}:9292"

  }

  class {
    'nova':
      verbose             => hiera('api::verbose', false),
      sql_connection      => hiera('api::sql_connection'),
      sql_idle_timeout    => hiera('sql_timeout', '120'), 
      rabbit_hosts        => [ hiera('message::vip') ],
      rabbit_userid       => hiera('message::username'),
      rabbit_password     => hiera('message::password'),
      rabbit_ssl          => $rabbit_ssl,
      rabbit_port         => $rabbit_ssl ? { true => '5671', default => '5672' },
      image_service       => hiera('api::image_service'),
      glance_api_servers  => $glance_servers,      
      glance_api_insecure => hiera('ssl_no_verify', false),
      glance_protocol     => $glance_protocol,
      memcached_servers   => hiera('api::cache_servers'),
  }

  file_line { 'nova_sudoers':
    path    => '/etc/sudoers',
    match   => '^nova ALL = \(root\) NOPASSWD: /usr/bin/nova-rootwrap /etc/nova/rootwrap.conf \*$',
    line    => "nova ALL = (root) NOPASSWD: /usr/bin/nova-rootwrap /etc/nova/rootwrap.conf *",
  }

  # HA rabbitmq settings (http://docs.openstack.org/high-availability-guide/content/_configure_openstack_services_to_use_rabbitmq.html)
  nova_config {
    'DEFAULT/rabbit_retry_interval':   value => 1;
    'DEFAULT/rabbit_retry_backoff':    value => 2;
    'DEFAULT/rabbit_max_retries':      value => 0;
    'DEFAULT/rabbit_host':             ensure => absent;
  }

  # DB pools
  nova_config {
    'database/min_pool_size':       value => hiera('api::sql_min_pool_size', 5);
    'database/max_pool_size':       value => hiera('api::sql_max_pool_size', 40);
    'database/max_overflow':        value => hiera('api::sql_max_overflow', 20);
    'database/max_retries':         value => hiera('api::sql_max_retries', -1);
  }

  if hiera('network::provider') == 'neutron' {

    # Neutron networking

    $keystone_protocol = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
    $keystone_host = hiera('identity::keystone_host')
    $neutron_protocol = hiera('network::neutron::ssl_cert', '') ? { '' => 'http', default => 'https' }
    $neutron_host = hiera('network::neutron::internal_address')

    nova_config {
      'DEFAULT/network_api_class': value => 'nova.network.neutronv2.api.API';
      'DEFAULT/neutron_url': value => "${neutron_protocol}://${neutron_host}:9696";
      'DEFAULT/neutron_auth_strategy': value => 'keystone';
      'DEFAULT/neutron_admin_tenant_name': value => hiera('network::neutron::tenant', 'services');
      'DEFAULT/neutron_admin_username': value => hiera('network::neutron::user');
      'DEFAULT/neutron_admin_password': value => hiera('network::neutron::password'), secret => true;
      'DEFAULT/neutron_admin_auth_url': value => "${keystone_protocol}://${keystone_host}:35357/v2.0";
      'DEFAULT/security_group_api': value => 'neutron';
      'DEFAULT/service_neutron_metadata_proxy': ensure => absent;
      'DEFAULT/neutron_metadata_proxy_shared_secret': ensure => absent;
      'DEFAULT/neutron_api_insecure': value => true;
    }

  }

}
