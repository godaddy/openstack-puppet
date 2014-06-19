class profile::openstack::sensu::plugins::glance_api {

  include profile::openstack::sensu::plugins::common

  file {'check_glance':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_glance',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_glance',
    require => [ Package['sensu'] ],
  }

}
