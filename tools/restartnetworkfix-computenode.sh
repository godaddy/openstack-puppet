#!/bin/bash
#
# Fix-up script for hypervisor/compute nodes in case 'service network restart' is ran
#
 
echo "Deleting old Linux bridge -> OVS links"
bridgeovslinks=$( ip link list | grep qvo | awk '{ print $2}' | cut -d":" -f1,1 )
for link in $bridgeovslinks
do
  ip link delete $link
done
 
echo "Deleting old Linux bridges"
bridges=$( brctl show | grep qbr | awk '{ print $1 }' )
for bridge in $bridges
do
  ifconfig $bridge down
  brctl delbr $bridge
done
 
echo "Restarting openstack services"
/etc/init.d/openstack-neutron-openvswitch-agent restart
/etc/init.d/openstack-nova-compute restart
/etc/init.d/openstack-neutron-ovs-cleanup start
 
echo "Repluging tap devices into linux bridge"
for $bridge in $bridges
do
  shortname=$( echo $bridge | sed -r 's/^qbr//' )
  brctl addif $bridge tap$shortname
done
