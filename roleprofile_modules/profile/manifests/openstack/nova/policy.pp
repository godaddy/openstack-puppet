# == Class: profile::openstack::nova::policy
#
# This lays down the /etc/nova/policy.json file, served as a flat file via
# Puppet.  Update the file located at:
#
# https://github.secureserver.net/cloudplatform/openstack-puppet/blob/master/modules/profile/files/nova-policy.json
#
# === Usage
#
#   include ::profile::openstack::nova::policy
#
# === Authors
#
# Christopher Eckhardt <ceckhardt@godaddy.com>
#
# === Copyright
#
# Copyright 2014 GoDaddy Operating Company, LLC
#
class profile::openstack::nova::policy {

  if hiera('image::custom_policy', true) {
    $snapshots = hiera('image::enable_snapshots', false) ? { true => 'snapshots', default => 'nosnapshots' }

    file {'/etc/nova/policy.json':
      ensure  => file,
      owner   => 'root',
      group   => 'nova',
      mode    => '0440',
      source  => "puppet:///modules/profile/nova-policy.json.${snapshots}",
      require => Package['openstack-nova-common'],
      notify  => Service['openstack-nova-api'],
    }
  }

}
