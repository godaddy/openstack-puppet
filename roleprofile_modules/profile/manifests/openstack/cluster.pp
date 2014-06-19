class profile::openstack::cluster {

  # We have different cluster members & config, depending on server role
  if hiera('role') == 'role::openstack::network' or hiera('role') == 'role::openstack::networkglance' {
    # Once we are on a puppet master setup, use collect() here to find other cluster members
    $cluster_members = hiera('network::cluster_nodes')

    corosync::property {
      'no-quorum-policy': value => "ignore";
    }
  } else {
    $cluster_members = hiera('api::cluster_nodes')
  }

  class { 'corosync::udpu':
    cluster_members => $cluster_members,
    bind_address => hiera('server::ip_address', $::ipaddress),
  }

  corosync::property {
    'pe-warn-series-max': value => 1000;
    'pe-input-series-max': value => 1000;
    'pe-error-series-max': value => 1000;
    'cluster-recheck-interval': value => "5m";
    'stonith-enabled': value => false;
  }

}


