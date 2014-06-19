class profile::openstack::keystonebasicconfig inherits profile::base {

  # Provides a basline/dummy keystone.conf file so that the keystone_* resource types
  # will work on machines that are not running Keysotne locally

  if ! defined(Class['profile::openstack::identity']) {

    $keystone_host = hiera('identity::keystone_host', '127.0.0.1')

    # What protocol are we running?
    case hiera('identity::ssl_cert', '') {
      '': {
        $protocol = 'http'
      }
      default: {
        $protocol = 'https'
      }
    }

    file {
      '/etc/keystone':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    keystone_config {
      'DEFAULT/admin_token':    value => hiera('identity::keystone_admin_token'), secret => true;
      'DEFAULT/admin_endpoint': value => "${protocol}://${keystone_host}:35357/v2.0/";
    }

    File['/etc/keystone'] -> Keystone_config <||>

  }

}
