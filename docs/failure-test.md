# Failure test

Run on 2026-11-06 in Codespace `hm-net`, after `containerlab deploy --reconfigure` and `sh scripts/bringup-core.sh`. The collector file had 2 lines before the test. Both lines were the denied ping from `10.10.10.10` to `10.10.20.10`.

## What was done

```bash
docker exec clab-hm-net-site-a-fw ip link set wg0 down
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.10.20.10
```

## What still happened

The ping still failed. Site A still wrote the deny. `/var/log/nft.log` on `site-a-fw` gained two new lines, `ID=17 SEQ=1` and `SEQ=2`, at 12:13:27 and 12:13:28. The zones are on that firewall, so the tunnel is not required for the drop or the local log.

## What was lost

`/var/log/site-a.log` on the collector stayed at 2 lines. Those two new denies did not arrive while `wg0` was down.

`ip link set wg0 up` did not finish the repair. The route `10.20.0.0/16 dev wg0` was gone, and it did not come back with the interface. The collector stayed at 2 lines until that route was added again and `rsyslogd` on `site-a-fw` was started again. After that, the file grew from 2 lines to 7, including a new deny at 12:14:24.

## How to detect it

Use two checks together:

- On `site-a-fw`, `ip -br link show wg0` says `DOWN`, or `ip route` has no `10.20.0.0/16 dev wg0`.
- `/var/log/nft.log` on Site A is still growing, and `/var/log/site-a.log` on the collector is not.

`wg show` is a weak signal by itself. While the interface was down it still printed a handshake from 27 seconds earlier.

## How to repair it

```bash
docker exec clab-hm-net-site-a-fw ip link set wg0 up
docker exec clab-hm-net-site-a-fw ip route replace 10.20.0.0/16 dev wg0
docker exec clab-hm-net-site-a-fw pkill rsyslogd
docker exec clab-hm-net-site-a-fw rsyslogd -f /etc/rsyslog.lab.conf
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 1 /var/log/site-a.log
```

The last line must be newer than the outage.
