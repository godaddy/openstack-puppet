class profile::openstack::logstash::agent::sensu inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-sensu.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-sensu.conf.erb'),
    notify  => Service['logstash'],
  }

}

