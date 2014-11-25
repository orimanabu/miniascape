#!/bin/sh

if [ x"$#" != x"1" ]; then
	echo "$0 vm"
	exit 1
fi
vm=$1; shift

echo "===> waiting for the VM (${vm}) to delete..."
while true; do
	nova show ${vm} > /dev/null 2>&1
	if [ x"$?" != x"0" ]; then
		echo
		break
	fi
	echo -n "."
	sleep 3
done
echo "===> done."

