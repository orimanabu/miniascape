#!/bin/sh

source ./subr.sh

node1eth0=10.0.1.13
node1eth1=172.16.0.1
node1vxlan=192.168.0.1
node1=${node1eth0}

node2eth0=10.0.1.23
node2eth1=172.16.0.2
node2vxlan=192.168.0.2
node2=${node2eth0}

for node in ${node1} ${node2}; do
	echo "=> ${node}"
#	do_command -r ${node} ip link show
	do_command -r ${node} ip -d link show dev vxlan99
#	do_command -r ${node} ip addr show
#	do_command -r ${node} ip route show
	do_command -r ${node} bridge fdb show dev vxlan99
	do_command -r ${node} bridge fdb show dev vnet0
	do_command -r ${node} brctl showmacs brvxlan
done
