class profile::openstack::sensu::checks::all {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'logstash_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/share/java/logstash.jar -C 1",
    subscribers => "${subscriberbase}_all",
  }

  sensu::check { 'disk_usage':
    command     => "/etc/sensu/plugins/check-disk.rb -w 90 -c 95",
    subscribers => "${subscriberbase}_all",
  }

}

