#!/bin/sh

source ./subr.sh

if [ x"$#" != x"1" ]; then
	echo "$0 vm"
	exit 1
fi
vm=$1; shift

image=$(nova show ${vm} | awk '/image/ {print $4}')
user=""
case ${image} in
cirros)
	user=cirros
	;;
rhel7)
	user=cloud-user
	;;
*)
	echo "unknown image: ${image}"
	exit 1
	;;
esac

echo "===> waiting for the VM (${vm}) to boot..."
while true; do
	nova show ${vm} | awk '/OS-EXT-STS:vm_state/ {print $4}' | grep -i error > /dev/null 2>&1
	if [ x"$?" = x"0" ]; then
		echo "nova boot failed.\n"
		exit 1
	fi
	ip=$(nova show ${vm} | awk '/network/ {print $5}')
	ip netns exec $(ip netns list | grep qrouter) ping -c 1 -W 1 ${ip} > /dev/null 2>&1
	if [ x"$?" = x"0" ]; then
		echo "pingable!"
		break
	fi
	echo -n "."
	sleep 7
done
while true; do
	ip=$(nova show ${vm} | awk '/network/ {print $5}')
	ip netns exec $(ip netns list | grep qrouter) ssh ${ssh_options} -o PasswordAuthentication=no -o ConnectTimeout=5 ${ip} -l ${user} uptime > /dev/null 2>&1
	if [ x"$?" = x"0" ]; then
		echo "sshable!"
		break
	fi
	echo -n "."
	sleep 3
done
echo "===> done."

