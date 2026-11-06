# Learning log

## Day 1 — 2026-11-06

Goal: Read the brief and write a design that can be checked before any container is built.

Tried: Mapped the brief onto five containers (two firewalls, two Site A zone hosts, one collector), a documentation-range underlay, and a WireGuard tunnel. Drafted the address plan and the log path in `docs/topology.md` and `ASSUMPTIONS.md`.

Broke: Nothing deployed, so nothing failed in the lab yet. The open risk is assumption 8 and 9: whether a small Debian image with nftables, WireGuard, and rsyslog fits a 2-core Codespace, and whether WireGuard's kernel module is available in that Docker-in-Docker image.

Learned: The checkpoint order is design first (diagram and assumptions), then the build, then a requirement change. Tunnel encryption and encrypting the log payload are separate. Containerlab's Codespaces guide uses a `devcontainer-dind` image and notes that Codespaces cannot run VM-based nodes, which matches the brief's "containers only" rule. Source: the assessment PDF, [containerlab Codespaces manual](https://containerlab.dev/manual/codespaces/), and this Cursor session (AI). The address plan and tool choices still need to be verified by deploying them.

Next: Open the Codespace, deploy `topology.clab.yml`, and check that each node has the address in the plan. Do not start nftables rules until that succeeds.

Added after the first draft: `.devcontainer/devcontainer.json` pins `devcontainer-dind-slim:0.68.0` and asks for 2 cores. `topology.clab.yml` uses `ghcr.io/srl-labs/network-multitool` and sets addresses with `exec`, because the containerlab `ipv4` link field does not apply to `kind: linux`. Source for that limitation: the containerlab topology manual and the linux playground example.
