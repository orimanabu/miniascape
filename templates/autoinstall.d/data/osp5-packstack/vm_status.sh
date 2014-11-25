#!/bin/bash

source ./subr.sh

# ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no $(nova show testvm | awk '/network/ {print $5}') -l cloud-user

if [ x"$#" != x"1" ]; then
	echo "$0 vm"
	exit 1
fi
vm=$1; shift
netns=$(ip netns list | grep qrouter)
ip=$(nova show ${vm} | awk '/network/ {print $5}')
image=$(nova show ${vm} | awk '/image/ {print $4}')
user=""
version_file=""

case ${image} in
cirros)
	user=cirros
	version_file=/etc/cirros/version
	;;
rhel7)
	user=cloud-user
	version_file=/etc/redhat-release
	;;
*)
	echo "unknown image: ${image}"
	exit 1
	;;
esac

do_command nova show ${vm}
echo "===> vm status for ${vm}/${image}/${ip}"
echo " * vm = ${vm}"
echo " * image = ${image}"
echo " * user = ${user}"
echo " * version_file = ${version_file}"
echo " * ip = ${ip}"
echo " * netns = ${netns}"

#echo "====> 'ip addr show' in qrouter netns on L3 node"
do_command ip netns exec ${netns} ip addr show

#echo "====> ping to VM (${vm})"
do_command ip netns exec ${netns} ping -c 3 -W 1 ${ip}

#echo "====> 'uname -a' on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} uname -a
#echo "====> version file on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} cat ${version_file}
#echo "====> 'ip addr show' on VM (${vm})"
do_command "ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} 'test -x /usr/sbin/ip && /usr/sbin/ip addr show || /bin/ip addr show'"
#echo "====> lsblk on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} lsblk
#echo "====> mount on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} mount
#echo "====> df -h on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} df -h
#echo "====> lsmod on VM (${vm})"
#do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} lsmod
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} cat /proc/modules
#echo "====> dmesg on VM (${vm})"
do_command ip netns exec ${netns} ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no ${ip} -l ${user} dmesg

#echo "====> console log on VM (${vm})"
do_command nova console-log ${vm}
