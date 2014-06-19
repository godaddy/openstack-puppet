class role {
  include profile::base
  include profile::graph_puppet_run
  include profile::openstack::collectd
  include profile::openstack::sensu::client
  include profile::openstack::statsd
}


class role::openstack::apponly inherits role {
  include profile::openstack::identity
  include profile::openstack::cache
  include profile::openstack::novabase
  include profile::openstack::api
  include profile::openstack::orchestration
  include profile::openstack::metering
  include profile::openstack::ldaphaproxy

  if hiera('network::provider') == 'neutron' {
    include profile::openstack::neutron::api
  }

  # Logstash setup
  include profile::openstack::logstash::agent::apponly

  # App servers also host Horizon, for now
  include role::openstack::webui

  # App servers also host RabbitMQ for now
  include role::openstack::message
}


class role::openstack::image inherits role {
  include profile::openstack::image

  # Logstash setup
  include profile::openstack::logstash::agent::image
}


class role::openstack::app inherits role {
  include role::openstack::apponly
  include role::openstack::image
}


class role::openstack::appglanceproxy inherits role {
  include role::openstack::apponly
  include profile::openstack::glanceproxy

  # Logstash setup
  include profile::openstack::logstash::agent::glanceproxy
}


class role::openstack::compute inherits role {
  include profile::openstack::novabase
  include profile::openstack::compute

  # Logstash setup
  include profile::openstack::logstash::agent::compute
}


class role::openstack::network inherits role {
  if hiera('network::provider') == 'neutron' {
    include profile::openstack::neutron::networknode
  } else {
    # Nova networking
    include profile::openstack::network
  }

  include profile::openstack::novabase
  include profile::openstack::metadata

  # Logstash setup
  include profile::openstack::logstash::agent::network
}


class role::openstack::networkglance inherits role {
  include role::openstack::network
  include role::openstack::image
}


class role::openstack::message inherits role {
  include profile::openstack::message
}


class role::openstack::webui inherits role {
  include profile::openstack::dashboard
  include profile::openstack::cache
}

class role::openstack::haproxy::dev inherits role {}
class role::openstack::haproxy::test inherits role {}
class role::openstack::haproxy::stage inherits role {}

class role::openstack::monrabbit inherits role {
  include profile::openstack::monrabbit

  # Logstash setup
  include profile::openstack::logstash::agent::monrabbit
}

class role::openstack::logstash inherits role {
  include profile::openstack::logstash::indexer
}

class role::openstack::elasticsearch inherits role {
  include profile::openstack::es

  # Logstash setup
  include profile::openstack::logstash::agent::es
}

class role::openstack::sensu inherits role {
  include profile::openstack::sensu::server

  # Logstash setup
  include profile::openstack::logstash::agent::sensu
}

class role::openstack::singlemonitor inherits role {
  include role::openstack::monrabbit
  include role::openstack::logstash
  include role::openstack::elasticsearch
  include role::openstack::sensu
}

