#!/bin/sh
# Build the tunnel, default-deny policy, and one log path.
# Run this inside the Codespace after: containerlab deploy -t topology.clab.yml
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
A=clab-hm-net-site-a-fw
B=clab-hm-net-site-b-fw
APP=clab-hm-net-app-01
MGMT=clab-hm-net-mgmt-01
COL=clab-hm-net-collector

echo "== packages"
for node in "$A" "$B" "$COL"; do
  docker exec "$node" apk add --no-cache nftables wireguard-tools rsyslog ulogd
done

echo "== keys"
docker exec "$A" sh -c 'umask 077; mkdir -p /etc/wireguard; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key'
docker exec "$B" sh -c 'umask 077; mkdir -p /etc/wireguard; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key'
PUBA="$(docker exec "$A" cat /etc/wireguard/public.key)"
PUBB="$(docker exec "$B" cat /etc/wireguard/public.key)"

echo "== tunnel"
docker exec "$A" sh -c "ip link del wg0 2>/dev/null || true
ip link add wg0 type wireguard
ip address add 10.255.0.1/30 dev wg0
wg set wg0 private-key /etc/wireguard/private.key listen-port 51820
wg set wg0 peer $PUBB allowed-ips 10.20.0.0/16,10.255.0.2/32 endpoint 192.0.2.2:51820
ip link set wg0 up
ip route replace 10.20.0.0/16 dev wg0
sysctl -w net.ipv4.ip_forward=1"
docker exec "$B" sh -c "ip link del wg0 2>/dev/null || true
ip link add wg0 type wireguard
ip address add 10.255.0.2/30 dev wg0
wg set wg0 private-key /etc/wireguard/private.key listen-port 51820
wg set wg0 peer $PUBA allowed-ips 10.10.0.0/16,10.255.0.1/32 endpoint 192.0.2.1:51820
ip link set wg0 up
ip route replace 10.10.0.0/16 dev wg0
sysctl -w net.ipv4.ip_forward=1"

echo "== host routes"
docker exec "$APP" ip route replace 10.10.20.0/24 via 10.10.10.1
docker exec "$APP" ip route replace 10.20.0.0/16 via 10.10.10.1
docker exec "$MGMT" ip route replace 10.10.10.0/24 via 10.10.20.1
docker exec "$MGMT" ip route replace 10.20.0.0/16 via 10.10.20.1
docker exec "$COL" ip route replace 10.255.0.0/30 via 10.20.10.1

echo "== tunnel ping before policy"
docker exec "$A" ping -c 2 -W 1 10.255.0.2

echo "== policy and logs"
docker cp "$ROOT/configs/site-a-fw.nft" "$A":/etc/nftables.nft
docker cp "$ROOT/configs/site-b-fw.nft" "$B":/etc/nftables.nft
docker cp "$ROOT/configs/ulogd.conf" "$A":/etc/ulogd.lab.conf
docker cp "$ROOT/configs/rsyslog-site-a.conf" "$A":/etc/rsyslog.lab.conf
docker cp "$ROOT/configs/rsyslog-collector.conf" "$COL":/etc/rsyslog.lab.conf
docker exec "$A" nft -f /etc/nftables.nft
docker exec "$B" nft -f /etc/nftables.nft
docker exec "$A" sh -c 'touch /var/log/nft.log; mkdir -p /var/log; pkill ulogd || true; pkill rsyslogd || true'
docker exec "$COL" sh -c 'mkdir -p /var/log; touch /var/log/site-a.log; chmod 666 /var/log/site-a.log; pkill rsyslogd || true'
docker exec "$A" ulogd -d -c /etc/ulogd.lab.conf
docker exec "$COL" rsyslogd -N1 -f /etc/rsyslog.lab.conf
docker exec "$A" rsyslogd -N1 -f /etc/rsyslog.lab.conf
docker exec "$COL" rsyslogd -f /etc/rsyslog.lab.conf
docker exec "$A" rsyslogd -f /etc/rsyslog.lab.conf

echo "== denied cross-zone ping"
docker exec "$APP" ping -c 2 -W 1 10.10.20.10 || true
sleep 2
echo "== site A log"
docker exec "$A" tail -n 5 /var/log/nft.log || true
echo "== collector log"
docker exec "$COL" tail -n 20 /var/log/site-a.log || true
echo "== wg"
docker exec "$A" wg show
