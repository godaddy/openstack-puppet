#!/bin/bash

rpm -qa | grep openstack | xargs yum -y remove
rpm -qa |grep ^python | grep client | xargs yum -y remove
killall /usr/bin/python
yum remove rabbitmq-server memcached httpd -y
service pacemaker stop ; service corosync stop
yum -y remove pacemaker corosync
cd /etc/
rm -rf ceilometer/ corosync/ glance/ heat/ httpd/ keystone/ nova/ rabbitmq/ 
rm -f /etc/pki/tls/private/* /etc/pki/tls/certs/{openstack,horizon,api,spice,keystone,gd,rabbitmq}*
rm -rf /var/lib/corosync/ /var/lib/pacemaker/
rm -rf /usr/share/openstack-dashboard/
rm -rf /var/lib/rabbitmq
