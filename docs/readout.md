# Readout

20 minutes. Say this in your own words. The commands are the only things to type.

## 10 minutes: result, then how

Start the same Codespace. Do not create a new one.

```powershell
gh codespace ssh -c hm-net-4j65j45p5qrp37rgv
```

If the lab was destroyed or the Codespace was recreated, rebuild first:

```bash
cd /workspaces/hm-network-home-lab
containerlab deploy -t topology.clab.yml --reconfigure
sh scripts/bringup-core.sh
```

Demo:

```bash
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 1 /var/log/site-a.log
```

Say: the ping fails, and the collector still receives the firewall line. The line shows `SRC=10.10.10.10` and `DST=10.10.20.10`.

Then the path, in this order:

1. `app-01` is `10.10.10.10` in the apps zone. `mgmt-01` is `10.10.20.10`. The host has a route via `10.10.10.1`, so the packet hits `site-a-fw`.
2. The forward chain on `site-a-fw` drops it and logs it with NFLOG group 1. ulogd writes `/var/log/nft.log`.
3. rsyslog on that firewall sends the line with TCP to `10.20.10.10` port `514`. The source is the tunnel address `10.255.0.1`.
4. WireGuard carries that TCP session to `192.0.2.2` port `51820`. `192.0.2.0/24` is documentation space standing in for an untrusted network. Nothing is published on the Codespace.
5. `site-b-fw` allows only that TCP flow to the collector. The collector appends `/var/log/site-a.log`.

If they ask what a zone host can reach: `app-01` cannot reach `mgmt-01` or the collector. TCP 22 from the firewall to the collector times out.

## 5 minutes: one concept

Teach the difference between the tunnel and the log.

WireGuard encrypts the path. TCP 514 inside it is still plain text. Someone who is on the tunnel can read the log line. Encrypting the line itself would be rsyslog TLS to port 6514, and that is not built. The rsyslog warnings during startup say the same thing: stream driver mode 0 is plain TCP.

## 5 minutes: the requirement change

This has not arrived. Say that. Do not invent a change.

When it does arrive, the talk is three sentences: what it changed, which file you edited, and what you would have designed differently on day 1. Re-run the ping and the `tail` after the edit. A change that stops the collector line is not done.

## Failure question, if they ask

`ip link set wg0 down` on `site-a-fw`. The deny still happens and Site A still logs it. The collector file stops growing. Bringing the interface up is not enough: the route `10.20.0.0/16 dev wg0` has to be added again, and rsyslog on Site A has to be started again. Details are in `docs/failure-test.md`.
