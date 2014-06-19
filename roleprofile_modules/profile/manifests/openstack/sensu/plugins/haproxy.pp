class profile::openstack::sensu::plugins::haproxy {

  include profile::openstack::sensu::plugins::common

  file {'/var/run/haproxy.sock':
    group   => 'sensu',
    mode    => '0660',
    require => Service['haproxy'],
  }

  file {'check-haproxy.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/check-haproxy.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/haproxy/check-haproxy.rb',
    require => [ Package['sensu'], File['/var/run/haproxy.sock'] ],
  }



}
