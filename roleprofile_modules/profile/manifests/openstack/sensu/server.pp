class profile::openstack::sensu::server inherits profile::base {

  class {'::redis':}

  class {'::sensu':
    server                   => true,
    client                   => true,
    api                      => true,
    dashboard                => true,
    install_repo             => false,
    rabbitmq_host            => hiera('sensu::mq_host', 'localhost'),
    rabbitmq_port            => hiera('sensu::mq_port', 5672),
    rabbitmq_user            => hiera('sensu::mq_user', 'sensu'),
    rabbitmq_password        => hiera('sensu::mq_password', 'sensu'),
    rabbitmq_vhost           => hiera('sensu::mq_vhost', '/sensu'),
    rabbitmq_ssl             => hiera('sensu::mq_ssl', false),
    redis_host               => hiera('sensu::redis_host', 'localhost'),
    redis_port               => hiera('sensu::redis_port', 6379),
    dashboard_port           => hiera('sensu::dashboard_port', 8080),
    use_embedded_ruby        => hiera('sensu::use_embedded_ruby', true),
    subscriptions            => [ ],
    safe_mode                => hiera('sensu::safe_mode', false),
  }

  # We want the common plugins
  include profile::openstack::sensu::plugins::common

  # Configure all the checks necessary to monitor everything
  include profile::openstack::sensu::checks

  # Handlers
  sensu::handler {'graphite-occurrences':
    type    => 'pipe',
    command => '/etc/sensu/handlers/graphite-occurrences.rb',
    source  => 'puppet:///modules/profile/sensu-community-plugins/handlers/metrics/graphite-occurrences.rb',
  }

  sensu::handler {'graphite':
    type    => 'tcp',
    socket  => {
      host  => 'g1dlcldgraphite01.dev.glbt1.gdg',
      port  => 2003,
    },
    mutator => 'only_check_output',
  }

  sensu::handler {'mailer':
    type    => 'pipe',
    command => '/etc/sensu/handlers/mailer.rb',
    source  => 'puppet:///modules/profile/other-sensu-plugins/mailer.rb',
    config  => {
      "mail_from" => "cloud@godaddy.com",
      "mail_to" => hiera('sensu::alerts_address', 'cloud@godaddy.com'),
      "smtp_address" =>  "localhost",
      "smtp_port" => "25",
      "smtp_domain" => "secureserver.net"
    },
    require => Exec['install-rubygem-mail'],
  }



}

