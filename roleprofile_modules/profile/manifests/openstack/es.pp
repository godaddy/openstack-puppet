class profile::openstack::es inherits profile::base {

  $region = hiera('region', '')
  $env    = $::world

  $bloom_disable_after_days = hiera('elasticsearch::curator::bloom_disable_after_days', 2)
  $delete_after_days        = hiera('elasticsearch::curator::delete_after_days', 30)

  # Java heap size for ES is half the physical memory, rounded up to the next nearest GB
  $es_heap_size = floor(regsubst($memorysize, '^([\d\.]+) GB$', '\1') / 2 + 1)

  # Install certs
  $ssl_cert = hiera('elasticsearch::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $ssl_cert {
    '': {
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $ssl_require = [ ]
    }
    default: {
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      realize Sslcert[$ssl_cert]
      $ssl_require = [ Sslcert[$ssl_cert] ]
    }
  }

  if $::profile::sslcerts::cacert_file != '' {
    realize Sslcert::Cacert['cacert']
    $real_ca_cert = $::profile::sslcerts::cacert_file
    $ca_require = [ Sslcert::Cacert['cacert'] ]
  } else {
    $ca_require = [ ]
  }


  if ! defined(Package['jdk']) {
    package {'jdk':
      ensure => present,
      before => Class['elasticsearch'],
    }
  }

  class {'elasticsearch':
    config => {
      'cluster' => { 'name' => hiera('elasticsearch::cluster', 'openstack-p3gen-elasticsearch')
      },
      'node'    => { 'name' => $::hostname },
      'index'   => {
        'number_of_replicas' => hiera('elasticsearch::number_of_replicas', '2'),
        'number_of_shards'   => hiera('elasticsearch::number_of_shards', '2'),
      },
      'script.disable_dynamic'  => 'true',
    }
  }

  file {'95-elasticsearch.conf':
    ensure  => file,
    path    => '/etc/security/limits.d/95-elasticsearch.conf',
    owner   => 'root',
    group   => 'root',
    content => "elasticsearch        -       nofiles       66000\nelasticsearch        -       memlock       -1\n",
    notify  => Service['elasticsearch'],
    require => Package['elasticsearch'],
  }

  file_line {
    "elasticsearch-sysconfig-heap-size":
      line => "ES_HEAP_SIZE=${es_heap_size}g",
      match => "^ES_HEAP_SIZE=.+$",
      path => "/etc/sysconfig/elasticsearch",
      require => Class['elasticsearch'],
  }

  $log_site = hiera('elasticsearch::site_name', 'logs.cloud.int.godaddy.com')

  class {'apache':
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
  }

  class {'kibana':
    es_url => hiera('elasticsearch::es_url', "http://${::ipaddress}:9200"),
    default_route => hiera('elasticsearch::kibana_dashboard', '/dashboard/file/openstack.json'),
  }

  file { '/opt/kibana/app/dashboards/openstack.json':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/kibana-dashboard-openstack-logs.json.erb'),
    require => Class['kibana'],
  }

  include ::apache::mod::auth_basic
  include ::apache::mod::dir
  include ::apache::mod::mime
  include ::apache::mod::proxy
  include ::apache::mod::proxy_http
  include ::apache::mod::ssl

  apache::mod { 'authnz_external':
    require => [
      Package['pwauth'],
      Package['mod_authnz_external'],
    ]
  }

  # mod_authz_unixgroup package should be in Spacewalk - ceckhardt 2/25/2014
  # http://code.google.com/p/mod-auth-external/wiki/ModAuthzUnixGroup
  apache::mod { 'authz_unixgroup':
      require => Package['mod_authz_unixgroup'],
  }

  $auth = '
    AuthType Basic
    AuthName "OpenStack ElasticSearch Cluster"
    AuthBasicProvider external
    AuthExternal pwauth
    AuthzUnixgroup on
    Require group ac_englinux ac_devcloud ac_engplat'

  package { 'pwauth':
    ensure => present
  }

  package { 'mod_authnz_external':
    ensure => present
  }

  package { 'mod_authz_unixgroup':
    ensure => present
  }

  apache::vhost {$log_site:
    port     => '80',
    docroot  => '/opt/kibana',
    rewrites => [
      {
        comment      => '# Enforce HTTPS',
        rewrite_cond => ['%{HTTPS} off'],
        rewrite_rule => ['(.*) https://%{HTTP_HOST}%{REQUEST_URI}'],
      },
    ],
  }

  apache::vhost {"${log_site} ssl":
    port            => '443',
    docroot         => '/opt/kibana',
    servername      => $log_site,
    ssl             => true,
    ssl_cert        => $real_ssl_cert,
    ssl_key         => $real_ssl_key,
    ssl_chain       => $real_ca_cert,
    directories     => [
      {
        provider        => 'location',
        path            => '/',
        custom_fragment => $auth
      },
      {
        path           => '/opt/kibana',
        options        => ['Indexes', 'FollowSymLinks', 'MultiViews'],
        allow_override => ['None'],
        order          => 'Allow,Deny',
        allow          => 'from all',
      },
    ],
    custom_fragment => '  DefineExternalAuth pwauth pipe /usr/bin/pwauth',
    require         => [ $ssl_require, $ca_require ]
  }

  # ES Curator stuff
  package {
    'python-pip':
      ensure => present,
  }

  package {
    'elasticsearch-curator':
      ensure    => present,
      provider  => 'pip',
      require   => Package['python-pip'],
  }

  file {
    '/etc/cron.d/elasticsearch-curator':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/elasticsearch-curator.cron.erb'),
      require => Package['elasticsearch-curator'],
  }

  $dsrvip = hiera('elasticsearch::vip', '')

  if $dsrvip != '' {
    l23network::l3::ifconfig { "dsrvip_${dsrvip}":
      interface => 'dummy0',
      ipaddr => $dsrvip,
      netmask => '255.255.255.255',
    }
  }

}
