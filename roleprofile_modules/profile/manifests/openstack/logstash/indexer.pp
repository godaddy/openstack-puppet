class profile::openstack::logstash::indexer inherits profile::base {

  $es_host    = hiera('logstash::indexer::es_host', 'logs.cloud.int.godaddy.com')
  $es_port    = hiera('logstash::indexer::es_port', 9200)
  $es_workers = hiera('logstash::indexer::es_workers', 1)

  $rmq_debug    = hiera('logstash::indexer::mq_debug', true)
  $rmq_exchange = hiera('logstash::mq_exchange', 'logstash-exchange')
  $rmq_host     = hiera('logstash::mq_host', 'rmq.logs.cloud.int.godaddy.com')
  $rmq_key      = hiera('logstash::mq_key', 'logstash-routing-key')
  $rmq_password = hiera('logstash::mq_pass', 'logstash')
  $rmq_port     = hiera('logstash::mq_port', 5672)
  $rmq_queue    = hiera('logstash::mq_queue', 'logstash-queue')
  $rmq_ssl      = hiera('logstash::mq_ssl', false)
  $rmq_user     = hiera('logstash::mq_user', 'logstash')
  $rmq_vhost    = hiera('logstash::mq_vhost', '/logstash')

  class {'logstash': }

  logstash::configfile {'input_rabbitmq':
    content => template('profile/logstash-input_rabbitmq.erb'),
    order   => 10,
  }

  logstash::configfile {'output_es':
    content => template('profile/logstash-output_es.erb'),
    order   => 90,
  }

}
