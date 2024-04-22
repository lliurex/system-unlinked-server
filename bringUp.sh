#!/bin/bash

function getIpFromRandom()
{
	PROPOSED_IP=127.$((1 + $RANDOM % 250)).$((1 + $RANDOM % 250)).$((1 + $RANDOM % 250))
}

function getIpFromN4dVar()
{
	INTERNAL_NETWORK='/var/lib/n4d/variables/INTERNAL_NETWORK'
	if [ ! -e $INTERNAL_NETWORK ]
	then
		INTERNAL_NETWORK='/var/lib/n4d/variables-dir/INTERNAL_NETWORK'
	fi
	PROPOSED_IP=$(grep value $INTERNAL_NETWORK | cut -d ":" -f2 | tr -d \"\ | tr -d ,)
	PROPOSED_IP=${PROPOSED_IP%%.0}.254
}

function getIpFromDnsmasq()
{
	SERVERHOST=/var/lib/dnsmasq/hosts/server
	if [ ! -e $SERVERHOST ]
	then
		PROPOSED_IP=$(head -n1 $SERVERHOST | cut -d " " -f1)
	fi
}

INTERNAL_IFACE='/var/lib/n4d/variables/INTERNAL_INTERFACE'
if [ ! -e $INTERNAL_FACE ]
then
	INTERNAL_IFACE='/var/lib/n4d/variables-dir/INTERNAL_INTERFACE'
fi

IFACE=""

if [ -e $INTERNAL_IFACE ]
then
	#Get internal iface from n4d
	IFACE=$(grep value $INTERNAL_IFACE | cut -d ":" -f2 | tr -d \"\ | tr -d ,)
fi

if [ ! -z $IFACE ]
then

	PROPOSED_IP=$(netplan-query $IFACE ip) || getIpFromDnsmasq
	if [ -z $PROPOSED_IP ]
	then
		getIpFromN4dVar
	fi
	if [ -z $PROPOSED_IP ]
	then
		getIpFromRandom
	fi
	LINKSPEED=$(cat /sys/class/net/$IFACE/speed 2>/dev/null)

	if [ -z $LINKSPEED ] || [ $LINKSPEED -lt 0 ]
	then
		#If no speed then there is no link so bring up iface
		ip addr add $PROPOSED_IP dev $IFACE
		ip link set $IFACE up
	fi
fi

exit 0
