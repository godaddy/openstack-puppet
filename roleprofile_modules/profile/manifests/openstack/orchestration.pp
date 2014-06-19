class profile::openstack::orchestration inherits profile::base {

  include profile::openstack::cluster

  $ssl_cert = hiera('orchestration::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path
  $rabbit_ssl = hiera('message::ssl', false)

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

  class {
    'heat::api':
      verbose           => hiera('orchestration::heat_verbose', false),
      debug             => hiera('orchestration::heat_debug', false),
      sql_connection    => hiera('orchestration::sql_connection'),
      sql_idle_timeout  => hiera('sql_timeout', '120'),
      keystone_host     => hiera('identity::keystone_host'),
      keystone_proto    => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
      tenant            => hiera('orchestration::tenant', 'services'),
      admin_user        => hiera('orchestration::user', 'heat'),
      admin_password    => hiera('orchestration::password', 'heat'),
      rabbit_hosts      => [ hiera('message::vip') ],
      rabbit_user       => hiera('message::username'),
      rabbit_password   => hiera('message::password'),
      rabbit_ssl        => $rabbit_ssl,
      rabbit_port       => $rabbit_ssl ? { true => '5671', default => '5672' },
      heat_host         => hiera('orchestration::public_address'),      
      cert_file         => $real_ssl_cert,
      key_file          => $real_ssl_key,
      require           => $require,
      start_clustered_services => false,
  }

  class {
    'heat::api::cfn':
      cert_file => $real_ssl_cert,
      key_file  => $real_ssl_key
  }

  class {
    'heat::api::cloudwatch':
      cloudwatch_host => hiera('orchestration::public_address'),
      cert_file => $real_ssl_cert,
      key_file  => $real_ssl_key
  }

  include heat::client

  class {
    'heat::keystone::auth':
      auth_name        => hiera('orchestration::user', 'heat'),
      #password         => hiera('orchestration::password', 'heat'),
      password         => undef,
      email            => '',
      public_address   => hiera('orchestration::public_address'),
      admin_address    => hiera('orchestration::admin_address'),
      internal_address => hiera('orchestration::internal_address'),
      public_protocol  => $protocol,
      admin_protocol  => $protocol,
      internal_protocol  => $protocol,
      region           => hiera('region'),
  }

  class {
    'heat::keystone::service::cfn':
      public_address   => hiera('orchestration::cfn_public_address'),
      admin_address    => hiera('orchestration::cfn_admin_address'),
      internal_address => hiera('orchestration::cfn_internal_address'),
      public_protocol  => $protocol,
      admin_protocol  => $protocol,
      internal_protocol  => $protocol,
      region           => hiera('region'),
  }

  # Pacemaker resource for heat engine service
  corosync::resource::heat_engine {
    'p_heat_engine':
      amqp_server_port => $rabbit_ssl ? { true => '5671', default => '5672' },
      require => Class['heat::api'],
  }

  # Logrotate config for heat logs
  file {
    '/etc/logrotate.d/openstack-heat':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('profile/logrotate-heat.erb'),
  }

  # HA rabbitmq settings (http://docs.openstack.org/high-availability-guide/content/_configure_openstack_services_to_use_rabbitmq.html)
  heat_config {
    'DEFAULT/rabbit_retry_interval':   value => 1;
    'DEFAULT/rabbit_retry_backoff':    value => 2;
    'DEFAULT/rabbit_max_retries':      value => 0;
  }

}
