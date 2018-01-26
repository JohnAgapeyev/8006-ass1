#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ACCEPT_LIST='80,443,53,22,546,547,647,847'
DROP_LIST='0'

#Drop all existing rules
iptables -F

#Drop all existing non-default chains
iptables -X

iptables -N web_and_ssh
iptables -N rest_traffic

#Set drop policy as default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -P web_and_ssh DROP
iptables -P rest_traffic DROP

#Accounting forwarding rules
iptables -A INPUT -m tcp -p tcp --sport www -j web_and_ssh
iptables -A INPUT -m tcp -p tcp --dport www -j web_and_ssh
iptables -A INPUT -m tcp -p tcp --sport ssh -j web_and_ssh
iptables -A INPUT -m tcp -p tcp --dport ssh -j web_and_ssh
iptables -A OUTPUT -m tcp -p tcp --sport www -j web_and_ssh
iptables -A OUTPUT -m tcp -p tcp --dport www -j web_and_ssh
iptables -A OUTPUT -m tcp -p tcp --sport ssh -j web_and_ssh
iptables -A OUTPUT -m tcp -p tcp --dport ssh -j web_and_ssh

#Forward all other traffic to rest_traffic
iptables -A INPUT -p all -j rest_traffic

iptables -A rest_traffic -m tcp -p all --sport :1023 -j DROP
iptables -A rest_traffic -m tcp -p all --sport 0 -j DROP
iptables -A rest_traffic -m tcp -p all --dport 0 -j DROP

IFS=',' read -ra ACCEPT <<< "$ACCEPT_LIST"
for i in "${ACCEPT[@]}"; do
    # process "$i"
    echo $i
    iptables -A INPUT -m tcp -p all --sport $i -j ACCEPT
    iptables -A INPUT -m tcp -p all --dport $i -j ACCEPT
    iptables -A OUTPUT -m tcp -p all --sport $i -j ACCEPT
    iptables -A OUTPUT -m tcp -p all --dport $i -j ACCEPT
done

IFS=',' read -ra DROP <<< "$DROP_LIST"
for i in "${DROP[@]}"; do
    # process "$i"
    echo $i
    iptables -A INPUT -m tcp -p all --sport $i -j DROP
    iptables -A INPUT -m tcp -p all --dport $i -j DROP
    iptables -A OUTPUT -m tcp -p all --sport $i -j DROP
    iptables -A OUTPUT -m tcp -p all --dport $i -j DROP
done


