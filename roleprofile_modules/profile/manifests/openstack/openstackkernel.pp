class profile::openstack::openstackkernel inherits profile::base {

  # Openstack kernel
  $compute_kernel_package = hiera('compute::kernel_package')
  package {
    $compute_kernel_package:
      ensure  => present,
  }

  $runningkernel = "kernel-${::kernelrelease}"
  exec {
    'running-kernel-check':
      command => $runningkernel ? { $compute_kernel_package => "/bin/true", default => "/bin/false" },
      require => Package[$compute_kernel_package],
  }

  $kernelversion = regsubst($compute_kernel_package, '^kernel-', '')
  exec {
    'default-kernel':
      command => "/sbin/grubby --set-default /boot/vmlinuz-${kernelversion}",
      unless  => "/sbin/grubby --default-kernel | grep /boot/vmlinuz-${kernelversion}",
  }

  # Disable yum from updating the kernel package, but
  # only after we have the kernel we want installed
  ini_setting { 'yum.conf exclude kernel':
    ensure  => present,
    path    => '/etc/yum.conf',
    section => 'main',
    setting => 'exclude',
    value   => 'kernel*',
  }

}
