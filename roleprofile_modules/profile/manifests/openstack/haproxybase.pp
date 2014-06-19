class profile::openstack::haproxybase inherits profile::base {

  # HA Proxy global and default options
  class {
    'haproxy':
      global_options    => {
        'maxconn' => '204096',
        'user'    => 'haproxy',
        'group'   => 'haproxy',
        'stats'   => 'socket /var/run/haproxy.sock mode 0600 level admin',
        'daemon'  => '',
        'log'     => '/dev/log local0 info'
      },
      defaults_options  => {
        'log'         => 'global',
        'mode'        => 'tcp',
        'option'      => [ 'dontlognull', 'redispatch' ],
        'retries'     => '3',
        'maxconn'     => '204096',
        'contimeout'  => '50000',
        'clitimeout'  => '500000',
        'srvtimeout'  => '500000'
      }
  }

}
