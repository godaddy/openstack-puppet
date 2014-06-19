class profile::openstack::image inherits profile::base {

  include profile::openstack::keystonebasicconfig
  include profile::openstack::glance::policy

  $ssl_cert = hiera('image::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  if hiera('image::real_servers::ssl', '') == false or $ssl_cert == '' {
    $real_ssl_cert = ''
    $real_ssl_key  = ''
    $protocol      = 'http'
    $require       = [ ]
  } else {
    $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
    $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
    $protocol = 'https'
    realize Sslcert[$ssl_cert]
    $require = [ Sslcert[$ssl_cert] ]
  }

  class {
    'glance::api':
      verbose           => hiera('image::verbose', false),
      debug             => hiera('image::debug', false),
      keystone_tenant   => hiera('image::tenant'),
      keystone_user     => hiera('image::user'),
      keystone_password => hiera('image::password'),
      sql_connection    => hiera('image::sql_connection'),
      sql_idle_timeout  => hiera('sql_timeout', '120'),
      auth_host         => hiera('identity::keystone_host'),
      auth_protocol     => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
      registry_host     => hiera('image::public_address'),
      registry_protocol => $ssl_cert ? { '' => 'http', default => 'https' },
      registry_insecure => hiera('ssl_no_verify', false),
      ssl_cert          => $real_ssl_cert,
      ssl_key           => $real_ssl_key,
      workers           => hiera('image::api_workers', 40),
      require           => $require
  }

  class {
    'glance::registry':
      verbose           => hiera('image::verbose', false),
      debug             => hiera('image::debug', false),
      keystone_tenant   => hiera('image::tenant'),
      keystone_user     => hiera('image::user'),
      keystone_password => hiera('image::password'),
      sql_connection    => hiera('image::sql_connection'),
      sql_idle_timeout  => hiera('sql_timeout', '120'),
      auth_host         => hiera('identity::keystone_host'),
      auth_protocol     => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
      ssl_cert          => $real_ssl_cert,
      ssl_key           => $real_ssl_key,
      require           => $require
  }

  class {
    'glance::backend::file':
  }

  class {
    'glance::keystone::auth':
      auth_name         => hiera('image::user', 'glance'),
      password          => undef,
      email             => '',
      public_address    => hiera('image::public_address'),
      admin_address     => hiera('image::admin_address'),
      internal_address  => hiera('image::internal_address'),
      public_protocol   => $ssl_cert ? { '' => 'http', default => 'https' },
      admin_protocol    => $ssl_cert ? { '' => 'http', default => 'https' },
      internal_protocol => $ssl_cert ? { '' => 'http', default => 'https' },
      region            => hiera('region'),
  }

  # HA rabbitmq settings (http://docs.openstack.org/high-availability-guide/content/_configure_openstack_services_to_use_rabbitmq.html)
  glance_api_config {
    'DEFAULT/rabbit_retry_interval':   value => 1;
    'DEFAULT/rabbit_retry_backoff':    value => 2;
    'DEFAULT/rabbit_max_retries':      value => 0;
  }

  glance_api_config {
    'DEFAULT/known_stores':     value => 'glance.store.filesystem.Store, glance.store.http.Store';
  }

  glance_registry_config {
    'DEFAULT/default_store':    value => 'file';
    'DEFAULT/known_stores':     value => 'glance.store.filesystem.Store, glance.store.http.Store';
  }

}
