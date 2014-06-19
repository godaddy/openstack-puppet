class profile::openstack::glanceproxy inherits profile::base {

  # HA Proxy global and default options
  include profile::openstack::haproxybase

  $ssl_cert = hiera('image::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_pem  = ''
      $require       = [ ]
    }
    default: {
      $real_ssl_pem = "${ssl_path}/private/${ssl_cert}.pem"
      realize Sslcert[$ssl_cert]
      $require = [ Sslcert[$ssl_cert] ]
    }
  }

  # Baseline LB config
  haproxy::listen {
    'glance-api':
      ipaddress         => '0.0.0.0',
      ports             => '9292',
      options           => { 'balance' => 'roundrobin' },
      bind_options      => [ 'ssl', "crt ${real_ssl_pem}" ],
      collect_exported  => false;

    'glance-registry':
      ipaddress         => '0.0.0.0',
      ports             => '9191',
      options           => { 'balance' => 'roundrobin' },
      bind_options      => [ 'ssl', "crt ${real_ssl_pem}" ],
      collect_exported  => false;
  }

  # Glance servers hash from hiera
  $glanceservers = hiera('image::real_servers')

  each($glanceservers) |$glancehost, $ip| {
    haproxy::balancermember {
      "${glancehost}-api":
        listening_service => 'glance-api',
        server_names      => $glancehost,
        ports             => '9292',
        ipaddresses       => $ip,
        options           => [ 'check', 'inter 10000',  'rise 2', 'fall 5' ];
    }

    haproxy::balancermember {
      "${glancehost}-registry":
        listening_service => 'glance-registry',
        server_names      => $glancehost,
        ports             => '9191',
        ipaddresses       => $ip,
        options           => [ 'check', 'inter 10000',  'rise 2', 'fall 5' ];
    }
  }


}
