class profile::openstack::cache inherits profile::base {

  class { 'memcached':
    udp_port  => '11211'
  }

  package { 'python-memcached':
    ensure => present
  }

}
