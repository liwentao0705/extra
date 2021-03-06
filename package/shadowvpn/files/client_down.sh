#!/bin/sh

# This script will be executed when client is down.
# All key value pairs in ShadowVPN config file will be passed to this script
# as environment variables, except password.

PID=$(cat $pidfile 2>/dev/null)
loger() {
	echo "$(date '+%c') down.$1 ShadowVPN[$PID] $2"
}

# Get uci setting
route_mode=$(uci get shadowvpn.@shadowvpn[-1].route_mode_save 2>/dev/null)

# Turn off NAT over VPN
iptables -t nat -D POSTROUTING -o $intf -j MASQUERADE
iptables -D FORWARD -o $intf -j ACCEPT
iptables -D FORWARD -i $intf -j ACCEPT
loger notice "Turn off NAT over $intf"

# Change routing table
ip route del $server
if [ "$route_mode" != 2 ]; then
	ip route del 0.0.0.0/1
	ip route del 128.0.0.0/1
	loger notice "Default route changed to original route"
fi

# Remove route rules
if [ -f /tmp/shadowvpn_routes ]; then
	sed -e "s/^/route del /" /tmp/shadowvpn_routes | ip -batch -
	loger notice "Route rules have been removed"
fi

rm -rf /tmp/shadowvpn_routes

loger info "Script $0 completed"
