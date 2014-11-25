#!/bin/bash

source ./subr.sh

source ~/keystonerc_demo
vm=vm1
volume=vol1
flavor=m1.tiny
image=cirros

echo "=> nova boot ${vm}"
./nova.sh -t demo -f ${flavor} -n demo-net -i ${image} -v ${vm} boot
./wait_for_vm_boot.sh ${vm}
sleep 5

echo "=> status"
cinder list
nova show ${vm}
echo "=> lsblk on VM(${vm})"
ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no $(nova show ${vm} | awk '/network/ {print $5}') -l cirros lsblk
sleep 2


echo "=> create volume"
do_command cinder create --display-name ${volume} 1
sleep 1
cinder list
echo "=> attach volume"
do_command nova volume-attach ${vm} $(cinder list | awk '/'${volume}'/ {print $2}') /dev/vdb
sleep 3

echo "=> status"
cinder list
nova show ${vm}
sleep 2

echo "=> lsblk on VM(${vm})"
ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no $(nova show ${vm} | awk '/network/ {print $5}') -l cirros lsblk
sleep 2

echo "=> detach volume"
do_command nova volume-detach ${vm} $(cinder list | awk '/'${volume}'/ {print $2}')
sleep 1
echo "=> delete volume"
do_command cinder delete ${volume}
sleep 1

echo "=> status"
cinder list
nova show ${vm}

echo "=> nova delete ${vm}"
nova delete ${vm}
