#!/bin/bash

source subr.sh

if [ x"$#" != x"1" ]; then
	echo "$0 region"
	exit 1
fi
region=$1; shift

mysql_user=root
mysql_password=mysql

do_query "UPDATE endpoint SET region = '${region}';" keystone
do_command openstack-config --set /etc/nova/nova.conf DEFAULT neutron_region_name ${region}
do_command openstack-config --set /etc/neutron/neutron.conf DEFAULT nova_region_name ${region}
do_command openstack-config --set /etc/neutron/metadata_agent.ini DEFAULT auth_region ${region}
