#!/bin/sh

rpm -qa | grep openstack | grep -v kernel | grep -v firmware | xargs yum -y remove
rpm -qa | grep ^python | grep client | xargs yum -y remove
rpm -qa | grep ^kernel | grep openstack | grep -v firmware | xargs yum -y remove

