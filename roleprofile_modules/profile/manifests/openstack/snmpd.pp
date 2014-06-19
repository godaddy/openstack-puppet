class profile::openstack::snmpd inherits profile::base {

  # Puppet hack to get around gd-net-snmp* stupidness
  package { 'net-snmp':
    ensure  => present,
    require => [ Package['gd-net-snmp-conf'], Package['gd-net-snmp-libs'] ],
  }

  package { [ 'gd-net-snmp-libs', 'gd-net-snmp-conf' ]:
    ensure => absent,
  }

  service { 'snmpd':
    ensure  => running,
    enable  => true,
    require => [ Package['net-snmp'], File['/etc/snmp/snmpd.conf'] ],
  }

  file { '/etc/snmp/snmpd.conf':
    content => template('profile/snmpd.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['net-snmp'],
    notify  => Service['snmpd'],
  }

  file_line {
    'snmpd_options':
      path    => "/etc/sysconfig/snmpd",
      match   => '^OPTIONS=.+$',
      line    => 'OPTIONS="-LS0-4d -Lf /dev/null -p /var/run/snmpd.pid"',
      notify  => Service['snmpd'],
      require => Package['net-snmp'],
  }

}
