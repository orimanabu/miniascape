#!/bin/sh

if [ x"$#" != x"4" ]; then
	echo "$0 tenant role user password"
	exit 1
fi
tenant=$1; shift
role=$1; shift
user=$1; shift
password=$1; shift

echo "=> keystone"
keystone tenant-create --name ${tenant}
keystone user-create --name ${user} --tenant ${tenant} --pass ${password} --enabled true
keystone role-create --name ${role}
keystone user-role-add --user ${user} --role ${role} --tenant ${tenant}

keystone tenant-list
keystone user-list
keystone user-get ${user}
keystone user-role-list

rcfile=/root/keystonerc_${user}
echo "=> ${rcfile}"
if [ -f ${rcfile} ]; then
	cp ${rcfile} ${rcfile}.save
fi
cp /root/keystonerc_admin ${rcfile}
sed -i \
-e "s/^\(.*OS_USERNAME=\)admin$/\1${user}/" \
-e "s/^\(.*OS_TENANT_NAME=\)admin$/\1${tenant}/" \
-e "s/^\(.*OS_PASSWORD=\)admin$/\1${password}/" \
-e "s/^\(.*\)keystone_admin\(.*\)$/\1keystone_${user}\2/" \
$rcfile
