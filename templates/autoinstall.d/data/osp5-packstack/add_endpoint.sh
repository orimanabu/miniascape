#!/bin/bash

source ./subr.sh

if [ x"$#" != x"3" ]; then
	echo "$0 service region host"
	exit 1
fi
service=$1; shift
region=$1; shift
host=$1; shift

source ~/keystonerc_admin
case ${service} in
keystone|identity)
	do_command keystone endpoint-create --region ${region} --service keystone --publicurl "'http://${host}:5000/v2.0'" --adminurl "'http://${host}:35357/v2.0'" --internalurl "'http://${host}:5000/v2.0'"
	;;
other)
	do_command keystone endpoint-create --region ${region} --service glance --publicurl "'http://${host}:9292'" --adminurl "'http://${host}:9292'" --internalurl "'http://${host}:9292'"
	do_command keystone endpoint-create --region ${region} --service cinder --publicurl "'http://${host}:8776/v1/%(tenant_id)s'" --adminurl "'http://${host}:8776/v1/%(tenant_id)s'" --internalurl "'http://${host}:8776/v1/%(tenant_id)s'"
	do_command keystone endpoint-create --region ${region} --service cinderv2 --publicurl "'http://${host}:8776/v2/%(tenant_id)s'" --adminurl "'http://${host}:8776/v2/%(tenant_id)s'" --internalurl "'http://${host}:8776/v2/%(tenant_id)s'"
	do_command keystone endpoint-create --region ${region} --service cinder_v2 --publicurl "'http://${host}:8776/v2/%(tenant_id)s'" --adminurl "'http://${host}:8776/v2/%(tenant_id)s'" --internalurl "'http://${host}:8776/v2/%(tenant_id)s'"
	do_command keystone endpoint-create --region ${region} --service neutron --publicurl "'http://${host}:9696'" --adminurl "'http://${host}:9696'" --internalurl "'http://${host}:9696'"
	do_command keystone endpoint-create --region ${region} --service nova --publicurl "'http://${host}:8774/v2/%(tenant_id)s'" --adminurl "'http://${host}:8774/v2/%(tenant_id)s'" --internalurl "'http://${host}:8774/v2/%(tenant_id)s'"
	do_command keystone endpoint-create --region ${region} --service nova_ec2 --publicurl "'http://${host}:8773/services/Cloud'" --adminurl "'http://${host}:8773/services/Admin'" --internalurl "'http://${host}:8773/services/Cloud'"
	;;
*)
	echo "$0: unknown service: ${service}"
	;;
esac
