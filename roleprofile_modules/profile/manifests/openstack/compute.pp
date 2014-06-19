class profile::openstack::compute inherits profile::base {

  # We need this first for sudoers
  require profile::openstack::novabase
  require profile::openstack::ceilbase

  # Neutron or Nova networking?
  if hiera('network::provider') == 'neutron' {
    include profile::openstack::neutron::computenode
  } else {
    include profile::openstack::interfaces
  }

  class {
    'nova::compute':
      enabled   => true,
      vnc_enabled => false,
      require => [ Exec['running-kernel-check'], Exec['running-vtx-check'], Exec['modprobe-kvm'] ],
  }


  class {
    'nova::compute::libvirt':
      require => [ Exec['running-kernel-check'], Exec['running-vtx-check'] ],
  }

  include profile::openstack::openstackkernel

  # Processor VTX exensions
  # Enabled in BIOS
  exec {
    'enable-vtx':
      command => "/opt/dell/srvadmin/bin/omconfig chassis biossetup attribute=cpuvt setting=enabled",
      onlyif => "/opt/dell/srvadmin/bin/omreport chassis biossetup | grep '^Processor Virtualization Technology' | grep Disabled",
  }

  # Enabled in runtime environment (if /dev/kvm exists, we're good)
  exec {
    'running-vtx-check':
      command => "/usr/bin/stat /dev/kvm",
      require => Exec['enable-vtx'],
  }

  # Ensure /dev/kvm has correct permissions
  file {
    '/dev/kvm':
      owner   => 'root',
      group   => 'kvm',
      mode    => '0666',
      require => Exec['running-vtx-check'],
  }

  # Make sure kvm and kvm_intel modules loaded
  exec {
    'modprobe-kvm':
      command => "/sbin/modprobe -a kvm kvm_intel",
      unless  => "/sbin/lsmod | /bin/grep -i kvm_intel",
  }

  # spice-server
  package {
    'spice-server':
      ensure  => present,
  }

  # Nova config stuff
  nova_config {
    'DEFAULT/libvirt_inject_key':               value => hiera('compute::libvirt_inject_key');
    'DEFAULT/libvirt_inject_password':          value => hiera('compute::libvirt_inject_password');
    'DEFAULT/libvirt_inject_partition':         value => hiera('compute::libvirt_inject_partition');
    'DEFAULT/firewall_driver':                  value => 'nova.virt.firewall.NoopFirewallDriver';
    'DEFAULT/libvirt_cpu_mode':                 value => hiera('compute::libvirt_cpu_mode', 'host-passthrough');
    'DEFAULT/reserved_host_disk_mb':            value => hiera('compute::reserved_host_disk_mb', '94208');    # 92 GB
    'DEFAULT/reserved_host_memory_mb':          value => hiera('compute::reserved_host_memory_mb', '2048');   # 2 GB
    'DEFAULT/libvirt_vif_driver':               value => hiera('network::libvirt_vif_driver', 'nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver');
    'DEFAULT/resume_guests_state_on_host_boot': value => hiera('compute::resume_guests_state_on_host_boot', true);
    'DEFAULT/image_cache_manager_interval':     value => hiera('compute::image_cache_manager_interval', 2400);
  }

  $libvirt_max_clients = hiera('compute::libvirt_max_clients', 40)
  $libvirt_max_workers = hiera('compute::libvirt_max_workers', 40)
  $libvirt_max_requests = hiera('compute::libvirt_max_requests', 50)
  $libvirt_max_client_requests = hiera('compute::libvirt_max_client_requests', 10)

  # Libvirt tweaks
  file_line {
    'libvirtd_max_clients':
      path    => '/etc/libvirt/libvirtd.conf',
      line    => "max_clients = ${libvirt_max_clients}",
      match   => '^#?max_clients( ?)=.*$',
      notify  => Service['libvirtd'];

    'libvirtd_max_workers':
      path    => '/etc/libvirt/libvirtd.conf',
      line    => "max_workers = ${libvirt_max_workers}",
      match   => '^#?max_workers( ?)=.*$',
      notify  => Service['libvirtd'];

    'libvirtd_max_requests':
      path    => '/etc/libvirt/libvirtd.conf',
      line    => "max_requests = ${libvirt_max_requests}",
      match   => '^#?max_requests( ?)=.*$',
      notify  => Service['libvirtd'];

    'libvirtd_max_client_requests':
      path    => '/etc/libvirt/libvirtd.conf',
      line    => "max_client_requests = ${libvirt_max_client_requests}",
      match   => '^#?max_client_requests( ?)=.*$',
      notify  => Service['libvirtd'];

    'qemu_security_driver':
      path    => '/etc/libvirt/qemu.conf',
      line    => 'security_driver = "none"',
      match   => '^#?security_driver( ?)=.*$',
      notify  => Service['libvirtd'];
  }

  # Spice config stuff
  $spicehost = hiera('compute::spicehost')
  $spice_proxy_ssl = hiera('api::spice_proxy_ssl', false)
  $spice_protocol = $spice_proxy_ssl ? { true => 'https', default => 'http' }
  nova_config {
    'spice/html5proxy_base_url':    value => "${spice_protocol}://${spicehost}:6082/spice_auto.html";
    'spice/server_listen':      value => $::ipaddress;
    'spice/server_proxyclient_address': value => $::ipaddress;
    'spice/enabled':      value => true;
    'spice/agent_enabled':      value => hiera('compute::spice::agent_enabled', false);
    'spice/keymap':       value => 'en-us';
  }

  # Config for ceilometer
  # Hack for MultiStrOpts in nova.conf
  # see http://lists.openstack.org/pipermail/openstack-dev/2013-August/014378.html for some context
  nova_config {
    'DEFAULT/instance_usage_audit':   value => 'True';
    'DEFAULT/instance_usage_audit_period':  value => 'hour';
    'DEFAULT/notify_on_state_change': value => 'vm_and_task_state';
    'DEFAULT/notification_driver':    value => 'nova.openstack.common.notifier.rpc_notifier,ceilometer.compute.nova_notifier';
    #'DEFAULT/notification_driver':   value => 'ceilometer.compute.nova_notifier';
  }

  class {
    'ceilometer::compute':
  }

  # Turn off uneeded rpc stuff
  service { [ 'rpcbind', 'nfslock' ]:
    ensure => stopped,
    enable => false,
  }

  # Need python-libguestfs for ssh key injection
  package { 'python-libguestfs':
    ensure => present
  }

  service { 'iptables':
    enable => true,
    notify => Service['openstack-neutron-openvswitch-agent'],
  }

  $app_servers = hiera('api::cluster_nodes', [ ])
  $app_vip = hiera('api::vip', undef)
  $mgmt_interface = hiera('compute::mgmt_interface', 'mgmt0')
  $allow_ssh_from = hiera('compute::allow_ssh_from', '172.16.0.0/12')

  file { '/etc/sysconfig/iptables':
    content => template('profile/iptables.sysconfig-computenode.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
    notify => Service['iptables'],
  }

  #check to make sure the runlevel 6 script exists
  #if not add them
  exec {
    'add-compute-init':
      command => "/sbin/chkconfig --add openstack-nova-compute",
      unless => "/usr/bin/test -f /etc/rc.d/rc6.d/K02openstack-nova-compute",
      require => Service[openstack-nova-compute];

    'add-neutron-ovs-init':
      command => "/sbin/chkconfig --add openstack-neutron-openvswitch-agent",
      unless => "/usr/bin/test -f /etc/rc.d/rc6.d/K02openstack-neutron-openvswitch-agent",
      require => Service[openstack-neutron-openvswitch-agent];

    'add-ceilometer-init':
      command => "/sbin/chkconfig --add openstack-ceilometer-compute",
      unless => "/usr/bin/test -f /etc/rc.d/rc6.d/K02openstack-ceilometer-compute",
      require => Service[openstack-ceilometer-compute];
  }

  #check to make sure libvirtd and libvirt-guests is shutdown after openstack
  file { '/etc/chkconfig.d/libvirt-guests':
    content => template('profile/libvirt-guests-computenode.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
   }
  exec { "/sbin/chkconfig libvirt-guests resetpriorities":
    subscribe => File["/etc/chkconfig.d/libvirt-guests"],
    refreshonly => true
  }
  file { '/etc/chkconfig.d/libvirtd':
    content => template('profile/libvirtd-computenode.erb'),
    owner => 'root',
    group => 'root',
    mode => '0644',
   }
  exec { "/sbin/chkconfig libvirtd resetpriorities":
    subscribe => File["/etc/chkconfig.d/libvirtd"],
    refreshonly => true
  }
}
