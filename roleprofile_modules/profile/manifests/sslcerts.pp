class profile::sslcerts {

	# Virtually declare all the SSL certs that we need for 
	# something or other.  Then they are realized in the
	# other profile classes that need them

	$ssl_certs = hiera('ssl_certs', [ ])
	$ssl_cacert = hiera('ssl_cacert', '')
	$no_verify = hiera('ssl_no_verify', false)
	$path = hiera('ssl_path', '/etc/pki/tls')

        each($ssl_certs) | $cert | {

		@sslcert {
			$cert:
				location	=> $path,
				group		=> 'openstack',
				require		=> Group['openstack']
		}

	}

	if $ssl_cacert != '' {
		@sslcert::cacert {
			'cacert':
				certname	=> $ssl_cacert,
				location	=> $path,
				group		=> 'openstack'
		}
		$cacert_file = "${path}/certs/${ssl_cacert}.crt"
	} else {
		$cacert_file = ''
	}

	group {
		'openstack':
			ensure		=> present;
	}

}
