class profile::base {

  # r10k setup
  include profile::r10k_setup

  # hiera-eyaml setup
  include profile::hiera_eyaml_setup

  # Virtual ssl certs
  include profile::sslcerts

  # NTP config
  include profile::ntp

  # LogStash Agent
  include profile::openstack::logstash::agent

  # Sensu Client
  include profile::openstack::sensu::client

  # snmpd setup
  include profile::openstack::snmpd

  # TrendMicro DeepSecurity Agent (HIPS)
  class {'hips_client':
    policy       => hiera('hips_client::policy', 'GD_DEFAULT'),
    control_host => hiera('hips_client::control_host', 'hips.sec.secureserver.net'),
    control_port => hiera('hips_client::control_port', 4120),
    installed    => hiera('hips_client::installed', true),
  }

  # Enable management of /etc/sudoers.d
  file {'/etc/sudoers':
    ensure => file,
  } ->
  file_line {'enable_/etc/sudoers.d':
    line => "#includedir /etc/sudoers.d\n",
    path => '/etc/sudoers',
  }

  # Hosts entries
  class { 'profile::hosts':
    stage => pre,
  }

  # Announce our $::environment and $::word
  class { 'profile::announce_world_env':
    stage => pre,
  }

  # To deal with non-qualified exec commands in some modules
  Exec {
    path => "/bin:/sbin:/usr/bin:/usr/sbin"
  }

}
