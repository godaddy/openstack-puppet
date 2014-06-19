class profile::openstack::sensu::plugins::keystone {

  include profile::openstack::sensu::plugins::common
  include profile::openstack::sensu::plugins::haproxy

  file {'check_keystone-api.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_keystone-api.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/other-sensu-plugins/check_keystone-api.rb',
    require => [ Package['sensu'] ],
  }

  file {'keystone-token-metrics.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/keystone-token-metrics.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/keystone/keystone-token-metrics.rb',
    require => [ Package['sensu'], Exec['install-rubygem-mysql2'] ],
  }

}
