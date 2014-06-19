class profile::openstack::dashboard inherits profile::base {

	$ssl_cert = hiera('dashboard::ssl_cert', '')
	$ssl_path = $::profile::sslcerts::path

	case $ssl_cert {
		'': {
			$real_ssl_cert = ''
			$real_ssl_key = ''
			$require = [ ]
		}
		default: {
			$real_ssl_cert = "${ssl_path}/certs/${ssl_cert}.crt"
			$real_ssl_key = "${ssl_path}/private/${ssl_cert}.key"
			realize Sslcert[$ssl_cert]
			if $::profile::sslcerts::cacert_file != '' {
				realize Sslcert::Cacert['cacert']
				$require = [ Sslcert[$ssl_cert], Sslcert::Cacert['cacert'] ]
			} else {
				$require = [ Sslcert[$ssl_cert] ]
			}
		}
	}

	# Make sure Django14 is there before installing horizon
	# to get around Anvil RPM deps derps.
	package {
		'Django14':
			ensure	=> present,
			before	=> Class['horizon'],
	}

	# Fixup for permissions
	file {
		'/usr/share/openstack-dashboard/static/dashboard':
			ensure	=> directory,
			owner	=> 'root',
			group	=> 'apache',
			mode	=> '0775',
      require => Class['horizon'],
	}

	class {
		'horizon':
			secret_key		=> hiera('dashboard::secret_key'),
			keystone_host		=> hiera('identity::keystone_host'),
			keystone_scheme		=> hiera('identity::ssl_cert', '') ? { '' => 'http', default => 'https' },
			keystone_user_provider	=> hiera('identity::keystone_user_provider', 'keystone'),
			django_debug		=> hiera('dashboard::debug', false),
			log_level		=> hiera('dashboard::log_level', 'INFO'),
			cache_servers		=> hiera('dashboard::cache_servers'),
			server_name		=> hiera('dashboard::server_name'),
			server_aliases		=> hiera('dashboard::server_aliases', [ ]),
			listen_ssl		=> hiera('dashboard::ssl', false),
			ssl_cert		=> $real_ssl_cert,
			ssl_key			=> $real_ssl_key,
			ssl_cacert		=> $::profile::sslcerts::cacert_file,
			ssl_no_verify		=> $::profile::sslcerts::no_verify,
			require			=> $require
	}

}
