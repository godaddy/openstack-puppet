#!/bin/bash

function usage() {
        echo "Usage: restartworld.sh [nova,keystone,glance,ceilometer,heat,neutron,spice,els,world] [app,network,network-af,compute]"
        echo "Example: restartworld.sh nova app"
        exit 1
}

if [  $# -ne 2 ]
then
        usage
fi

function restartviapacemaker() {
	local service
	local tmp
	local crm
	local sleep
	local pmresource
	local hostname
	local curhost
	
	crm=$(which crm)
	service=$1
	sleep=3

	case $service in
		openstack-heat-engine)
			pmresource="heat_engine-p_heat_engine"
			service="heat-engine";; #clownshoes with the actual running service name..
		openstack-ceilometer-central)
			pmresource="ceilometer_central-p_ceilometer_central"
			service="openstack-ceilometer-agent-central";; #clownshoes with the actual running service name..
		*)
			echo "Unknown pacemaker service: $service"
			return 1;;
	esac

	echo "Service: $1 is handled by pacemaker, restarting via pacemaker"
	#echo "This service is pacemaker resource: $pmresource"

	tmp=$( $crm resource status $pmresource | egrep -i "NOT|unmanaged" )
	if [ $? -eq 1 ]
	then
		#check to see if the resource is running on the current host
		curhost=$( $crm resource status  $pmresource | cut -d":" -f2,2 | cut -d" " -f2,2 )
		hostname=$( hostname )
		if [ "$curhost" == "$hostname" ]
		then
			#pacemaker resource is running and its on this host
			tmp=$( $crm resource stop $pmresource )
		
			#need to sleep so pacemaker can shutdown the service
			sleep $sleep

			#kill the service if its still running (ie someone started it locally)
			tmp=$( ps auxwwwf | grep $service | grep -v grep )
			if [ $? -eq 0 ]
			then	
				tmp=$( ps auxwwwf | grep $service | grep -v grep | awk '{print $2}')
				for i in $tmp
				do
					kill -9 $i
				done
				#somereason if we kill it doesn't handel start up right...
				tmp=$( $crm resource cleanup $pmresource )
			fi
			tmp=$( $crm resource start $pmresource )
		else
			#pacemaker resource is not running on this host -but we should make sure the resource hasn't been started
			tmp=$( ps auxwwwf | grep $service | grep -v grep )
			if [ $? -eq 0 ]
			then	
				tmp=$( ps auxwwwf | grep $service | grep -v grep | awk '{print $2}')
				for i in $tmp
				do
					kill -9 $i
				done
			fi
			echo "Success: service is running on: $curhost - not attempting to restart the service here"
			return 0
		fi
	else
		$pacemaker resouce was not running, try to cleanup resource
		tmp=$( $crm resource cleanup $pmresource )

		#kill the service if its still running (ie someone started it locally)
		tmp=$( ps auxwwwf | grep $service | grep -v grep )
		if [ $? -eq 0 ]
		then	
			tmp=$( ps auxwwwf | grep $service | grep -v grep | awk '{print $2}')
			for i in $tmp
			do
				kill -9 $i
			done
			#somereason if we kill it doesn't handel start up right...
			tmp=$( $crm resource cleanup $pmresource )
		fi
	
		tmp=$( $crm resource start $pmresource )
	 fi

	#pacemaker is slow starting stuff... sleep for a bit to give it time...
	sleep $sleep
	
	tmp=$( $crm resource status | grep "$pmresource" | grep "Started" )
	if [ $? -eq 0 ]
	then
		tmp=$(crm resource status $pmresource )
		echo "Success: $tmp"
		return 0
	else
		echo "****FAILED**** to start service $1, please investigate"
		return 1
	fi
}

function restartservice() {
        local service
        local tmp
	local sleep

        service=$1
	sleep=1	

	if [ "$service" == "openstack-heat-engine" ]
	then
		restartviapacemaker $service
		return $?
	elif [ "$service" == "openstack-ceilometer-central" ]
	then
		restartviapacemaker $service
		return $?
	fi

        echo "Restarting service: $service"

        tmp=$(service $service status)
        if [ $? -eq 0 ]
        then
                tmp=$(/sbin/service $service stop)
		
		#give the service some time to stop...
		sleep $sleep

		#kill the service if its still running (handles spice pretty well)
		tmp=$( ps auxwwwf | grep $service | grep -v grep )
		if [ $? -eq 0 ]
		then	
			tmp=$( ps auxwwwf | grep $service | grep -v grep | awk '{print $2}')
			for i in $tmp
			do
				kill -9 $i
			done
		fi
                tmp=$(/sbin/service $service start)
        else
                tmp=$(/sbin/service $service start)
        fi
	tmp=$(/sbin/service $service status)
	if [ $? -eq 0 ]
	then
		echo "Success: $tmp"
		return 0
	else
		echo "****FAILED****: $tmp"
		return 1
	fi
}



