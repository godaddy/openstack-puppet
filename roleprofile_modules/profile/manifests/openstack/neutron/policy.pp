# == Class: profile::openstack::neutron::policy
#
# This lays down the /etc/neutron/policy.json file, served as a flat file via
# Puppet.  Update the file located at:
#
# https://github.secureserver.net/cloudplatform/openstack-puppet/blob/master/modules/profile/files/neutron-policy.json
#
# === Usage
#
#   include ::profile::openstack::neutron::policy
#
# === Authors
#
# Christopher Eckhardt <ceckhardt@godaddy.com>
#
# === Copyright
#
# Copyright 2014 GoDaddy Operating Company, LLC
#
class profile::openstack::neutron::policy {

  if hiera('network::neutron::custom_policy', true) {
    file {'/etc/neutron/policy.json':
      ensure  => file,
      owner   => 'root',
      group   => 'neutron',
      mode    => '0440',
      source  => 'puppet:///modules/profile/neutron-policy.json',
      require => Package['openstack-neutron'],
      notify  => Service['neutron-server'],
    }
  }

}
