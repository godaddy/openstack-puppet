class profile::ntp {

  class { '::ntp':
    servers => [ '10.255.250.11', '10.255.251.11' ],
    restrict => [ '127.0.0.1' ],
    disable_monitor => true,
  }

}
