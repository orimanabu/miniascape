#!/bin/bash

OPTIND=1
exclude=""
enable=""

while getopts "hex:" opt; do
	case ${opt} in
	h)
		usage
		exit 0
		;;
	e)
		enable=xxx
		;;
	x)
		exclude=${OPTARG}
		;;
	esac
done
shift $((OPTIND-1))
[ "$1" = "--" ] && shift

if [ x"$#" != x"1" ]; then
	echo "$0 op"
	exit 1
fi
op=$1; shift

#echo "exclude=${exclude}"
#echo "op=${op}"
#exit

services="\
openstack-keystone \
openstack-glance-api \
openstack-glance-registry \
openstack-cinder-api \
openstack-cinder-scheduler \
openstack-cinder-volume \
openstack-nova-api \
openstack-nova-cert \
openstack-nova-conductor \
openstack-nova-consoleauth \
openstack-nova-novncproxy \
openstack-nova-scheduler \
neutron-ovs-cleanup \
neutron-server \
neutron-openvswitch-agent \
neutron-metadata-agent \
neutron-dhcp-agent \
neutron-l3-agent \
"

#test=echo

case ${op} in
start)
	for service in ${services}; do
		[ x"${exclude}" != x"" ] && echo ${service} | grep ${exclude} > /dev/null && continue
		echo "==> ${service}"
		${test} systemctl start ${service}.service
		test -n ${enable} && ${test} systemctl enable ${service}.service
	done
	;;
stop)
	for service in $(echo ${services} | tr ' ' '\n' | tac); do
		[ x"${exclude}" != x"" ] && echo ${service} | grep ${exclude} > /dev/null && continue
		echo "==> ${service}"
		${test} systemctl stop ${service}.service
		test -n ${enable} && ${test} systemctl disable ${service}.service
	done
	;;
esac
