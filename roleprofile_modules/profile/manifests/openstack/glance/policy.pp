# == Class: profile::openstack::glance::policy
#
# This lays down the /etc/glance/policy.json file, served as a flat file via
# Puppet.  Update the file located at:
#
# https://github.secureserver.net/cloudplatform/openstack-puppet/blob/master/modules/profile/files/glance-policy.json
#
# === Usage
#
#   include ::profile::openstack::glance::policy
#
# === Authors
#
# Christopher Eckhardt <ceckhardt@godaddy.com>
#
# === Copyright
#
# Copyright 2014 GoDaddy Operating Company, LLC
#
class profile::openstack::glance::policy {

  if hiera('image::custom_policy', true) {
    $snapshots = hiera('image::enable_snapshots', false) ? { true => 'snapshots', default => 'nosnapshots' }

    file {'/etc/glance/policy.json':
      ensure  => file,
      owner   => 'root',
      group   => 'glance',
      mode    => '0440',
      source  => "puppet:///modules/profile/glance-policy.json.${snapshots}",
      require => Package['openstack-glance'],
      notify  => Service['openstack-glance-api'],
    }
  }

}
