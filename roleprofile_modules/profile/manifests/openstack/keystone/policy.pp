# == Class: profile::openstack::keystone::policy
#
# This lays down the /etc/keystone/policy.json file, served as a flat file via
# Puppet.
#
# === Usage
#
#   include ::profile::openstack::keystone::policy
#
# === Authors
#
# Craig Jellick <cjellick@godaddy.com>
#
# === Copyright
#
# Copyright 2014 GoDaddy Operating Company, LLC
#
class profile::openstack::keystone::policy {

  file {'/etc/keystone/policy.json':
    ensure  => file,
    owner   => 'root',
    group   => 'keystone',
    mode    => '0440',
    source  => "puppet:///modules/profile/keystone-policy.json",
    require => Package['openstack-keystone'],
    notify  => Service['openstack-keystone'],
  }

}
