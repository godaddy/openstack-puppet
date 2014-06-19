class profile::openstack::elsopenstackintegrations inherits profile::base {

  $rabbit_hosts                  = hiera('message::vip')
  $rabbit_use_ssl                = hiera('message::ssl')
  $rabbit_user                   = hiera('message::username')
  $rabbit_password               = regsubst(hiera('message::password'), '%', '%%', 'G')
  $ldap_admin_dn                 = hiera('els::ldap_admin_dn')
  $ldap_admin_password           = regsubst(hiera('els::ldap_admin_pass'), '%', '%%', 'G')
  $ldap_server_urls              = hiera('els::ldap_server_urls')
  $ldap_server_ou                = hiera('els::ldap_server_ou')
  $cloud_admin_username          = hiera('identity::admin_user')
  $cloud_admin_password          = regsubst(hiera('identity::admin_password'), '%', '%%', 'G')
  $project_admin_username        = hiera('els::project_admin_username')
  $project_admin_password        = regsubst(hiera('els::project_admin_password'), '%', '%%', 'G')
  $spacewalk_admin_user          = hiera('els::spacewalk_scriptadmin_username')
  $spacewalk_admin_pass          = regsubst(hiera('els::spacewalk_scriptadmin_password'), '%', '%%', 'G')
  $spacewalk_url                 = hiera('els::spacewalk_url')
  $project_name_format           = hiera('els::project_name_format')
  $spacewalk_domain_suffixes     = hiera('els::spacewalk_domain_suffixes')
  $dns_user                      = hiera('els::dns_svc_user')
  $dns_pass                      = regsubst(hiera('els::dns_svc_pass'), '%', '%%', 'G')
  $dns_api_url                   = hiera('els::dns_api_url')
  $dns_timeout                   = hiera('els::dns_timeout')
  $windows_domain                = hiera('els::windows_domain')
  $linux_domain                  = hiera('els::linux_domain')
  $dns_feature_enabled           = hiera('els::dns_feature_enabled')
  $keystone_timeout              = hiera('els::keystone_timeout', 120)
  $keystone_protocol             = hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' }
  $keystone_host                 = hiera('identity::keystone_host')
  $keystone_url                  = "${keystone_protocol}://${keystone_host}:5000/v2.0"
  $cron_enabled                  = hiera('els::cron_enabled', false)
  $detailed_event_logger_enabled = hiera('els::detailed_event_logger_enabled', 'True')
  $delete_dns_entries_enabled    = hiera('els::delete_dns_entries_enabled', 'True')
  $reap_ldap_hostname_enabled    = hiera('els::reap_ldap_hostname_enabled', 'True')
  $reap_spacewalk_host_enabled   = hiera('els::reap_spacewalk_host_enabled', 'True')
  $info_event_logger_enabled     = hiera('els::info_event_logger_enabled', 'True')
  $create_dns_entries_enabled    = hiera('els::create_dns_entries_enabled', 'True')
  $check_ad_for_fqdn             = hiera('els::check_ad_for_fqdn')
  $neutron_url                   = hiera('els::neutron_url')

  # Derive RabbitMQ port from ssl setting
  $rabbit_port = $rabbit_use_ssl ? { true => 5671, default => 5672 }

  # Just use first RabbitMQ server
  if is_array($rabbit_hosts) {
    $rabbit_host = $rabbit_hosts[0]
  } else {
    $rabbit_host = $rabbit_hosts
  }

  package { 'els-openstack-integrations':
    ensure => present,
  }

  file { '/etc/els-openstack-integrations/els-openstack-integrations.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('profile/els-openstack-integrations.conf.erb'),
    require => Package['els-openstack-integrations'],
    notify  => Service['els-notifications-consumer'],
  }

  # Symlink logging config file
  file { '/etc/els-openstack-integrations/logging.conf':
    ensure => 'link',
    target => hiera('els::logging_config'),
    require => Package['els-openstack-integrations'],
    notify  => Service['els-notifications-consumer'],
  }

  file { '/etc/els-openstack-integrations/security_group_rules.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    source  => "puppet:///modules/profile/security_group_rules.yaml-${::world}",
    require => Package['els-openstack-integrations'],
  }

  service { 'els-notifications-consumer':
      ensure => running,
      enable => true,
      require => [ File['/etc/els-openstack-integrations/logging.conf'], File['/etc/els-openstack-integrations/els-openstack-integrations.conf'] ],
  }

  # Put user bootstrapping cron on this box?
  if hiera('server::user_bootstrap', '') != '' {
      file { '/etc/cron.d/els-user-bootstrap-sync':
        ensure  => $cron_enabled ? { true => 'present', default => 'absent' },
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('profile/els-user-bootstrap-sync.cron.erb'),
        require => Package['els-openstack-integrations'],
    }
  }
}
