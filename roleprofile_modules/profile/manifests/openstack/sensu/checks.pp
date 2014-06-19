class profile::openstack::sensu::checks {

  # Include all the different checks to get configured on the Sensu server

  # Global defaults for checks
  Sensu::Check {
    handlers    => [ 'default', 'mailer' ],
    interval    => 60,
    refresh     => 86400,
    standalone  => false,
  }

  include profile::openstack::sensu::checks::all

  include profile::openstack::sensu::checks::nova_api
  include profile::openstack::sensu::checks::nova_cert
  include profile::openstack::sensu::checks::nova_conductor
  include profile::openstack::sensu::checks::nova_consoleauth
  include profile::openstack::sensu::checks::nova_scheduler
  include profile::openstack::sensu::checks::nova_spicehtml5proxy
  include profile::openstack::sensu::checks::nova_api_metadata
  include profile::openstack::sensu::checks::nova_compute

  include profile::openstack::sensu::checks::horizon

  include profile::openstack::sensu::checks::keystone

  include profile::openstack::sensu::checks::glance_api
  include profile::openstack::sensu::checks::glance_registry

  include profile::openstack::sensu::checks::neutron_server
  include profile::openstack::sensu::checks::neutron_dhcp_agent
  include profile::openstack::sensu::checks::neutron_openvswitch_agent

  include profile::openstack::sensu::checks::ceilometer_alarm_evaluator
  include profile::openstack::sensu::checks::ceilometer_alarm_notifier
  include profile::openstack::sensu::checks::ceilometer_api
  include profile::openstack::sensu::checks::ceilometer_collector
  include profile::openstack::sensu::checks::ceilometer_compute

  include profile::openstack::sensu::checks::heat_api_cfn
  include profile::openstack::sensu::checks::heat_api_cloudwatch
  include profile::openstack::sensu::checks::heat_api

  include profile::openstack::sensu::checks::libvirtd

  include profile::openstack::sensu::checks::rabbitmq

  include profile::openstack::sensu::checks::els_openstack_integrations

}
