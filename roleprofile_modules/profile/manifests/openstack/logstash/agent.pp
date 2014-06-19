class profile::openstack::logstash::agent {

  $server_role = hiera('role')
  if $server_role != 'role::openstack::singlemonitor' and $server_role != 'role::openstack::logstash' {

    $mq_exchange   = hiera('logstash::mq_exchange', 'logstash-exchange')
    $mq_host       = hiera('logstash::mq_host')
    $mq_key        = hiera('logstash::mq_key', 'logstash-routing-key')
    $mq_pass       = hiera('logstash::mq_pass', 'logstash')
    $mq_user       = hiera('logstash::mq_user', 'logstash')
    $mq_vhost      = hiera('logstash::mq_vhost', '/logstash')
    $mq_debug      = hiera('logstash::mq_debug', false)

    $mq_port       = hiera('logstash::mq_port', 5672)
    $mq_ssl        = hiera('logstash::mq_ssl', false)

    class { 'logstash': }

    logstash::configfile {'input_rabbitmq':
      content => template(hiera('logstash::client::conf_template')),
      order   => 15,
    }

    file {[
      '/var/log/audit/audit.log',
      '/var/log/dmesg',
      '/var/log/messages',
      '/var/log/secure',
      '/var/log/yum.log'
    ]:
      ensure => file,
      owner  => 'root',
      group  => $::logstash::params::group,
      mode   => '0640',
    }

  }

  # Clear out any legacy logstash config from /etc/logstash
  exec { 'clear-old-logstash-conf':
    command => '/bin/rm -f /etc/logstash/*.conf',
    onlyif  => '/bin/ls /etc/logstash/*.conf',
    before  => Class['logstash'],
  }

  # Global logstash settings for sysconfig
  file_line { 'logstash-sysconfig-java-opts':
    path    => '/etc/sysconfig/logstash',
    match   => '^LOGSTASH_JAVA_OPTS=',
    line    => 'LOGSTASH_JAVA_OPTS="-Xms256m -Xmx512m"',
    before  => Class['logstash'],
  }

  file_line { 'logstash-sysconfig-path-conf':
    path    => '/etc/sysconfig/logstash',
    match   => '^LOGSTASH_PATH_CONF=',
    line    => 'LOGSTASH_PATH_CONF=/etc/logstash/conf.d',
    before  => Class['logstash'],
  }

}
