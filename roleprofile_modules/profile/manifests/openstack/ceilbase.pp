class profile::openstack::ceilbase inherits profile::base {

  $rabbit_ssl = hiera('message::ssl', false)

  class {
    'ceilometer':
      verbose         => hiera('metering::ceilometer_verbose', false),
      debug           => hiera('metering::ceilometer_debug', false),
      db_connection   => hiera('metering::db_connection'),
      db_idle_timeout => hiera('sql_timeout', '120'),
      rabbit_hosts    => [ hiera('message::vip') ],
      rabbit_user     => hiera('message::username'),
      rabbit_password => hiera('message::password'),
      rabbit_ssl      => $rabbit_ssl,
      rabbit_port     => $rabbit_ssl ? { true => '5671', default => '5672' },
      keystone_host   => hiera('identity::keystone_host'),
      keystone_proto  => hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
      tenant          => hiera('metering::tenant'),
      admin_user      => hiera('metering::user', 'ceilometer'),
      admin_password  => hiera('metering::password', 'ceilometer'),
      secret          => hiera('metering::secret'),
  }

  include ceilometer::client

  # HA rabbitmq settings (http://docs.openstack.org/high-availability-guide/content/_configure_openstack_services_to_use_rabbitmq.html)
  ceilometer_config {
    'DEFAULT/rabbit_retry_interval':   value => 1;
    'DEFAULT/rabbit_retry_backoff':    value => 2;
    'DEFAULT/rabbit_max_retries':      value => 0;
  }

}
