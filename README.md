# hm-network-home-lab

Private two-site lab: Site A is zoned behind a firewall, Site B receives its firewall logs, and the only path between them is a site-to-site tunnel. Nothing in the lab is published to the public internet.

This runs in GitHub Codespaces with [containerlab](https://containerlab.dev/manual/codespaces/). Each site, firewall, and server is a Linux container. Firewall policy is nftables. The tunnel is WireGuard. The collector is rsyslog.

## Status

The core path has been run once in Codespace `hm-net`: five nodes, a WireGuard tunnel, default deny, and one Site A firewall line stored on the collector. Rebuild it with the commands below. Private keys are generated inside the containers and are not in this repo.

| Doc | What it is |
| --- | --- |
| [topology.clab.yml](topology.clab.yml) | Five nodes, four links, addresses only |
| [docs/topology.md](docs/topology.md) | IP plan, zones, and the path a log takes |
| [ASSUMPTIONS.md](ASSUMPTIONS.md) | Every assumption the design depends on |
| [LEARNING.md](LEARNING.md) | Short daily notes |
| [docs/failure-test.md](docs/failure-test.md) | What the tunnel outage lost, and how it was repaired |
| [docs/runbook.md](docs/runbook.md) | Three failures hit during the build: symptom, proof, fix |
| [docs/readout.md](docs/readout.md) | What to say in the 20 minutes |

## Run

Use a 2-core Codespace. In GitHub, set the Codespaces idle timeout to 10 minutes, and stop the codespace when you step away.

From the Codespace terminal, in `/workspaces/hm-network-home-lab`:

```bash
containerlab deploy -t topology.clab.yml --reconfigure
sh scripts/bringup-core.sh
```

`--reconfigure` is required when the containers already exist. The first deploy of a fresh Codespace can omit it.

Prove the log path:

```bash
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 5 /var/log/site-a.log
```

The ping loses every packet. The collector file contains a line tagged `hm-site-a` with `SRC=10.10.10.10` and `DST=10.10.20.10`.

`eth0` is containerlab's management network, `172.20.20.0/24`. The lab addresses are on the later interfaces. `docker ps` must not show a host port mapping such as `0.0.0.0:80->80`.

```bash
containerlab destroy -t topology.clab.yml
```

## Ground rules carried into this repo

- Address space is private ranges plus the RFC 5737 documentation range on the simulated untrusted link.
- No real organization names, copied production configs, or credentials.
- The commit history is part of the work. Commit as the lab changes.
- AI assistance is logged in `LEARNING.md` and still has to be checked against the tools' own docs.
