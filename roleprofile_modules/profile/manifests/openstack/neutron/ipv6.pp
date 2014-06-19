class profile::openstack::neutron::ipv6 inherits profile::base {

  # IPv6 stuff
  file { '/etc/modprobe.d/noipv6.conf':
    ensure => absent;
  }

  file_line {
    'networking_ipv6':
      line => 'NETWORKING_IPV6=yes',
      match => '^NETWORKING_IPV6=',
      path => '/etc/sysconfig/network';

    'ipv6init':
      line => 'IPV6INIT=yes',
      match => '^IPV6INIT=',
      path => '/etc/sysconfig/network';
  }

  exec {
    'check_ipv6_enabled':
      command => '/bin/ls /proc/sys/net/ipv6 1>/dev/null 2>&1',
      require => [ File_line['networking_ipv6'], File_line['ipv6init'], File['/etc/modprobe.d/noipv6.conf'] ],
  }

}
