class profile::openstack::logstash::agent::compute inherits profile::openstack::logstash::agent {

  file { '/etc/logstash/conf.d/logstash-compute.conf':
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0640',
    content => template('profile/logstash-compute.conf.erb'),
    notify  => Service['logstash'],
  }

  file { '/var/log/libvirt':
    ensure  => directory,
    mode    => '0755',
    require => Package['libvirt'],
  }

  file { '/var/log/libvirt/libvirtd.log':
    ensure  => present,
    mode    => '0644',
    require => Package['libvirt'],
  }

}

