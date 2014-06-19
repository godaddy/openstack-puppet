class profile::r10k_setup {

  class { 'r10k':
    version => '1.2.1',
    sources => {
      'puppet' => {
        'remote'  => 'git@github.secureserver.net:cloudplatform/openstack-puppet.git',
        'basedir' => "${::settings::confdir}/environments",
        'prefix'  => false,
      },
      'hiera' => {
        'remote'  => 'git@github.secureserver.net:cloudplatform/openstack-hieradata.git',
        'basedir' => "${::settings::confdir}/hiera",
        'prefix'  => true,
      }
    },
    purgedirs => ["${::settings::confdir}/environments"],
    manage_modulepath => true,
    modulepath  => "${::settings::confdir}/environments/\$environment/modules:${::settings::confdir}/environments/\$environment/roleprofile_modules",
  }

  # Determine the appropriate $::world setting, and drop it in an external fact
  if $::world != undef {
    $the_world = $::world
  } else {
    $the_world = $::environment ? {
      'openstack-puppet-dev'      => 'dev',
      'openstack-puppet-test'     => 'test',
      'openstack-puppet-stage'    => 'stage',
      'openstack-puppet-prod'     => 'prod',
      'openstack-puppet-appfirst' => 'appfirst',
    }
  }

  file { '/etc/facter':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  file { '/etc/facter/facts.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/facter'],
  }

  file { '/etc/facter/facts.d/world.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/world.yaml.erb'),
    require => File['/etc/facter/facts.d'],
  }

  # Default puppet environment for this node (under the new r10k setup)
  if $::world != undef {
    $the_env = $::world ? {
      'dev'       => 'master',
      'test'      => 'master',
      'stage'     => 'prod',
      'prod'      => 'prod',
      'appfirst'  => 'prod',
      default     => 'prod',
    }
  } else {
    $the_env = $::environment ? {
      'openstack-puppet-dev'      => 'master',
      'openstack-puppet-test'     => 'master',
      'openstack-puppet-stage'    => 'prod',
      'openstack-puppet-prod'     => 'prod',
      'openstack-puppet-appfirst' => 'prod',
      default                     => 'prod',
    }
  }

  ini_setting { 'Default Puppet environment':
    ensure  => present,
    path    => "${::settings::confdir}/puppet.conf",
    section => "main",
    setting => "environment",
    value   => $the_env,
  }

}
