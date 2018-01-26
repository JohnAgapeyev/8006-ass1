#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

ACCEPT_LIST='80,443,53,22,546,547,647,847'
DROP_LIST='0'

#Drop tcp existing rules
iptables -F

#Drop tcp existing non-default chains
iptables -X

iptables -N WEBSSH
iptables -N REST

#Set drop policy as default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Accounting forwarding rules
iptables -A INPUT -m tcp -p tcp --sport www -j WEBSSH
iptables -A INPUT -m tcp -p tcp --dport www -j WEBSSH
iptables -A INPUT -m tcp -p tcp --sport ssh -j WEBSSH
iptables -A INPUT -m tcp -p tcp --dport ssh -j WEBSSH
iptables -A OUTPUT -m tcp -p tcp --sport www -j WEBSSH
iptables -A OUTPUT -m tcp -p tcp --dport www -j WEBSSH
iptables -A OUTPUT -m tcp -p tcp --sport ssh -j WEBSSH
iptables -A OUTPUT -m tcp -p tcp --dport ssh -j WEBSSH

#Forward tcp other traffic to REST
iptables -A INPUT -p tcp -j REST

iptables -A REST -m tcp -p tcp --sport :1023 -j DROP
iptables -A REST -m tcp -p tcp --sport 0 -j DROP
iptables -A REST -m tcp -p tcp --dport 0 -j DROP

IFS=',' read -ra ACCEPT <<< "$ACCEPT_LIST"
for i in "${ACCEPT[@]}"; do
    # process "$i"
    echo $i
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j ACCEPT
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j ACCEPT

    iptables -A REST -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A REST -m tcp -p tcp --dport $i -j ACCEPT
    iptables -A REST -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A REST -m tcp -p tcp --dport $i -j ACCEPT
done

IFS=',' read -ra DROP <<< "$DROP_LIST"
for i in "${DROP[@]}"; do
    # process "$i"
    echo $i
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j DROP
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j DROP
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j DROP
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j DROP

    iptables -A REST -m tcp -p tcp --sport $i -j DROP
    iptables -A REST -m tcp -p tcp --dport $i -j DROP
    iptables -A REST -m tcp -p tcp --sport $i -j DROP
    iptables -A REST -m tcp -p tcp --dport $i -j DROP
done


