class profile::openstack::sensu::plugins::els_openstack_integrations {

  include profile::openstack::sensu::plugins::common

  file {'check-log.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/check-log.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/logging/check-log.rb',
    require => [ Package['sensu'], File['/var/cache/check-log'] ],
  }

  file { '/var/cache/check-log':
    ensure  => directory,
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0755',
  }

}
