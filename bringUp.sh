#!/bin/bash

INTERNAL_IFACE='/var/lib/n4d/variables-dir/INTERNAL_INTERFACE'
IFACE=""

if [ -e $INTERNAL_IFACE ]
then
	#Get internal iface from n4d
	IFACE=$(grep value $INTERNAL_IFACE | cut -d ":" -f2 | tr -d \"\ )
fi

if [ ! -z $IFACE ]
then

	PROPOSED_IP=$(netplan-query $IFACE ip)
	LINKSPEED=$(cat /sys/class/net/$IFACE/speed 2>/dev/null)

	if [ -z $LINKSPEED ]
	then
		#If no speed then there is no link so bring up iface
		ip addr add $PROPOSED_IP dev $IFACE
		ip link set $IFACE up
	fi
fi

exit 0
