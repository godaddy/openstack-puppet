class profile::graph_puppet_run {
  class {'::graph_puppet_run':
    graphite_prefix => hiera('graph_puppet_run::prefix'),
    graphite_server => hiera('graph_puppet_run::server'),
    graphite_port   => hiera('graph_puppet_run::port'),
  }
}
