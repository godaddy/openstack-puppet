class profile::openstack::logstash::agent::glanceproxy inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-glanceproxy.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-glanceproxy.conf.erb'),
    notify  => Service['logstash'],
  }

}

