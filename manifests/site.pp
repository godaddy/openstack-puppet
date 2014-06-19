# Enforce some ordering
stage { 'pre': }
stage { 'post': }
Stage['pre'] -> Stage['main'] -> Stage['post']

node default {
	# Get the role from hiera and include that class
	hiera_include('role', 'role')
}
