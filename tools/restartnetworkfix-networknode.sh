#!/bin/bash
#
# Fix-up script for Neutron "network" nodes in case 'service network restart' is ran
#

echo "Stopping neutron services"
/etc/init.d/openstack-neutron-openvswitch-agent stop
/etc/init.d/openstack-neutron-dhcp-agent stop
killall -9 dnsmasq
echo "Waiting for dnsmasq to die"
sleep 5
echo "Cleaning up old netns stuff"
for netns in `ip netns list`
do
    echo "Found $netns, removing"
    ip netns delete $netns
done
echo "Starting neutron services"
/etc/init.d/openstack-neutron-openvswitch-agent start
/etc/init.d/openstack-neutron-dhcp-agent start
