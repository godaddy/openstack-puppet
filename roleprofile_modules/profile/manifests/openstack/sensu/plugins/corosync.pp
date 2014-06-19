class profile::openstack::sensu::plugins::corosync {

  include profile::openstack::sensu::plugins::common

  file {'check_crm':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_crm',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_crm',
    require => [ Package['sensu'], Package['perl-Nagios-Plugin'], File_line['check_crm_sudoers'] ],
  }

  file_line {'check_crm_sudoers':
    path    => '/etc/sudoers',
    match   => '^sensu  ALL=\(ALL\) NOPASSWD: /usr/sbin/crm_mon -1 -r -f$',
    line    => "sensu  ALL=(ALL) NOPASSWD: /usr/sbin/crm_mon -1 -r -f",
    require => Package['sensu'],
  }

}
