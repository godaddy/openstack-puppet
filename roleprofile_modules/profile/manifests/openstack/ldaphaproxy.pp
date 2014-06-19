class profile::openstack::ldaphaproxy inherits profile::base {

  # HA Proxy global and default options
  include profile::openstack::haproxybase

  # Baseline LB config
  haproxy::listen {
    'ldaps':
      ipaddress => '127.0.0.1',
      ports     => '636',
      options   => { 'balance' => 'roundrobin' },
  }

  # LDAP servers hash from hiera
  $ldapservers = hiera('identity::ldap_servers')

  each($ldapservers) |$ldaphost, $ip| {
    haproxy::balancermember {
      $ldaphost:
        listening_service => 'ldaps',
        server_names      => $ldaphost,
        ports             => '636',
        ipaddresses       => $ip,
        options           => [ 'check', 'inter 10000',  'rise 2', 'fall 5' ],
    }
  }

  # Disable cert validation
  file_line {
    'openldap-conf-TLS_REQCERT':
      line => "TLS_REQCERT never",
      match => "^TLS_REQCERT.+$",
      path => "/etc/openldap/ldap.conf",
      notify  => [ Service['openstack-keystone'], Service['nova-api'], Service['els-notifications-consumer'] ],
  }

}
