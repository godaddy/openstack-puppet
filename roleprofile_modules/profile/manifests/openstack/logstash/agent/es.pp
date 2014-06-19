class profile::openstack::logstash::agent::es inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-es.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-es.conf.erb'),
    notify  => Service['logstash'],
  }

}

