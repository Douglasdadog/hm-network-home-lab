# hm-network-home-lab

Private two-site lab: Site A is zoned behind a firewall, Site B receives its firewall logs, and the only path between them is a site-to-site tunnel. Nothing in the lab is published to the public internet.

This runs in GitHub Codespaces with [containerlab](https://containerlab.dev/manual/codespaces/). Each site, firewall, and server is a Linux container. Firewall policy is `nftables`. The tunnel is `WireGuard`. The collector is `rsyslog`.

---

## Deliverables & Documentation Index

| File | Purpose |
| :--- | :--- |
| [topology.clab.yml](topology.clab.yml) | Containerlab topology definition (5 nodes, 4 inter-site links) |
| [docs/topology.md](docs/topology.md) | Network architecture, IP address plan, and packet traversal diagrams |
| [ASSUMPTIONS.md](ASSUMPTIONS.md) | Stated engineering assumptions and technical justifications |
| [LEARNING.md](LEARNING.md) | Daily engineering log (Goal, Tried, Broke, Learned, Next) |
| [docs/runbook.md](docs/runbook.md) | Operational runbook covering top 3 failure modes, symptoms, and remediation |
| [docs/failure-test.md](docs/failure-test.md) | Tunnel failure injection experiment, telemetry loss analysis, and recovery |
| [docs/readout.md](docs/readout.md) | 20-minute technical readout notes and architecture walkthrough |

---

## How to Replicate and Rebuild This Lab

Anyone can rebuild and verify this exact lab from scratch in GitHub Codespaces by following these step-by-step instructions.

### Prerequisites & Free Quota Management
- Use the standard **2-core machine** (`basicLinux32gb`) to conserve monthly free quota.
- In `github.com/settings/codespaces`, set the idle timeout to **10 minutes**.
- Stop the Codespace when stepping away (`gh codespace stop`).

---

### Step 1: Launch Codespace
1. Navigate to [https://github.com/Douglasdadog/hm-network-home-lab](https://github.com/Douglasdadog/hm-network-home-lab).
2. Click the green **Code** button, select the **Codespaces** tab, and click **Create codespace on main**.
3. Wait for the browser terminal to initialize inside `/workspaces/hm-network-home-lab`.

---

### Step 2: Deploy Network Topology & Provision Lab Services
Run the following two commands in the Codespace terminal:

```bash
# 1. Instantiate the five containers and virtual links via containerlab
containerlab deploy -t topology.clab.yml --reconfigure

# 2. Configure WireGuard tunnel, host routes, nftables firewall rules, and syslog services
sh scripts/bringup-core.sh
```

> **Note on `--reconfigure`:** Required when redeploying existing containers to ensure interface IP assignments are applied cleanly.

---

### Step 3: Verify the Security Policy & Telemetry Pipeline
Run the verification check to prove inter-zone isolation and secure log shipping:

```bash
# 1. Trigger an unauthorized cross-zone connection attempt (Apps -> Mgmt)
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10

# 2. Inspect the Site B collector log file
docker exec clab-hm-net-collector tail -n 2 /var/log/site-a.log
```

**Expected Results:**
1. **Packet Loss:** Ping fails with `100% packet loss` (packet dropped at `site-a-fw`).
2. **Log Received:** The collector displays a log record tagged `hm-site-a` containing:
   `IN=eth1 OUT=eth2 ... SRC=10.10.10.10 DST=10.10.20.10 PROTO=ICMP`.

---

### Step 4: Verify Zero Public Exposure
Confirm that no container ports are exposed or published to the host/internet:

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

**Expected Result:** The `PORTS` column contains no host port bindings (no `0.0.0.0:*->*` or arrow redirections).

---

### Step 5: Teardown & Clean Up
When testing is complete, destroy the lab instances:

```bash
containerlab destroy -t topology.clab.yml
```

---

## Ground Rules & Constraints Carried Into This Repo
- **IP Addressing:** Strictly utilizes RFC 1918 private subnets and RFC 5737 documentation space (`192.0.2.0/24`) for the transit link.
- **Privacy:** No real organization names, production configurations, or credentials anywhere in the repository.
- **Security:** Private cryptographic keys are generated ephemerally inside containers upon startup and are excluded from git version control.
