class profile::openstack::sensu::plugins::ceilometer_collector {

  include profile::openstack::sensu::plugins::common

 file {'check_ceilometer-collector.sh':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_ceilometer-collector.sh',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-collector.sh',
    require => [ Package['sensu'], File_line['check_ceilometer_collector_sudoers'] ],
  }

  file_line {'check_ceilometer_collector_sudoers':
    path    => '/etc/sudoers',
    match   => '^sensu  ALL=\(ALL\) NOPASSWD: /bin/netstat -epta$',
    line    => "sensu  ALL=(ALL) NOPASSWD: /bin/netstat -epta",
    require => Package['sensu'],
  }

}
