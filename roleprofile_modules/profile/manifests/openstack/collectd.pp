# == Class: profile::openstack::collectd
#  Profile definition for Collectd installations on OpenStack nodes
#
# === Actions
#  Configures and runs collectd for Graphite stats visualization
#
# === Usage
#  include ::profile::openstack::collectd
class profile::openstack::collectd {

  class {'::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
    interval     => hiera('collectd::interval'),
  }

  class {'::collectd::plugin::write_graphite':
    graphitehost   => hiera('collectd::plugin::write_graphite::graphitehost'),
    graphiteport   => hiera('collectd::plugin::write_graphite::graphiteport', '2003'),
    storerates     => hiera('collectd::plugin::write_graphite::storerates', 'true'),
    graphiteprefix => hiera('collectd::plugin::write_graphite::graphiteprefix'),
  }

  class {'::collectd::plugin::syslog':
    log_level => hiera('collectd::plugin::syslog::log_level', 'info'),
  }

  collectd::plugin {'cpu':}
  collectd::plugin {'load':}
  collectd::plugin {'memory':}

  class {'::collectd::plugin::df':
    mountpoints    => hiera('collectd::plugin::df::mountpoints', '/'),
    fstypes        => hiera('collectd::plugin::df::fstypes',
                            ['nfs','tmpfs','autofs','gpfs','proc','devpts']),
    ignoreselected => hiera('collectd::plugin::df::ignoreselected', 'false'),
  }

  class {'::collectd::plugin::disk':
    disks          => hiera('collectd::plugin::disk::disks', '/'),
    ignoreselected => hiera('collectd::plugin::disk::ignoreselected', 'false'),
  }

  class {'::collectd::plugin::network':}

  class {'::collectd::plugin::interface':
    interfaces     => hiera('collectd::plugin::interface::interfaces'),
    ignoreselected => hiera('collectd::plugin::interface::ignoreselected'),
  }

  class {'::collectd::plugin::ntpd':
    host           => hiera('collectd::plugin::ntpd::host', 'localhost'),
    port           => hiera('collectd::plugin::ntpd::port', '123'),
    reverselookups => hiera('collectd::plugin::ntpd::reverselookups', 'false'),
    includeunitid  => hiera('collectd::plugin::ntpd::includeunitid', 'false'),
  }

  #class {'::collectd::plugin::tcpconns':
  #  localports  => hiera('collectd::plugin::tcpconns::localports',
  #                       ['22', '80', '443', '9200', '9300']),
  #  remoteports => hiera('collectd::plugin::tcpconns::remoteports',
  #                       ['25', '80', '443']),
  #  listening   => hiera('collectd::plugin::tcpconns::listening', 'true'),
  #}
}
