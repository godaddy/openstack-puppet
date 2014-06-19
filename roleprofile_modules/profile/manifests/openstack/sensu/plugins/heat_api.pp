class profile::openstack::sensu::plugins::heat_api {

  include profile::openstack::sensu::plugins::common
  include profile::openstack::sensu::plugins::corosync

  file {'check_heatapi':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_heatapi',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_heatapi',
    require => [ Package['sensu'] ],
  }

}
