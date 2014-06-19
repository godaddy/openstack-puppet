class profile::openstack::sensu::checks::libvirtd {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'libvirtd_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p libvirtd -C 1",
    subscribers => "${subscriberbase}_libvirtd",
  }

}

