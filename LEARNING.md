# Learning log

## Day 1 — 2026-11-06

Goal: Read the brief and write a design that can be checked before any container is built.

Tried: Mapped the brief onto five containers (two firewalls, two Site A zone hosts, one collector), a documentation-range underlay, and a WireGuard tunnel. Drafted the address plan and the log path in `docs/topology.md` and `ASSUMPTIONS.md`.

Broke: The first running containers had only `eth0` until `containerlab deploy --reconfigure`. WireGuard refused a ping to `10.255.0.2` until that address was in the peer allowed list. The collector did not create `/var/log/site-a.log` on its own.

Learned: The checkpoint order is design first (diagram and assumptions), then the build, then a requirement change. Tunnel encryption and encrypting the log payload are separate. Containerlab's Codespaces guide uses a `devcontainer-dind` image and notes that Codespaces cannot run VM-based nodes, which matches the brief's "containers only" rule. Source: the assessment PDF, [containerlab Codespaces manual](https://containerlab.dev/manual/codespaces/), and this Cursor session (AI). The address plan and tool choices still need to be verified by deploying them.

Next: The core path now runs. A later day covers the requirement change, then the readout.

Added after the design draft: the first containers came up with only `eth0` because a second deploy refused to replace them. `containerlab deploy --reconfigure` created `eth1` and the later interfaces, and the zone pings succeeded. WireGuard's kernel interface works in this Codespace. A ping to `10.255.0.2` failed with "Required key not available" until that address was added to the peer `allowed-ips`. A plain nftables log was not used. NFLOG group 1 plus ulogd wrote `/var/log/nft.log`, and rsyslog forwarded it with TCP to `10.20.10.10:514`. The collector file stayed missing until it existed and was writable. After that, the deny line arrived. Source: this Codespace, the containerlab deploy output, and the rsyslog 8.2608 warnings. AI drafted the rules; the checks above are what confirmed them.

Added after the first draft: `.devcontainer/devcontainer.json` pins `devcontainer-dind-slim:0.68.0` and asks for 2 cores. `topology.clab.yml` uses `ghcr.io/srl-labs/network-multitool` and sets addresses with `exec`, because the containerlab `ipv4` link field does not apply to `kind: linux`. Source for that limitation: the containerlab topology manual and the linux playground example.
