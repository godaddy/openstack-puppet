class profile::openstack::sensu::checks::nova_api_metadata {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'nova_api_metadata_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/nova-api-metadata -C 1",
    subscribers => "${subscriberbase}_nova_api_metadata",
  }

  sensu::check {'nova_api_metadata_ip_corosync':
    command     => "/etc/sensu/plugins/check_crm",
    subscribers => "${subscriberbase}_nova_api_metadata",
  }

  sensu::check {'nova_api_metadata_url':
    command     => "/etc/sensu/plugins/check-http.rb -u http://localhost:8775",
    subscribers => "${subscriberbase}_nova_api_metadata",
  }

}

