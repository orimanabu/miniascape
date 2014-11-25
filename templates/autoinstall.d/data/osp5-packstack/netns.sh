#!/bin/bash

source ./subr.sh

if [ x"$#" != x"1" ]; then
	echo "$0 vm"
	exit 1
fi
vm=$1; shift

echo "==> 'ip addr show' in qrouter netns on L3 node"
ip netns exec $(ip netns list | grep qrouter) ip addr show
echo "==> 'ip addr show' on VM(${vm})"
ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no $(nova show ${vm} | awk '/network/ {print $5}') -l cirros ip addr show
echo "==> 'uname -a' on VM(${vm})"
ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no $(nova show ${vm} | awk '/network/ {print $5}') -l cirros uname -a
echo "==> on VM(${vm})"
ip netns exec $(ip netns list | grep qrouter) ssh -o StrictHostKeyChecking=no $(nova show ${vm} | awk '/network/ {print $5}') -l cirros "test -f /etc/cirros/version && echo -n 'cirros version: ' && cat /etc/cirros/version"
