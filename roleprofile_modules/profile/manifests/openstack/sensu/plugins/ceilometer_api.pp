class profile::openstack::sensu::plugins::ceilometer_api {

  include profile::openstack::sensu::plugins::common
  include profile::openstack::sensu::plugins::corosync

 file {'check_ceilometer-api.sh':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_ceilometer-api.sh',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-api.sh',
    require => [ Package['sensu'] ],
  }

}
