#!/bin/bash

source ./subr.sh

ram=1024	# MB
disk=10		# GB
vcpu=1
flavor=m1.custom_rhel7

echo "=> flavor"
nova flavor-list | grep ${flavor} > /dev/null 2>&1
if [ x"$?" != x"0" ]; then
	echo "==> create ${flavor}"
	./flavor.sh ${flavor} ${ram} ${disk} ${vcpu}
fi

echo "=> vm status"
source ~/keystonerc_demo
for image in cirros rhel7; do
	echo "==> nova boot ${image}"
	./nova.sh -t demo -f ${flavor} -n demo-net -i ${image} -v vm_${image} boot 2>&1 | tee log.nova.boot.${image}
	./wait_for_vm_boot.sh vm_${image}
	sleep 5
	./vm_status.sh vm_${image} 2>&1 | tee log.boot_status.${image}
	nova delete vm_${image}
	./wait_for_vm_delete.sh vm_${image}
	sleep 10
done

#source ~/keystonerc_admin
#nova flavor-delete ${flavor}
