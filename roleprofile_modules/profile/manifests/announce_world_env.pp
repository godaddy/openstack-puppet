class profile::announce_world_env {

  # Announce our $::environment and $::word
  notify { 'world_and_env':
    message => "***** Puppet running with ::world = ${::world} and ::environment = ${::environment} *****",
  }

}
