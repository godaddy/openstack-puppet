class profile::openstack::sensu::checks::nova_cert {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_cert_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-cert -C 1",
    subscribers => "${subscriberbase}_nova_cert",
  }

}

