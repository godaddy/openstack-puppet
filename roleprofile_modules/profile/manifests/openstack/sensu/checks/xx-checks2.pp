class profile::openstack::sensu::checks::xxxx2 {

  # Common checks
  sensu::check {'cron_check':
    command     => '/etc/sensu/plugins/check-procs.rb -p crond -C 1',
    subscribers => 'sensu-test',
    require     => File['check-procs.rb'],
  }

#  # OpenStack checks
#  realize(File[
#    'check-haproxy.rb',
#    'haproxy-metrics.rb',
#    'check_ceilometer-agent-central.sh',
#    'check_ceilometer-agent-compute.sh',
#    'check_ceilometer-api.sh',
#    'check_ceilometer-collector.sh',
#    'check_keystone-api.sh',
#    'keystone-token-metrics.rb',
#    'neutron-agent-status.py'])
#
#  sensu::check {'check_haproxy':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check-haproxy.rb',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check-haproxy.rb'],
#  }
#
#  sensu::check {'check_haproxy_metrics':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/haproxy-metrics.rb',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['haproxy-metrics.rb'],
#  }
#
#  sensu::check {'check_ceilometer_agent_central':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check_ceilometer-agent-central.sh',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check_ceilometer-agent-central.sh'],
#  }
#
#  sensu::check {'check_ceilometer_agent_compute':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check_ceilometer-agent-compute.sh',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check_ceilometer-agent-compute.sh'],
#  }
#
#  sensu::check {'check_ceilometer_api':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check_ceilometer-api.sh',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check_ceilometer-api.sh'],
#  }
#
#  sensu::check {'check_ceilometer_collector':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check_ceilometer-collector.sh',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check_ceilometer-collector.sh'],
#  }
#
#  sensu::check {'check_keystone_api':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/check_keystone-api.sh',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['check_keystone-api.sh'],
#  }
#
#  sensu::check {'check_keystone_token_metrics':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/keystone-token-metrics.rb',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['keystone-token-metrics.rb'],
#  }
#
#  sensu::check {'check_neutron_agent_status':
#    type        => 'pipe',
#    command     => '/etc/sensu/plugins/neutron-agent-status.py',
#    handlers    => [ 'default', 'mailer' ],
#    subscribers => 'sensu-test',
#    interval    => 60,
#    require     => File['neutron-agent-status.py'],
#  }

}

