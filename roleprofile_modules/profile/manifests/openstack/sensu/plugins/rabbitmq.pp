class profile::openstack::sensu::plugins::rabbitmq {

  include profile::openstack::sensu::plugins::common

  file {'rabbitmq-alive.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/rabbitmq-alive.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/rabbitmq/rabbitmq-alive.rb',
    require => [ Package['sensu'], Exec['install-rubygem-rest_client'] ],
  }

  file {'rabbitmq-amqp-alive.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/rabbitmq-amqp-alive.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/rabbitmq/rabbitmq-amqp-alive.rb',
    require => [ Package['sensu'], Exec['install-rubygem-rest_client'], Exec['install-rubygem-bunny'] ],
  }

  file {'check-rabbitmq-messages.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/check-rabbitmq-messages.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/rabbitmq/check-rabbitmq-messages.rb',
    require => [ Package['sensu'], Exec['install-rubygem-carrot-top'] ],
  }

  file {'rabbitmq-queue-metrics.rb':
    ensure  => file,
    path    => '/etc/sensu/plugins/rabbitmq-queue-metrics.rb',
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    source  => 'puppet:///modules/profile/sensu-community-plugins/plugins/rabbitmq/rabbitmq-queue-metrics.rb',
    require => [ Package['sensu'], Exec['install-rubygem-carrot-top'] ],
  }

}
