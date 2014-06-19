class profile::openstack::sensu::checks::rabbitmq {

  $subscriberbase = hiera('sensu::subscriber_base')

  $username = hiera('message::username')
  $password = hiera('message::password')
  $ssl = hiera('message::ssl', false) ? { true => "--ssl", default => "" }
  $port = hiera('message::ssl', false) ? { true => 5671, default => 5672 }

  sensu::check {'rabbitmq_amqp_alive':
    command     => "/etc/sensu/plugins/rabbitmq-amqp-alive.rb -u ${username} -p '${password}' -P ${port} ${ssl}",
    subscribers => "${subscriberbase}_rabbitmq",
  }

  sensu::check {'check_rabbitmq_messages':
    command     => "/etc/sensu/plugins/check-rabbitmq-messages.rb --user ${username} --password '${password}' --port 15672 ${ssl}",
    subscribers => "${subscriberbase}_rabbitmq",
  }

  sensu::check {'rabbitmq_queue_metrics':
    command     => "/etc/sensu/plugins/rabbitmq-queue-metrics.rb --user ${username} --password '${password}' --port 15672 ${ssl}",
    type        => 'metric',
    subscribers => "${subscriberbase}_rabbitmq",
    handlers    => [ 'default' ],
  }

}