function restartnova() {
        local tier
        local services

        tier=$1
        if [ "$tier" == "app" ]
        then    
                services="openstack-nova-api openstack-nova-scheduler openstack-nova-conductor openstack-nova-spicehtml5proxy openstack-nova-cert"
        elif [ "$tier" == "network" ]
        then
                services="openstack-nova-metadata-api"
        elif [ "$tier" == "network-af" ]
        then
                services="openstack-nova-metadata-api"
        elif [ "$tier" == "compute" ]
        then
                services="openstack-nova-compute"
        fi

        for i in $services
        do
                restartservice $i 
        done

}

function restartkeystone() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then    
                services="openstack-keystone"
        else
                echo "Keystone does not run on $tier"
                return 1
        fi

        for i in $services
        do
                restartservice $i 
        done
}

function restartglance() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then    
                services="openstack-glance-registry openstack-glance-api"
        elif [ "$tier" == "network-af" ]
        then
                services="openstack-glance-registry openstack-glance-api"
        else
                echo "Glance does not run on $tier"
                return 1
        fi

        for i in $services
        do
                restartservice $i 
        done
}

function restartheat() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then    
                services="openstack-heat-api openstack-heat-api-cloudwatch openstack-heat-api-cfn openstack-heat-engine"
        else
                echo "Heat does not run on $tier"
                return 1
        fi

        for i in $services
        do
                restartservice $i 
        done
}

function restartneutron() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then    
                services="openstack-neutron-server"
        elif [ "$tier" == "network" ]
        then
                services="openstack-neutron-openvswitch-agent openstack-neutron-dhcp-agent"
        elif [ "$tier" == "network-af" ]
        then
                services="openstack-neutron-openvswitch-agent openstack-neutron-dhcp-agent"
        elif [ "$tier" == "compute" ]
        then
                services="openstack-neutron-openvswitch-agent"
        fi

        for i in $services
        do
                restartservice $i 
        done
}

function restartspice() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then
                services="openstack-nova-spicehtml5proxy"
        else
                echo "Spice does not run on $tier"
                return 1
        fi
        for i in $services
        do
                restartservice $i 
        done
}

function restartceilometer() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then    
                services="openstack-ceilometer-alarm-notifier openstack-ceilometer-alarm-evaluator openstack-ceilometer-api \
                          openstack-ceilometer-central openstack-ceilometer-collector"
        elif [ "$tier" == "compute" ]
        then
                services="openstack-ceilometer-compute"
        else
                echo "Ceilometer does not run on $tier"
                return 1
        fi

        for i in $services
        do
                restartservice $i 
        done
}

function restartels() {
        local tier
        local services
        tier=$1

        if [ "$tier" == "app" ]
        then
                services="els-notifications-consumer"
        else
                echo "els does not run on $tier"
                return 1
        fi
        for i in $services
        do
                restartservice $i 
        done
}


function restartworld() {
        local tier
        tier=$1

        if [ "$tier" == "app" ]
        then
                restartnova $tier
                restartneutron $tier
                restartkeystone $tier
                restartglance $tier
                restartheat $tier
                restartceilometer $tier
		restartels $tier
        elif [ "$tier" == "network" ]
        then
                restartneutron $tier
                restartnova $tier
        elif [ "$tier" == "network-af" ]
        then
                restartneutron $tier
                restartnova $tier
                restartglance $tier
        elif [ "$tier" == "compute" ]
        then
                restartneutron $tier
                restartnova $tier
                restartceilometer $tier
        fi
        
}

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

case $2 in
        app)
                tier=app;;
        network)
                tier=network;;
        network-af)
                tier=network-af;;
        compute)
                tier=compute;;
        *) usage;;
esac

case $1 in
        nova)
                restartnova $tier;;
        keystone)
                restartkeystone $tier;;
        glance)
                restartglance $tier;;
        ceilometer)
                restartceilometer $tier;;
        heat)
                restartheat $tier;;
        neutron)
                restartneutron $tier;;
        spice)
                restartspice $tier;;
        world)
                restartworld $tier;;
	els)
		restartels $tier;;
        *)
                usage;;
esac
