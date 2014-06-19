class profile::openstack::sensu::client {

  # Sensu Client (Don't configure Sensu client stuff on the Sensu server itself)
  $server_role = hiera('role')

  if $server_role != 'role::openstack::singlemonitor' and $server_role != 'role::openstack::sensu' {

    # Ok, we keep the list of Sensu subscriptions in the main hiera data file for the environment
    # But, it's based on the server role, so we have to pull that first.
    $role = hiera('role')
    $shortrole = regsubst($role, '^role::openstack::(.+)$', '\1')

    # Then merge the subscriptions lists together to get the full list for this machine
    $subscriptions = flatten([ hiera('sensu::client::subscriptions::all', []), hiera("sensu::client::subscriptions::${shortrole}", []) ])

    class {'::sensu':
      use_embedded_ruby        => true,
      safe_mode                => false,
      client                   => true,
      server                   => false,
      api                      => false,
      dashboard                => false,
      log_level                => hiera('sensu::client::log_level', 'info'),
      install_repo             => hiera('sensu::client::install_repo', false),
      api_host                 => hiera('sensu::api_host'),
      api_port                 => hiera('sensu::api_port', 4567),
      redis_host               => hiera('sensu::redis_host', 'localhost'),
      redis_port               => hiera('sensu::redis_port', 6379),
      rabbitmq_user            => hiera('sensu::mq_user', 'sensu'),
      rabbitmq_password        => hiera('sensu::mq_password', 'sensu'),
      rabbitmq_host            => hiera('sensu::mq_host', 'localhost'),
      rabbitmq_port            => hiera('sensu::mq_port', 5672),
      rabbitmq_vhost           => hiera('sensu::mq_vhost', '/sensu'),
      rabbitmq_ssl             => hiera('sensu::mq_ssl', false),
      subscriptions            => $subscriptions,
    }

    # Take our $subscriptions array and turn it into an array of plugin class names for inclusion
    $classes = regsubst($subscriptions, '^openstack_[^_]+_(.+)$', 'profile::openstack::sensu::plugins::\1')

    include profile::openstack::sensu::plugins::common
    include $classes

  }
}
