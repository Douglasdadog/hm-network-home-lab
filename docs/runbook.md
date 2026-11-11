# Runbook

Three failures actually hit during the build. Each entry has: the symptom, the command that proved it, and the command that fixed it.

## Failure 1: Containers had only `eth0` after the first deploy

**Symptom.** After `containerlab deploy -t topology.clab.yml`, `ip -br address` on `site-a-fw` showed only `eth0`. The lab interfaces (`eth1`, `eth2`, `eth3`) were absent. Zone pings failed immediately.

**Prove it.**

```bash
docker exec clab-hm-net-site-a-fw ip -br address
```

Output shows only `lo` and `eth0`. No `eth1` through `eth3`.

**Fix it.**

```bash
containerlab deploy -t topology.clab.yml --reconfigure
```

`--reconfigure` is required when the containers already exist from an earlier run. Without it, containerlab skips the `exec` block that sets up the interfaces and addresses. After `--reconfigure`, the five addresses appear and zone pings pass.

> Note in `README.md`: the first deploy of a fresh Codespace can omit `--reconfigure`. Every subsequent deploy needs it.

---

## Failure 2: WireGuard tunnel ping failed with "Required key not available"

**Symptom.** After the tunnel interfaces were configured and brought up, `ping -c 2 10.255.0.2` from `site-a-fw` returned `RTNETLINK answers: Required key not available` and lost every packet. `wg show` showed the peer but no handshake.

**Prove it.**

```bash
docker exec clab-hm-net-site-a-fw wg show
```

The peer line shows `allowed ips: 10.20.0.0/16` only. The tunnel address `10.255.0.2/32` is not in the list.

**Fix it.**

Add the tunnel peer addresses to `AllowedIPs` on both sides:

```bash
# On site-a-fw: peer may also send from its own tunnel address
wg set wg0 peer <PUBB> allowed-ips 10.20.0.0/16,10.255.0.2/32

# On site-b-fw: peer may also send from its own tunnel address
wg set wg0 peer <PUBA> allowed-ips 10.10.0.0/16,10.255.0.1/32
```

WireGuard `AllowedIPs` controls which source addresses are accepted from that peer, not just which routes to inject. A packet sourced from `10.255.0.1` is dropped by the peer unless `10.255.0.1/32` is in the list. The syslog connection is sourced from that address, so without this entry the log path also silently fails. `bringup-core.sh` now includes both `/32` entries.

---

## Failure 3: Collector file stopped growing after tunnel repair

**Symptom.** After `ip link set wg0 down` (failure test) and then `ip link set wg0 up`, `/var/log/nft.log` on `site-a-fw` kept growing with new denies, but `/var/log/site-a.log` on the collector stayed frozen. The tunnel appeared to be back up.

**Prove it.**

```bash
# On site-a-fw: local log is growing
docker exec clab-hm-net-site-a-fw tail -n 3 /var/log/nft.log

# On collector: file has not changed
docker exec clab-hm-net-collector tail -n 3 /var/log/site-a.log

# Route is gone
docker exec clab-hm-net-site-a-fw ip route show
```

`ip route show` has no `10.20.0.0/16 dev wg0` line. `wg show` may still print an old handshake timestamp, which is a weak signal.

**Fix it.**

Three actions in order:

```bash
# 1. Bring the interface up (if not already)
docker exec clab-hm-net-site-a-fw ip link set wg0 up

# 2. Put the route back — it does not return automatically
docker exec clab-hm-net-site-a-fw ip route replace 10.20.0.0/16 dev wg0

# 3. Restart rsyslog on site-a-fw — it lost the TCP session and does not reconnect on its own
docker exec clab-hm-net-site-a-fw pkill rsyslogd
docker exec clab-hm-net-site-a-fw rsyslogd -f /etc/rsyslog.lab.conf

# 4. Produce a new deny and confirm delivery
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 1 /var/log/site-a.log
```

The last line must be newer than the outage. If it is not, check `ip -br link show wg0` before restarting rsyslog.

**Root cause.** When `wg0` goes down, the kernel removes the route `10.20.0.0/16 dev wg0`. Bringing the interface back up does not restore it. rsyslog's TCP forwarding action enters a retry loop but does not reconnect after the route returns unless the daemon is restarted.
