class profile::openstack::sensu::plugins::common {

  # Packages, Gems, etc. needed by Sensu plugins
  exec {'install-rubygem-rest_client':
    command   => '/opt/sensu/embedded/bin/gem install rest_client',
    unless    => '/bin/ls /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/rest_client*',
    require   => Package['sensu'],
  }

  exec {'install-rubygem-carrot-top':
    command   => '/opt/sensu/embedded/bin/gem install carrot-top',
    unless    => '/bin/ls /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/carrot-top*',
    require   => [ Package['sensu'], Package['ruby-devel'] ],
  }

  exec {'install-rubygem-mysql2':
    command   => '/opt/sensu/embedded/bin/gem install mysql2',
    unless    => '/bin/ls /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/mysql2*',
    require   => [ Package['sensu'], Package['mysql-devel'], Package['gcc'] ],
  }

  exec {'install-rubygem-mail':
    command   => '/opt/sensu/embedded/bin/gem install mail -v 2.5.4',
    unless    => '/bin/ls /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/mail-2.5.4*',
    require   => [ Package['sensu'] ],
  }

  exec {'install-rubygem-bunny':
    command   => '/opt/sensu/embedded/bin/gem install bunny',
    unless    => '/bin/ls /opt/sensu/embedded/lib/ruby/gems/2.0.0/gems/bunny*',
    require   => [ Package['sensu'] ],
  }

  package { [ 'gcc', 'mysql-devel', 'perl-Nagios-Plugin' ]:
    ensure => present,
  }
  # Note: we get the ruby-devel package from the ruby module


  # Common plugins needed by all Sensu clients
  file {'check-procs.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-procs.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/processes/check-procs.rb',
  }

  file {'check-http.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-http.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/http/check-http.rb',
  }

  file {'check-cmd.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-cmd.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/processes/check-cmd.rb',
  }

  file {'/etc/sudoers.d/sensu_check_cmd':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => "Defaults !requiretty\nDefaults !visiblepw\nsensu ALL=(root) NOPASSWD: /etc/sensu/plugins/check-cmd.rb\n",
  }

  file {'check-disk.rb':
    ensure => file,
    path   => '/etc/sensu/plugins/check-disk.rb',
    owner  => 'sensu',
    group  => 'sensu',
    mode   => '0555',
    source => 'puppet:///modules/profile/sensu-community-plugins/plugins/system/check-disk.rb',
  }

}
