class profile::openstack::sensu::checks::ceilometer_alarm_notifier {

  $subscriberbase = hiera('sensu::subscriber_base')

  sensu::check {'ceilometer_alarm_notifier_processes':
    command     => "/etc/sensu/plugins/check-procs.rb -p /usr/bin/ceilometer-alarm-notifier -C 1",
    subscribers => "${subscriberbase}_ceilometer_alarm_notifier",
  }

}

