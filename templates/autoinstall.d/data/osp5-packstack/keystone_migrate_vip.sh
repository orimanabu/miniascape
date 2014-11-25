#!/bin/sh

source ./subr.sh

#if [ x"$#" != x"2" ]; then
#	echo "$0 old new"
#	exit 1
#fi
vip={{ keystone_ha.service_ip }}
master={{ keystone_mysql.master.ip }}
slave={{ keystone_mysql.slave.ip }}

do_query -s "SELECT * FROM endpoint WHERE service_id = (SELECT id FROM service WHERE type = 'identity')" keystone -N -s | while read line; do
	#params=$(echo ${line} | perl -ane "\$F[5] =~ s/${master}/${vip}/; print qq|id='\$F[0]', legacy_endpoint_id='\$F[1]', interface='\$F[2]', region='\$F[3]', service_id='\$F[4]', url='\$F[5]', extra='\$F[6]', enabled=\$F[7]\n|";)
	sql=$(echo ${line} | perl -ane "\$F[5] =~ s/${master}/${vip}/; print qq|UPDATE endpoint SET url = '\$F[5]' WHERE id='\$F[0]';|")
	echo ${sql}
	echo ${sql} | mysql -u${mysql_user} -p${mysql_password} keystone
done

rcfile=/root/keystonerc_admin
do_command test -f ${rcfile}.orig '||' cp -p ${rcfile} ${rcfile}.orig
do_command sed -i -e "s/${master}/${vip}/" ${rcfile}
scp ${rcfile} ${slave}:
for host in ${master} ${slave}; do
	do_command -r ${host} openstack-config --set /etc/keystone/keystone.conf database connection "mysql://${keystone_db_user}:${keystone_db_password}@${vip}/keystone"
done
do_command "ping -c 1 -W 3 ${vip} && cp -rp /etc/keystone/ssl /etc/keystone/ssl.orig && ssh ${ssh_options} ${vip} '(cd / && tar cf - etc/keystone/ssl)' | (cd / && tar xpvf -)"

#echo "SELECT * FROM endpoint WHERE service_id = (SELECT id FROM service WHERE type = 'identity') ORDER BY region, interface;" | mysql -uroot -pmysql keystone -t
do_query "SELECT endpoint.id, endpoint.legacy_endpoint_id, endpoint.interface, endpoint.region, endpoint.url, endpoint.extra, endpoint.enabled, service.type, service.extra FROM endpoint, service WHERE service.id = endpoint.service_id ORDER BY region,type,interface;" keystone -t

