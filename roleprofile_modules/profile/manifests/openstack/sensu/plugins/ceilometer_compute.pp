class profile::openstack::sensu::plugins::ceilometer_compute {

  include profile::openstack::sensu::plugins::common

 file {'check_ceilometer-agent-compute.sh':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_ceilometer-agent-compute.sh',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-agent-compute.sh',
    require => [ Package['sensu'], File_line['check_ceilometer_agent_compute_sudoers'] ],
  }

  file_line {'check_ceilometer_agent_compute_sudoers':
    path    => '/etc/sudoers',
    match   => '^sensu  ALL=\(ALL\) NOPASSWD: /bin/netstat -epta$',
    line    => "sensu  ALL=(ALL) NOPASSWD: /bin/netstat -epta",
    require => Package['sensu'],
  }

}
