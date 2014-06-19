class profile::openstack::sensu::plugins::nova_api {

  include profile::openstack::sensu::plugins::common

  file {'check_novaapi':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_novaapi',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_novaapi',
    require => [ Package['sensu'] ],
  }

  file {'check_nova_services':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_nova_services',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_nova_services',
    require => [ Package['sensu'] ],
  }

}
