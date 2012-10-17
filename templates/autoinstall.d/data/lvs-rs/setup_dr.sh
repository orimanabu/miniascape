# Requirements: sysctl
# Author: Satoru SATOH <ssato@redhat.com>
# License: MIT
#
# References:
#
# * RHEL 6 LB Admin Guide:
#   * 3.2.1. Direct Routing and arptables_jf: http://red.ht/P9dQhy
#   * 3.2.2. Direct Routing and iptables: http://red.ht/Tutpvs
#
arptables -A IN  -d {{ lvs.virtual_ip }} -j DROP
arptables -A OUT -s {{ lvs.virtual_ip }} -j mangle --mangle-ip-s {{ lvs.real_ip }}

# TODO: alternative for arptables_jf:
#iptables -t nat -A PREROUTING -p <tcp|udp> -d <vip> --dport <port> -j REDIRECT

ip addr add {{ lvs.virtual_ip }} dev {{ lvs.device }}