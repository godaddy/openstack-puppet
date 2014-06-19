#!/bin/bash

rpm -qa | grep openstack | grep -v kernel | xargs yum -y remove
rpm -qa |grep ^python | grep client | xargs yum -y remove
killall /usr/bin/python
service pacemaker stop ; service corosync stop
yum -y remove pacemaker corosync
cd /etc/
rm -rf ceilometer/ corosync/ nova/
rm -f /etc/sysconfig/network-scripts/ifcfg-bond0.* /etc/sysconfig/network-scripts/ifcfg-br*
rm -rf /var/lib/corosync/ /var/lib/pacemaker/
