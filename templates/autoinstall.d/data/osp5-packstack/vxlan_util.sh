#!/bin/sh

source ./subr.sh

vni=99
vtep=eth1
bridge=br-vxlan${vni}
mcgroup=239.0.${vni}.1
mcport=4789
addr_ssh=(10.0.1.13 10.0.1.23)
addr_vtep=(172.16.${vni}.1 172.16.${vni}.2)
addr_vxlan=(192.168.${vni}.1 192.168.${vni}.2)
addr_vm=(192.168.122.11 192.168.122.12)

if [ "$#" -lt 1 ]; then
	echo "$0 cmd arg"
	exit 1
fi
cmd=$1; shift
arg=$1; shift

echo "* vni=${vni}"
echo "* vtep=${vtep}"
echo "* bridge=${bridge}"
echo "* mcgroup=${mcgroup}"
echo "* mcport=${mcport}"

echo "=> ${cmd} ${arg}"
case ${cmd} in
ping)
	ip -o -4 addr show dev ${vtep} | grep ${addr_vtep[0]} > /dev/null 2>&1
	if [ x"$?" = x"0" ]; then
		target=${addr_vxlan[1]}
	else
		target=${addr_vxlan[0]}
	fi
	echo "==> target: ${target}"
	do_command ping -c 3 -W 3 ${target}
	;;
dump|capture)
	flavor=pcap
	if [ x"${arg}" != x ]; then
		flavor=${arg}
	fi
	pcap=${flavor}.pcap
	do_command tcpdump -i ${vtep} -w ${pcap}
	;;
stat)
	for i in 0 1; do
		node="node$((i+1))"
		addr=${addr_ssh[$i]}
		echo "==> ${node}"
		do_command -r ${addr} ip link show
		do_command -r ${addr} ip -d link show dev vxlan${vni}
		do_command -r ${addr} ip neigh show
		do_command -r ${addr} ip addr show
		do_command -r ${addr} ip route show
		do_command -r ${addr} ip maddr show dev ${vtep}
		do_command -r ${addr} bridge fdb show
		do_command -r ${addr} firewall-cmd --list-all
		do_command -r ${addr} brctl show
		do_command -r ${addr} brctl showmacs ${bridge}
		do_command -r ${addr} ovs-vsctl show
		do_command -r ${addr} ovs-ofctl dump-flows ${bridge}
		do_command -r ${addr} ovs-ofctl dump-ports-desc ${bridge}
	done
	;;
init)
	for i in 0 1; do
		node="node$((i+1))"
		addr=${addr_ssh[$i]}
		echo "==> ${node}"
		do_command -r ${addr} ip addr add ${addr_vtep[$i]}/24 dev ${vtep}
		do_command -r ${addr} ip link set up dev ${vtep}
		#do_command -r ${addr} ip route add 224.0.0.0/4 dev ${vtep}
		do_command -r ${addr} ip link add vxlan${vni} type vxlan id ${vni} group ${mcgroup} dstport ${mcport} ttl 1 dev ${vtep}
		do_command -r ${addr} ip link set up dev vxlan${vni}
		#do_command -r ${node1} "firewall-cmd --add-rich-rule='rule family=\"ipv4\" destination address=\"224.0.0.0/4\" port port=\"${mcport}\" protocol=\"udp\" log prefix=\"vxlan mcast\" level=\"info\" limit value=\"1/m\" accept'"
		#do_command -r ${node1} "firewall-cmd --add-rich-rule='rule family=\"ipv4\" destination address=\"172.16.0.0/24\" port port=\"${mcport}\" protocol=\"udp\" log prefix=\"vxlan mcast\" level=\"info\" limit value=\"1/m\" accept'"
		do_command -r ${addr} firewall-cmd --add-source 224.0.0.0/4
		do_command -r ${addr} firewall-cmd --add-port ${mcport}/udp
	done
	;;
phys|primitive)
	case ${arg} in
	start|create)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} ip addr add ${addr_vxlan[$i]}/24 dev vxlan${vni}
		done
		;;
	stop|delete|destroy)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} ip addr del ${addr_vxlan[$i]}/24 dev vxlan${vni}
		done
		;;
	esac
	;;
br|bridge)
	case ${arg} in
	start|create)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} brctl addbr ${bridge}
			do_command -r ${addr} brctl addif ${bridge} vxlan${vni}
			do_command -r ${addr} ip link set up dev ${bridge}
		done
		;;
	stop|delete|destroy)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} ip link set down dev ${bridge}
			do_command -r ${addr} brctl delif ${bridge} vxlan${vni}
			do_command -r ${addr} brctl delbr ${bridge}
		done
		;;
	esac
	;;
ovs-linux)
	echo "=> ovs + linux vxlan"
	case ${arg} in
	start|create)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} systemctl start openvswitch
			do_command -r ${addr} 'ovs-vsctl list-br | while read line; do ovs-vsctl del-br ${line}; done'
			do_command -r ${addr} ovs-vsctl add-br ${bridge}
			do_command -r ${addr} ovs-vsctl add-port ${bridge} vxlan${vni}
			do_command -r ${addr} ip link set up dev ${bridge}
		done
		;;
	stop|delete|destroy)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} ip link set down dev ${bridge}
			do_command -r ${addr} ovs-vsctl del-port ${bridge} vxlan${vni}
			do_command -r ${addr} ovs-vsctl del-br ${bridge}
			do_command -r ${addr} systemctl stop openvswitch
		done
		;;
	esac
	;;
ovs-only)
	echo "=> ovs-only vxlan"
	case ${arg} in
	start|create)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			if [ x"$i" == x"0" ]; then
				remote_vtep=${addr_vtep[1]}
			else
				remote_vtep=${addr_vtep[0]}
			fi
			echo "==> ${node}"
			do_command -r ${addr} ip addr add ${addr_vtep[$i]}/24 dev ${vtep}
			do_command -r ${addr} ip link set up dev ${vtep}
			do_command -r ${addr} firewall-cmd --add-port ${mcport}/udp
			do_command -r ${addr} systemctl start openvswitch
			do_command -r ${addr} 'ovs-vsctl list-br | while read line; do ovs-vsctl del-br ${line}; done'
			do_command -r ${addr} ovs-vsctl add-br ${bridge}
			do_command -r ${addr} ovs-vsctl add-port ${bridge} vxlan${vni} -- set interface vxlan${vni} type=vxlan options:remote_ip=${remote_vtep} options:key=${vni}
			do_command -r ${addr} ip link set up dev ${bridge}
		done
		;;
	stop|delete|destroy)
		for i in 0 1; do
			node="node$((i+1))"
			addr=${addr_ssh[$i]}
			echo "==> ${node}"
			do_command -r ${addr} ip link set down dev ${bridge}
			do_command -r ${addr} ovs-vsctl del-port ${bridge} vxlan${vni}
			do_command -r ${addr} ovs-vsctl del-br ${bridge}
			do_command -r ${addr} systemctl stop openvswitch
			do_command -r ${addr} ip link set down dev ${vtep}
			do_command -r ${addr} ip addr del ${addr_vtep[$i]}/24 dev ${vtep}
		done
		;;
	esac
	;;
esac

#    <interface type='bridge'>
#      <mac address='52:54:00:64:a8:84'/>
#      <source bridge='br-vxlan99'/>
#      <virtualport type='openvswitch'/>
#      <model type='virtio'/>
#      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
#    </interface>
