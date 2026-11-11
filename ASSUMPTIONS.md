#Assumptions

1. **Site A Zone Segmentation:** Site A is scoped to two internal broadcast domains: `apps` (`10.10.10.0/24`) and `mgmt` (`10.10.20.0/24`). `site-a-fw` acts as the default gateway terminating both subnets and enforces inter-zone isolation.
2. **Untrusted Underlay Transport:** The transit link interconnecting the sites uses RFC 5737 documentation space (`192.0.2.0/24`) to simulate an untrusted transport medium. Container management network `eth0` (`172.20.20.0/24`) is strictly for tool provisioning and is not routable to the lab data plane.
3. **Site-to-Site Tunneling:** WireGuard point-to-point interface `wg0` (`10.255.0.0/30`) over UDP `51820` provides layer-3 cryptographic encapsulation across the transit link.
4. **Log Transport Protocol:** Core firewall drop telemetry is transmitted using TCP `514` to prevent unacknowledged log loss during transit. Telemetry is sourced from the firewall's tunnel IP (`10.255.0.1`) and directed to the collector (`10.20.10.10`).
5. **Site B Platform Architecture:** Site B consists of a single management zone (`10.20.10.0/24`) hosting the log collector behind `site-b-fw`.
6. **Firewall Policy Baseline:** Both firewalls operate on stateful default-deny (`policy drop` on input, forward, and output chains). The only permitted inter-site transit flow is WireGuard UDP `51820` on the underlay and TCP `514` inside the tunnel.
7. **Ephemeral Cryptographic Material:** Private keys are generated dynamically inside containers at initialization and are excluded from git repositories.
8. **Container Host Isolation:** Standard nftables logging is diverted via `NFLOG group 1` to `ulogd` to isolate packet records within container network namespaces and prevent host kernel buffer (`dmesg`) leakage.
9. **Infrastructure Footprint:** Built within GitHub Codespaces free-tier constraints (2-core architecture, 10-minute idle timeouts).
10. **Data Privacy:** All network addresses utilize RFC 1918 private ranges or RFC 5737 documentation blocks. Host port publishing (`ports:`) is disabled.
