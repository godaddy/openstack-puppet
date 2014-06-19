class profile::openstack::metering inherits profile::base {

  require profile::openstack::ceilbase
  require profile::openstack::cluster

  class {
    'ceilometer::api':
      start_clustered_services => false,
  }

  class {
    'ceilometer::keystone::auth':
      auth_name        => hiera('metering::user', 'ceilometer'),
      password         => undef,
      email            => '',
      public_address   => hiera('metering::public_address'),
      admin_address    => hiera('metering::admin_address'),
      internal_address => hiera('metering::internal_address'),
      region           => hiera('region'),
  }


  # Pacemaker resource for ceilometer cluster service
  $rabbit_ssl = hiera('message::ssl', false)
  corosync::resource::ceilometer_central {
    'p_ceilometer_central':
      amqp_server_port => $rabbit_ssl ? { true => '5671', default => '5672' },
      require => Class['ceilometer::api'],
  }

}
