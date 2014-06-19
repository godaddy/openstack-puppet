class profile::openstack::identity inherits profile::base {

  include profile::openstack::keystone::policy

  $keystone_host = hiera('identity::keystone_host', '127.0.0.1')

  # Install certs
  $pki_cert = hiera('identity::token_pki_cert', '')
  $ssl_cert = hiera('identity::ssl_cert', '')
  $ssl_path = $::profile::sslcerts::path

  case $pki_cert {
    '': {
      $real_pki_cert = ''
      $real_pki_key = ''
      $pki_require = [ ]
    }
    default: {
      $real_pki_cert = "${ssl_path}/certs/${pki_cert}.crt"
      $real_pki_key = "${ssl_path}/private/${pki_cert}.key"
      realize Sslcert[$pki_cert]
      $pki_require = [ Sslcert[$pki_cert] ]
    }
  }

  case $ssl_cert {
    '': {
      $enable_ssl = false
      $real_ssl_cert = ''
      $real_ssl_key = ''
      $protocol = 'http'
      $ssl_require = [ ]
    }
    default: {
      $enable_ssl = true
      $real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
      $real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
      $protocol = 'https'
      realize Sslcert[$ssl_cert]
      $ssl_require = [ Sslcert[$ssl_cert] ]
    }
  }

  if $::profile::sslcerts::cacert_file != '' {
    realize Sslcert::Cacert['cacert']
    $ca_require = [ Sslcert::Cacert['cacert'] ]
  } else {
    $ca_require = [ ]
  }

  class {
    'keystone':
      verbose           => hiera('identity::keystone_verbose', false),
      debug             => hiera('identity::keystone_debug', false),
      catalog_type      => 'sql',
      admin_token       => hiera('identity::keystone_admin_token'),
      sql_connection    => hiera('identity::keystone_sql_connection'),
      token_provider    => hiera('identity::token_provider', 'keystone.token.providers.uuid.Provider'),
      token_expiration  => hiera('identity::token_expiration', 43200),
      pki_cert          => $real_pki_cert,
      pki_key           => $real_pki_key,
      pki_cacert        => $real_pki_cacert,
      enable_ssl        => $enable_ssl,
      ssl_certfile      => $real_ssl_cert,
      ssl_keyfile       => $real_ssl_key,
      ssl_ca_certs      => $::profile::sslcerts::cacert_file,
      ssl_ca_key        => '',
      ssl_cert_subject  => '',
      idle_timeout      => hiera('sql_timeout', '120'),
      admin_endpoint    => "${protocol}://${keystone_host}:35357/v2.0/",
      require           => [ $pki_require, $ssl_require, $ca_require ]
  }

  # LDAP Integration
  package { 'python-ldap':
    ensure => present,
    before => Class['keystone'],
  }

  keystone_config {
    'identity/driver':              value => 'keystone.identity.backends.ldap.Identity';
    'assignment/driver':            value => 'keystone.assignment.backends.sql.Assignment';
      
    'ldap/url':                     value => hiera('identity::keystone_ldap_url');
    'ldap/user':                    value => hiera('identity::keystone_ldap_user');
    'ldap/password':                value => hiera('identity::keystone_ldap_pass'), secret => true;
    'ldap/page_size':               value => '2000';
    'ldap/query_scope':             value => 'sub';
      
    'ldap/user_tree_dn':            value => hiera('identity::keystone_ldap_user_tree_dn');
    'ldap/user_filter':             value => '(&(objectClass=organizationalPerson)(!(objectClass=computer))) ';
    'ldap/user_objectclass':        value => 'organizationalPerson';
    'ldap/user_id_attribute':       value => 'sAMAccountName';
    'ldap/user_name_attribute':     value => 'sAMAccountName';
    'ldap/user_mail_attribute':     value => 'mail';
    'ldap/user_enabled_attribute':  value => 'userAccountControl';
    'ldap/user_enabled_mask':       value => '2';
    'ldap/user_enabled_default':    value => '512';
    'ldap/user_allow_create':       value => 'False';
    'ldap/user_allow_update':       value => ' False';
    'ldap/user_allow_delete':       value => 'False';
    'ldap/user_enabled_emulation':  value => 'False';   

    'ldap/group_tree_dn':           value => hiera('identity::keystone_ldap_group_tree_dn');
    'ldap/group_objectclass':       value => 'group';
    'ldap/group_id_attribute':      value => 'cn';
    'ldap/group_name_attribute':    value => 'name';
    'ldap/group_member_attribute':  value => 'member';
    'ldap/group_desc_attribute':    value => 'description';
    'ldap/group_allow_create':      value => 'False';
    'ldap/group_allow_update':      value => 'False';
    'ldap/group_allow_delete':      value => 'False';
  }

  # Keystone startup bombs without this
  keystone_config {
    'paste_deploy/config_file': value => 'keystone-paste.ini';
  }

  # Adds the admin credential to keystone.
  class {
    'keystone::roles::admin':
      admin   => hiera('identity::admin_user'),
      email   => '',
      password  => hiera('identity::admin_password'),
  }

  # Add the project admin role
  keystone_role { ['ProjectAdmin']:
    ensure => present,
  }

  # Installs the service user endpoint.
  class {
    'keystone::endpoint':
      public_url       => "${protocol}://${keystone_host}:5000",
      admin_url        => "${protocol}://${keystone_host}:35357",
      internal_url     => "${protocol}://${keystone_host}:5000",
      region           => hiera('region'),
  }

  # Creates the v3 Identity service
  $v3_service_name = "keystonev3" 
  keystone_service { $v3_service_name:
    ensure      => present,
    type        => 'identityv3',
    description => 'OpenStack Identity Service v3',
  }
 
  # Create the v3 Identity endpoint 
  $region = hiera('region')
  keystone_endpoint { "${region}/${v3_service_name}":
    ensure => present,
    public_url       => "${protocol}://${keystone_host}:5000/v3",
    admin_url        => "${protocol}://${keystone_host}:35357/v3",
    internal_url     => "${protocol}://${keystone_host}:5000/v3",
    region           => hiera('region'),
  }

  # Logrotate config for keystone logs
  file {
    '/etc/logrotate.d/openstack-keystone':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => template('profile/logrotate-keystone.erb'),
  }

  # Keystone token flush cron
  $token_flush_cron_enabled  = hiera('server::keystone_token_flush_cron_enabled', false)
  file {
    '/etc/cron.d/keystone_token_flush':
      ensure  => $token_flush_cron_enabled ? { true => 'present', default => 'absent' },
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('profile/keystone_token_flush_cron.erb'),
      require => Package['openstack-keystone'],
  }

}
