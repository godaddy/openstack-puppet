class profile::openstack::sensu::checks::nova_spicehtml5proxy {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_spicehtml5proxy_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-spicehtml5proxy -C 1",
    subscribers => "${subscriberbase}_nova_spicehtml5proxy",
  }

}

