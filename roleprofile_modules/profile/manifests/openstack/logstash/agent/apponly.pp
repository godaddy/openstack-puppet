class profile::openstack::logstash::agent::apponly inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-apponly.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-apponly.conf.erb'),
    notify  => Service['logstash'],
  }

}

