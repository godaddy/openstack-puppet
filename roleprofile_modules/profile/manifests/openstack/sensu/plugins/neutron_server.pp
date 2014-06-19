class profile::openstack::sensu::plugins::neutron_server {

  include profile::openstack::sensu::plugins::common

  file {'neutron-agent-status.py':
    ensure  => file,
    path    => '/etc/sensu/plugins/neutron-agent-status.py',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/neutron/neutron-agent-status.py',
    require => [ Package['sensu'] ],
  }

  file {'check_neutron-api.py':
    ensure  => file,
    path    => '/etc/sensu/plugins/check_neutron-api.py',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/neutron/check_neutron-api.py',
    require => [ Package['sensu'] ],
  }

}
