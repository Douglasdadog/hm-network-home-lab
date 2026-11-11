#!/bin/sh
# Tunnel setup for site-a-fw.
# Run inside the Codespace after containerlab deploy.
# Replace PEER_PUBLIC_KEY with the public key printed by site-b-fw.
# Private keys are generated inside the container and are not in this repo.
#
# To generate keys on site-a-fw first:
#   docker exec clab-hm-net-site-a-fw sh -c \
#     'umask 077; mkdir -p /etc/wireguard; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key; cat /etc/wireguard/public.key'

PEER_PUBLIC_KEY="<site-b-fw public key>"

docker exec clab-hm-net-site-a-fw sh -c "
ip link del wg0 2>/dev/null || true
ip link add wg0 type wireguard
ip address add 10.255.0.1/30 dev wg0
wg set wg0 private-key /etc/wireguard/private.key listen-port 51820
wg set wg0 peer ${PEER_PUBLIC_KEY} allowed-ips 10.20.0.0/16,10.255.0.2/32 endpoint 192.0.2.2:51820
ip link set wg0 up
ip route replace 10.20.0.0/16 dev wg0
sysctl -w net.ipv4.ip_forward=1
"

echo "== verify"
docker exec clab-hm-net-site-a-fw wg show
docker exec clab-hm-net-site-a-fw ping -c 2 -W 1 10.255.0.2
