class profile::openstack::statsd {
  # https://github.secureserver.net/cloudplatform/statsd-puppet
  class {'::statsd':
    graphite_host => hiera('statsd::graphite_host', 'p3gen.graphs.int.godaddy.com'),
    graphite_port => hiera('statsd::graphite_port', 2003),
    statsd_port   => hiera('statsd::statsd_port', 8125),
    prefix        => hiera('statsd::prefix', 'cloud.openstack.dev'),
  }
}
