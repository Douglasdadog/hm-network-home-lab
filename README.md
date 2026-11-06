# hm-network-home-lab

Private two-site lab: Site A is zoned behind a firewall, Site B receives its firewall logs, and the only path between them is a site-to-site tunnel. Nothing in the lab is published to the public internet.

This runs in GitHub Codespaces with [containerlab](https://containerlab.dev/manual/codespaces/). Each site, firewall, and server is a Linux container. Firewall policy is nftables. The tunnel is WireGuard. The collector is rsyslog.

## Status

The Codespaces environment and an empty containerlab topology are in the repo. Firewall rules and the tunnel are not.

| Doc | What it is |
| --- | --- |
| [topology.clab.yml](topology.clab.yml) | Five nodes, four links, addresses only |
| [docs/topology.md](docs/topology.md) | IP plan, zones, and the path a log takes |
| [ASSUMPTIONS.md](ASSUMPTIONS.md) | Every assumption the design depends on |
| [LEARNING.md](LEARNING.md) | Short daily notes |

## Run

Use a 2-core Codespace. In GitHub, set the Codespaces idle timeout to 10 minutes, and stop the codespace when you step away.

From the codespace terminal:

```bash
containerlab deploy -t topology.clab.yml
containerlab inspect -t topology.clab.yml
```

A node is up when `ip address` inside it shows the address from `docs/topology.md`. `eth0` is containerlab's management interface. The lab addresses are on `eth1` and, for the firewalls, the later interfaces.

```bash
containerlab destroy -t topology.clab.yml
```

## Ground rules carried into this repo

- Address space is private ranges plus the RFC 5737 documentation range on the simulated untrusted link.
- No real organization names, copied production configs, or credentials.
- The commit history is part of the work. Commit as the lab changes.
- AI assistance is logged in `LEARNING.md` and still has to be checked against the tools' own docs.
