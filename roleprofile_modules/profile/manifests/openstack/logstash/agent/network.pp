class profile::openstack::logstash::agent::network inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-network.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-network.conf.erb'),
    notify  => Service['logstash'],
  }

}

