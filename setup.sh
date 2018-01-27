#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

TCP_ACCEPT='80, 443, 22, 546, 547, 647, 847'
UDP_ACCEPT='53, 22, 546, 547, 647, 847'
TCP_DROP='0'
UDP_DROP='0'

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

#Forward all other traffic to REST
iptables -A INPUT -p all -j REST
iptables -A OUTPUT -p all -j REST

iptables -A REST -m tcp -p tcp --sport :1023 --dport 80 -j DROP

IFS=',' read -ra ACCEPT <<< "$TCP_ACCEPT"
for i in "${ACCEPT[@]}"; do
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j ACCEPT
    iptables -A REST -m tcp -p tcp --sport $i -j ACCEPT
    iptables -A REST -m tcp -p tcp --dport $i -j ACCEPT
done
IFS=',' read -ra DROP <<< "$TCP_DROP"
for i in "${DROP[@]}"; do
    iptables -A WEBSSH -m tcp -p tcp --sport $i -j DROP
    iptables -A WEBSSH -m tcp -p tcp --dport $i -j DROP
    iptables -A REST -m tcp -p tcp --sport $i -j DROP
    iptables -A REST -m tcp -p tcp --dport $i -j DROP
done
IFS=',' read -ra ACCEPT <<< "$UDP_ACCEPT"
for i in "${ACCEPT[@]}"; do
    iptables -A WEBSSH -m udp -p udp --sport $i -j ACCEPT
    iptables -A WEBSSH -m udp -p udp --dport $i -j ACCEPT
    iptables -A REST -m udp -p udp --sport $i -j ACCEPT
    iptables -A REST -m udp -p udp --dport $i -j ACCEPT
done
IFS=',' read -ra DROP <<< "$UDP_DROP"
for i in "${DROP[@]}"; do
    iptables -A WEBSSH -m udp -p udp --sport $i -j DROP
    iptables -A WEBSSH -m udp -p udp --dport $i -j DROP
    iptables -A REST -m udp -p udp --sport $i -j DROP
    iptables -A REST -m udp -p udp --dport $i -j DROP
done
