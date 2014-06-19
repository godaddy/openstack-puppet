class profile::openstack::logstash::agent::monrabbit inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-monrabbit.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-monrabbit.conf.erb'),
    notify  => Service['logstash'],
  }

}

