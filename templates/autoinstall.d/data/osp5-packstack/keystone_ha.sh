#!/bin/bash

source ./subr.sh

if [ x"$#" != x"1" ]; then
	echo "$0 method"
	echo "  method: endpoint, certs"
	exit
fi
method=$1; shift

vip={{ keystone_ha.service_ip }}
master={{ keystone_mysql.master.ip }}
slave={{ keystone_mysql.slave.ip }}

for host in ${master} ${slave}; do
	case ${method} in
	endpoint)
		source ~/keystonerc_admin
		service_id=$(ssh ${ssh_options} ${host} keystone --os-username admin --os-password admin --os-tenant-name admin --os-auth-url 'http://127.0.0.1:5000/v2.0' service-list | awk '/keystone/ {print $2}')
		do_query -r ${host} "UPDATE endpoint SET url = 'http://${vip}:5000/v2.0' WHERE service_id = '${service_id}' and interface = 'internal'" keystone
		do_query -r ${host} "UPDATE endpoint SET url = 'http://${vip}:5000/v2.0' WHERE service_id = '${service_id}' and interface = 'public'" keystone
		do_query -r ${host} "UPDATE endpoint SET url = 'http://${vip}:35357/v2.0' WHERE service_id = '${service_id}' and interface = 'admin'" keystone
		#vip=$(resolveip -s ${vip})
		keystonerc=/root/keystonerc_admin
		do_command -r ${host} test -f ${keystonerc}.orig '||' cp -p ${keystonerc} ${keystonerc}.orig
		do_command -r ${host} sed -i -e "s/${host}/${vip}/" /root/keystonerc_admin
		do_command -r ${host} openstack-config --set /etc/keystone/keystone.conf database connection "mysql://${keystone_db_user}:${keystone_db_password}@${vip}/keystone"
		;;
	certs)
		do_command -r ${host} "ping -c 1 -W 3 ${vip} && cp -rp /etc/keystone/ssl /etc/keystone/ssl.orig && ssh ${ssh_options} ${vip} '(cd / && tar cf - etc/keystone/ssl)' | (cd / && tar xpvf -)"
		;;
	*)
		echo "unknown method: ${method}"
		;;
	esac
done
