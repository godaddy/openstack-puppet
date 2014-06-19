openstack-puppet
================

Go Daddy Puppet module for installing, configuring, and managing OpenStack components.

Deployment managed by r10k.  See the Puppetfile for other Puppet modules used.

This is meant to be a community reference, and likely cannot be cloned and used
immediately "out of the box."  You will, at a minimum, need to populate a hiera
file for all the configuration parameters.

Patches/comments/complaints welcomed and encouraged!  Create an issue or PR here.

Puppet Configuration
--------------------

This module requires Puppet >= 3.5.1 and the "parser=future" and 
"evaluator=current" puppet.conf options.

