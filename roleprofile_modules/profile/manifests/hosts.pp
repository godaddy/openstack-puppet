class profile::hosts {

  # Hosts entries
  $server_role = hiera('role')
  $short_role = regsubst($server_role, '^role::openstack::(.+)$', '\1')
  $hosts = hiera("hosts::${short_role}", { })

  each($hosts) | $host, $ip | {  
    host { $host:
      ip    => $ip,
    }
  }

}
