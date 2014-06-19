class profile::hiera_eyaml_setup {

  package { 'hiera-eyaml':
    ensure    => present,
    provider  => gem,
  }

  file { '/etc/profile.d/hiera-eyaml.sh':
    ensure    => present,
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    content   => 'export EYAML_CONFIG=/etc/hiera-eyaml.yaml',
  }

  file { '/etc/hiera-eyaml.yaml':
    ensure    => present,
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    content   => template('profile/hiera-eyaml.yaml.erb'),
  }

}
