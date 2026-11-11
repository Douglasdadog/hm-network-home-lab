# Readout Presentation Notes

Technical readout and architecture walkthrough for the Network Home Lab: Secure Log Transport practical assessment.

- **Presenter:** Douglas
- **Target Duration:** 20 Minutes (10m Demo & Walkthrough / 5m Concept / 5m Adaptability & Failure Analysis)
- **Lab Environment:** GitHub Codespaces (2-core machine, containerlab)

---

## 1. Executive Summary & Verification (Minutes 00:00 – 10:00)

### 1.1 Objective
- Interconnect two distinct administrative domains privately: Site A (Banking Data Center) and Site B (Log Processing Platform).
- Implement internal zone segmentation on Site A (Apps vs. Management).
- Securely transport firewall denial telemetry to Site B over an untrusted transport medium (`192.0.2.0/24`, RFC 5737).
- Maintain absolute zero public internet exposure (no host port publication).

### 1.2 Verification Commands
Live demonstration proving inter-zone drop and subsequent remote syslog telemetry receipt:

```bash
# 1. Trigger unauthorized cross-zone access (Apps -> Mgmt)
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10

# 2. Inspect Site B collector destination file
docker exec clab-hm-net-collector tail -n 2 /var/log/site-a.log
```

**Observed Telemetry:**
- `app-01` to `mgmt-01` packet transmission drops with 100% loss.
- `/var/log/site-a.log` registers: `hm-site-a IN=eth1 OUT=eth2 ... SRC=10.10.10.10 DST=10.10.20.10 PROTO=ICMP`.

### 1.3 Topology & Traffic Flow Summary
- **Network Boundaries:**
  - Site A Apps Zone: `10.10.10.0/24` (Gateway: `site-a-fw` eth1 `10.10.10.1`)
  - Site A Mgmt Zone: `10.10.20.0/24` (Gateway: `site-a-fw` eth2 `10.10.20.1`)
  - Inter-site Underlay: `192.0.2.0/24` (RFC 5737 simulated untrusted path)
  - Encrypted Tunnel: WireGuard point-to-point `10.255.0.0/30` over UDP `51820`
  - Site B Collector Zone: `10.20.10.0/24` (Collector IP: `10.20.10.10`)
- **Firewall Policy (`nftables`):**
  - Stateful default-deny (`policy drop` across input, forward, and output chains).
  - Cross-zone forward traffic dropped; matched packets evaluated via `NFLOG group 1`.
  - Local `ulogd` daemon buffers NFLOG netlink events to `/var/log/nft.log`.
  - `rsyslog` captures stream via `imfile` and forwards to Site B collector over TCP `514`.
- **Public Exposure Check:**
  - `docker ps` validates zero port redirects or published host ports (`0.0.0.0:*->*`).

---

## 2. Technical Deep Dive: Tunnel vs. Payload Encryption (Minutes 10:00 – 15:00)

Comparative evaluation of transport-layer vs. presentation/application-layer security boundaries:

| Dimension | Transport Tunnel Encryption | Application / Payload Encryption |
| :--- | :--- | :--- |
| **Protocol Used** | WireGuard (`UDP 51820`, ChaCha20-Poly1305) | Plain Syslog over TCP (`514`) vs TLS (`6514`) |
| **Protection Scope** | Secures hop-to-hop link across untrusted underlay (`192.0.2.0/24`). | Protects log record integrity and confidentiality end-to-end. |
| **Observation** | Packet sniffing on transit link yields only encrypted payloads. | Raw rsyslog traffic inside tunnel remains unencrypted plaintext. |
| **Architectural Threat** | Protects against ISP / transit network eavesdropping. | Leaves data vulnerable to lateral sniffers inside Site B post-decryption. |
| **Recommendation** | Layer application-level TLS (`RFC 5425`, port 6514) on top of VPN tunnels for zero-trust compliance. |

---

## 3. Resilience, Fault Analysis & Adaptation (Minutes 15:00 – 20:00)

### 3.1 Handling Project Variability & Requirements
- Project brief anticipated a requirement change mid-cycle.
- In accordance with baseline assumptions (`ASSUMPTIONS.md`), scope adjustments were kept modular.
- Policy rules and routing scripts are decoupled from containerlab topologies, enabling seamless adjustments (e.g., adding DMZ subnets or switching to TLS) without rebuilding infrastructure.

### 3.2 Observed Failure Modes & Operational Findings
Key takeaways from failure injection testing (`docs/failure-test.md`):

1. **Tunnel Invalidation (`ip link set wg0 down`):**
   - *Impact:* Site A dropped packets locally and continued logging to `/var/log/nft.log`. Remote delivery was suspended without dropping local security enforcement.
2. **Interface Flapping & Static Route Loss:**
   - *Finding:* Bringing the tunnel up (`ip link set wg0 up`) did not automatically reinstate the kernel route `10.20.0.0/16 dev wg0`.
   - *TCP State Stall:* `rsyslog`'s active TCP socket hung in a retry cycle without completing automatic reconnection post-link recovery.
   - *Remediation Applied:* Re-injected static route and restarted local `rsyslogd` instance.
3. **Architectural Improvements for Production:**
   - Eliminate bare static routing over virtual interfaces in favor of dynamic routing daemons (e.g., BGP via FRRouting) with bidirectional forwarding detection (BFD).
   - Leverage interface event triggers (`wg-quick` `PostUp`/`PostDown` or systemd-networkd) to ensure routing tables and streaming services self-heal automatically upon interface state changes.
