#!/bin/bash

if [ x"$#" == x"0" ]; then
	echo "$0 op"
	exit 1
fi
op=$1; shift
vm=$(basename $(pwd))

echo "op: ${op}"
echo "vm: ${vm}"

case ${op} in
destroy)
	virsh destroy ${vm}
	virsh undefine --snapshots-metadata --remove-all-storage ${vm}
	;;
create)
	sudo bash ./vmbuild.sh ks.cfg
	;;
start)
	sudo virsh start ${vm}
	sudo virsh console ${vm}
	;;
snapshot-create)
	snap=$1; shift
	comment=$1; shift
	if [ x"${snap}" = x"" ]; then
		echo "$0 snapshot-create SNAPSHOT_NAME COMMENT"
		exit 1
	fi
	sudo virsh snapshot-create-as ${vm} ${snap} ${comment}
	sudo virsh snapshot-list ${vm}
	sudo virsh snapshot-info ${vm} ${snap}
	;;
snapshot-revert)
	snap=$1; shift
	if [ x"${snap}" = x"" ]; then
		echo "$0 snapshot-revert SNAPSHOT_NAME"
		exit 1
	fi
	sudo virsh snapshot-revert ${vm} ${snap}
	sudo virsh snapshot-list ${vm}
	;;
esac
