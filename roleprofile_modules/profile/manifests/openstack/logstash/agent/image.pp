class profile::openstack::logstash::agent::image inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-image.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-image.conf.erb'),
    notify  => Service['logstash'],
  }

}

