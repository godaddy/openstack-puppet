class profile::openstack::sensu::plugins::xxxx {

  # Plugins needed for for nova api checks



  # Common Plugins
  @file {'check-procs.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-procs.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/processes/check-procs.rb',
  }

  @file {'check-cmd.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-cmd.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/processes/check-cmd.rb',
  }

  # HAProxy Plugins
  @file {'check-haproxy.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-haproxy.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/haproxy/check-haproxy.rb',
  }

  @file {'haproxy-metrics.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/haproxy-metrics.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/haproxy/haproxy-metrics.rb',
  }

  # OpenStack Community Plugins
  @file {'check_ceilometer-agent-central.sh':
    ensure => file,
    path   => '/etc/sensu/plugins/check_ceilometer-agent-central.sh',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-agent-central.sh',
  }

  @file {'check_ceilometer-agent-compute.sh':
    ensure => file,
    path   => '/etc/sensu/plugins/check_ceilometer-agent-compute.sh',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-agent-compute.sh',
  }

  @file {'check_ceilometer-api.sh':
    ensure => file,
    path   => '/etc/sensu/plugins/check_ceilometer-api.sh',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-api.sh',
  }

  @file {'check_ceilometer-collector.sh':
    ensure => file,
    path   => '/etc/sensu/plugins/check_ceilometer-collector.sh',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/ceilometer/check_ceilometer-collector.sh',
  }

  @file {'check_keystone-api.sh':
    ensure => file,
    path   => '/etc/sensu/plugins/check_keystone-api.sh',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/keystone/check_keystone-api.sh',
  }

  @file {'keystone-token-metrics.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/keystone-token-metrics.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/keystone/keystone-token-metrics.rb',
  }

  @file {'neutron-agent-status.py':
    ensure => file,
    path   => '/etc/sensu/plugins/neutron-agent-status.py',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/openstack/neutron/neutron-agent-status.py',
  }
}
