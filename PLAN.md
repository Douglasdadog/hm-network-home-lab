# Master plan

Finish the core before any stretch item. The core is a private tunnel, two zones on Site A, and one Site A firewall log stored on the Site B collector. The readout shows that path, teaches one concept, and explains the requirement change.

Run each remaining step in order. Do not start a step until the previous "Pass" check is true. After each step that changes the lab, commit and add a `LEARNING.md` entry.

You are here: the core path rebuilds from `scripts/bringup-core.sh`, and the tunnel failure test is written in `docs/failure-test.md`. The readout script is `docs/readout.md`. The requirement change has not arrived. Do not start `humble parakeet`.

## Facts, so the commands stay exact

| Item | Value |
| --- | --- |
| GitHub user | `Douglasdadog` |
| Repo | https://github.com/Douglasdadog/hm-network-home-lab |
| Visibility | Public. It is not private. |
| Branch | `main` |
| Codespace display name | `hm-net` |
| Codespace name | `hm-net-4j65j45p5qrp37rgv` |
| Machine | `basicLinux32gb` (2 cores, 8 GB RAM, 32 GB storage) |
| This Codespace's idle timeout | 10 minutes. Already set. |
| Do not use | `humble-parakeet-v6w9649j9gxgfw4rw`. That one is 4-core with a 30-minute timeout. It was stopped so it does not spend the free quota. |
| Lab file | `topology.clab.yml`, lab name `hm-net` |
| Container names | `clab-hm-net-site-a-fw`, `clab-hm-net-site-b-fw`, `clab-hm-net-app-01`, `clab-hm-net-mgmt-01`, `clab-hm-net-collector` |

`PLAN.md` is on the laptop and is not in the Codespace yet. Follow this file from the laptop. The Codespace has the files that are already on `main`: the devcontainer, `topology.clab.yml`, `docs/topology.md`, `ASSUMPTIONS.md`, and `LEARNING.md`.

On the laptop, `gh` is the command. Do not type `Douglasdadog/hm-network-home-lab` by itself and press Enter. PowerShell will try to run that text as a program. A repo name is only valid after a flag such as `--repo` or `-c`.

Three shells show up below:

- PowerShell on the laptop. Start in `C:\Users\Douglas\hm-network-home-lab` unless a step says otherwise.
- `codespace$` is the shell after `gh codespace ssh` succeeds. The repo root there is `/workspaces/hm-network-home-lab`.
- A node command is `docker exec clab-hm-net-<node> ...` from the Codespace shell. You do not SSH to a node.

## Already done

- GitHub CLI is logged in as `Douglasdadog`, with the `codespace` scope.
- `main` is pushed. It contains the design, the devcontainer, and the empty topology.
- One Codespace exists: 2-core, idle timeout 10 minutes, branch `main`.

## Still open before the lab boots

The account-wide default at https://github.com/settings/codespaces was not changed from here. This Codespace is already 10 minutes, so you do not need that page to continue. Do not add a payment method. The "paid for by Douglasdadog" line is the free quota on your account.

## Every working day

- Commit only what you just proved. The history is part of the review.
- `LEARNING.md` gets five lines: goal, tried, broke, learned and the source, next.
- Check any doc or assistant output against the running lab before you keep it.
- Use this Codespace only. If `gh codespace list` ever shows a second one, stop and delete the extra before you continue.
- Stop it when you leave: `gh codespace stop -c hm-net-4j65j45p5qrp37rgv`. Files stay. Only running time uses the quota.
- Addresses stay in private ranges or `192.0.2.0/24` (RFC 5737). No real organization names, production configs, or credentials.
- New assumptions go into `ASSUMPTIONS.md` in the same commit as the change that required them.
- Never add a `ports:` entry to the topology. That publishes a container port on the Codespace.

## 2. Boot the empty lab

This is the current step.

1. On the laptop, check the state. `hm-net` was `Available` when this plan was updated. If a later check says `Shutdown`, the same ssh command in step 2 starts it again. Do not run `gh codespace create` again.

```powershell
gh codespace list
```

Pass: one row, display name `hm-net`, name `hm-net-4j65j45p5qrp37rgv`, and state `Available`.

2. Connect. The first connection downloads the devcontainer image and can sit there for several minutes. Wait for a Linux shell prompt. Do not cancel it and start another Codespace.

```powershell
gh codespace ssh -c hm-net-4j65j45p5qrp37rgv
```

Pass, inside that shell:

```bash
containerlab version
nproc
```

`containerlab version` prints a version. `nproc` prints `2`.

3. Deploy and inspect:

```bash
cd /workspaces/hm-network-home-lab
containerlab deploy -t topology.clab.yml
containerlab inspect -t topology.clab.yml
docker ps --format 'table {{.Names}}\t{{.Ports}}'
```

Pass: five containers are running, named `clab-hm-net-site-a-fw`, `clab-hm-net-site-b-fw`, `clab-hm-net-app-01`, `clab-hm-net-mgmt-01`, and `clab-hm-net-collector`. The ports column is empty. An empty column means nothing is published to the host.

4. Check addresses. `eth0` is containerlab's management network. Ignore its address.

```bash
docker exec clab-hm-net-site-a-fw ip -br address
docker exec clab-hm-net-app-01 ip -br address
docker exec clab-hm-net-mgmt-01 ip -br address
docker exec clab-hm-net-site-b-fw ip -br address
docker exec clab-hm-net-collector ip -br address
```

Pass when these are present:

| Node | Interface | Address |
| --- | --- | --- |
| site-a-fw | eth1 | 10.10.10.1/24 |
| site-a-fw | eth2 | 10.10.20.1/24 |
| site-a-fw | eth3 | 192.0.2.1/24 |
| app-01 | eth1 | 10.10.10.10/24 |
| mgmt-01 | eth1 | 10.10.20.10/24 |
| site-b-fw | eth1 | 10.20.10.1/24 |
| site-b-fw | eth2 | 192.0.2.2/24 |
| collector | eth1 | 10.20.10.10/24 |

5. Prove each zone link before any routing:

```bash
docker exec clab-hm-net-app-01 ping -c 3 10.10.10.1
docker exec clab-hm-net-mgmt-01 ping -c 3 10.10.20.1
docker exec clab-hm-net-collector ping -c 3 10.20.10.1
docker exec clab-hm-net-site-a-fw ping -c 3 192.0.2.2
```

Pass: each command reports 3 received. If a ping fails, fix `topology.clab.yml` and run `containerlab deploy -t topology.clab.yml` again. Do not start the tunnel.

6. Stop the Codespace when you leave the laptop. Run this in a Windows PowerShell window, not inside the Codespace:

```powershell
gh codespace stop -c hm-net-4j65j45p5qrp37rgv
```

Files stay. Only running time uses the quota. Start again later with the same `gh codespace ssh -c hm-net-4j65j45p5qrp37rgv` command. Do not create a new one.

## 3. Day 3 checkpoint

This checkpoint is the diagram and the assumptions. It does not require a running lab. Do not claim the addresses were checked. They have not been.

1. On the laptop, from `C:\Users\Douglas\hm-network-home-lab`, commit `ASSUMPTIONS.md` and push `main`. `docs/topology.md` is already on `main`. Leave `PLAN.md` uncommitted unless you want the plan in the repo too.
2. Send these two links through the channel that came with the brief:

https://github.com/Douglasdadog/hm-network-home-lab/blob/main/docs/topology.md

https://github.com/Douglasdadog/hm-network-home-lab/blob/main/ASSUMPTIONS.md

3. In the message, say the scope you are asking them to confirm: two Site A zones (`apps`, `mgmt`), one Site B collector subnet, WireGuard over `192.0.2.0/24`, and TCP `514` inside the tunnel for firewall logs. Say that `containerlab deploy` has not been run yet.

Pass: both links are sent. When a reply arrives, copy any correction into `ASSUMPTIONS.md`. Do not add a zone or a product while you wait. After the send, section 2's deploy is the next lab step. The Codespace can stay stopped until then.

## 4. Install the firewall tools

The current image is Alpine-based and has ping and `ip`, not nftables, WireGuard, or rsyslog. Install on the two firewalls and the collector before any policy exists. A policy applied first can block the package download.

On each of `site-a-fw`, `site-b-fw`, and `collector`:

```bash
docker exec clab-hm-net-site-a-fw apk add --no-cache nftables wireguard-tools rsyslog ulogd
```

Repeat with `clab-hm-net-site-b-fw` and `clab-hm-net-collector`. If `apk` cannot find `ulogd`, run `apk search ulogd` and install the package whose description says NFLOG. Record the real package name in the README.

Confirm the tools exist:

```bash
docker exec clab-hm-net-site-a-fw sh -c 'command -v nft; command -v wg; command -v rsyslogd'
```

Pass: three paths are printed. `app-01` and `mgmt-01` do not need these packages.

These installs disappear when the container is recreated. That is expected. Keep the exact `apk` lines in the README. Moving them into the topology so a fresh deploy needs no manual install is stretch step S3, not this step.

## 5. Build the tunnel before the firewall

Generate keys inside the containers. Do not invent key material, and do not commit private keys. The laptop copy of `.gitignore` lists `*.key`, and that change is not on `main` yet. Before the first commit that could contain a key, make sure `git status` does not list a `*.key` file.

On `site-a-fw` and again on `site-b-fw`:

```bash
docker exec clab-hm-net-site-a-fw sh -c 'umask 077; mkdir -p /etc/wireguard; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key; cat /etc/wireguard/public.key'
```

Copy the two public keys into your notes. Then configure the interfaces. Replace the two `PEER_PUBLIC_KEY` placeholders with the other node's public key.

On `site-a-fw`:

```bash
docker exec clab-hm-net-site-a-fw sh -c '
ip link add wg0 type wireguard
ip address add 10.255.0.1/30 dev wg0
wg set wg0 private-key /etc/wireguard/private.key listen-port 51820
wg set wg0 peer PEER_PUBLIC_KEY allowed-ips 10.20.0.0/16 endpoint 192.0.2.2:51820
ip link set wg0 up
ip route replace 10.20.0.0/16 dev wg0
'
```

On `site-b-fw`, use address `10.255.0.2/30`, peer endpoint `192.0.2.1:51820`, and route `10.10.0.0/16`.

Do not use `wg-quick` for this lab. It can insert its own iptables rules, and this lab's policy is nftables that you can explain line by line.

If `ip link add wg0 type wireguard` says the operation is not supported, the Codespace kernel has no WireGuard module. Try userspace next, on both firewalls:

```bash
docker exec clab-hm-net-site-a-fw sh -c 'apk add --no-cache wireguard-go && wireguard-go wg0'
```

Then repeat the `ip address` and `wg set` commands. `wireguard-go` needs `/dev/net/tun`. containerlab can pass it with a `devices` list of `/dev/net/tun` on that node. If userspace also fails, stop and switch the tunnel assumption to strongSwan. Write that change in `ASSUMPTIONS.md` before installing it.

Pass, before any nftables rule exists:

```bash
docker exec clab-hm-net-site-a-fw ping -c 3 10.255.0.2
docker exec clab-hm-net-site-a-fw wg show
```

`wg show` has a latest handshake, and the ping receives 3 replies. `ss -ulpn` on `site-a-fw` shows `51820` on `192.0.2.1`, or on `0.0.0.0` if WireGuard cannot bind one address. If it listens on all addresses, say so in the assumptions. Do not publish `51820` with a Docker port mapping.

Save the working commands into `configs/tunnel-site-a.sh` and `configs/tunnel-site-b.sh` with the public keys only. Keep private keys inside the containers.

## 6. Teach the hosts where the other zone is

A host with no route never hits the firewall, so the firewall cannot log a deny. Add routes on the zone hosts. Do not replace their default route. The default route on `eth0` is containerlab management, and removing it is a separate experiment.

```bash
docker exec clab-hm-net-app-01 ip route replace 10.10.20.0/24 via 10.10.10.1
docker exec clab-hm-net-app-01 ip route replace 10.20.0.0/16 via 10.10.10.1
docker exec clab-hm-net-mgmt-01 ip route replace 10.10.10.0/24 via 10.10.20.1
docker exec clab-hm-net-mgmt-01 ip route replace 10.20.0.0/16 via 10.10.20.1
docker exec clab-hm-net-collector ip route replace 10.255.0.0/30 via 10.20.10.1
```

The collector route is the return path for syslog. The firewall sources that connection from `10.255.0.1`. Without this route, the collector answers through `eth0` and the proof is invalid.

Pass:

```bash
docker exec clab-hm-net-app-01 ip route get 10.10.20.10
```

The output says `via 10.10.10.1`.

## 7. Turn on forwarding, then default deny

On both firewalls:

```bash
docker exec clab-hm-net-site-a-fw sysctl -w net.ipv4.ip_forward=1
```

If sysctl refuses, add this under that node in `topology.clab.yml` and redeploy:

```yaml
sysctls:
  net.ipv4.ip_forward: "1"
```

Write the policy in the repo as `configs/site-a-fw.nft` and `configs/site-b-fw.nft`, then load each file:

```bash
docker cp configs/site-a-fw.nft clab-hm-net-site-a-fw:/etc/nftables.nft
docker exec clab-hm-net-site-a-fw nft -f /etc/nftables.nft
```

Site A. `eth1` is apps, `eth2` is mgmt, `eth3` is the underlay, `wg0` is the tunnel. Syslog is sent by the firewall itself, so it is an output rule, not a forward rule.

```nft
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iif "eth3" udp dport 51820 ip saddr 192.0.2.2 accept
    iif "lo" accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
  }

  chain output {
    type filter hook output priority 0; policy drop;
    ct state established,related accept
    oif "eth0" accept
    oif "eth3" udp dport 51820 ip daddr 192.0.2.2 accept
    oif "wg0" tcp dport 514 ip daddr 10.20.10.10 accept
  }
}
```

`eth0` in the output chain is lab plumbing so a later package install still works. It is not a path to Site B. Say that in `ASSUMPTIONS.md`. There is no forward rule from `eth1` to `eth2`, so the zones cannot reach each other.

Site B. The collector is behind `eth1`. The underlay is `eth2`.

```nft
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    ct state established,related accept
    iif "eth2" udp dport 51820 ip saddr 192.0.2.1 accept
    iif "lo" accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iif "wg0" oif "eth1" ip saddr 10.255.0.1 ip daddr 10.20.10.10 tcp dport 514 accept
  }

  chain output {
    type filter hook output priority 0; policy drop;
    ct state established,related accept
    oif "eth0" accept
    oif "eth2" udp dport 51820 ip daddr 192.0.2.1 accept
  }
}
```

The tunnel ping belongs in section 5, before these rules exist. After `nft -f` loads, ICMP is not allowed, so this ping must fail:

```bash
docker exec clab-hm-net-site-a-fw ping -c 2 -W 1 10.255.0.2
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.10.20.10
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.20.10.10
docker exec clab-hm-net-site-a-fw nft list ruleset
```

Pass: all three pings lose every packet. `nft list ruleset` shows policy `drop` on input, forward, and output. `wg show` still has the peer. If the ping to `10.255.0.2` still gets replies, the rules did not load.

Day 7, after this pass: send a short status through the same channel as the diagram. Then stop. The next message you receive is the requirement change. Read it before step 10.

## 8. Make a denied packet visible inside Site A

A plain nftables `log` writes to the kernel message buffer. In this lab the containers share the Codespace kernel, so those lines show up in the Codespace `dmesg`, not in the firewall's own files. Use NFLOG instead. It stays with the container's network namespace.

Add a log rule at the front of Site A's forward chain:

```nft
ip saddr 10.10.10.0/24 ip daddr 10.10.20.0/24 log prefix "hm-site-a " group 1
```

Reload with `nft -f /etc/nftables.nft`.

Then point ulogd at group 1 and a file under `/var/log/nft.log`. After `apk add`, the package ships a sample config. Change that sample. Do not write a second config from memory if the sample's stack names differ. You need three facts in the file: NFLOG group `1`, an output file `/var/log/nft.log`, and the stack that connects them. Start ulogd, then:

```bash
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.10.20.10
docker exec clab-hm-net-site-a-fw tail -n 5 /var/log/nft.log
```

Pass: the file contains a line with `hm-site-a` and the addresses `10.10.10.10` and `10.10.20.10`. If the file stays empty, check `ps` for ulogd and the group number before touching rsyslog.

## 9. Carry that line to Site B

On the collector, rsyslog listens only on the zone address and writes a file:

```bash
docker exec clab-hm-net-collector sh -c 'printf "%s\n" \
  "module(load=\"imtcp\")" \
  "input(type=\"imtcp\" port=\"514\" address=\"10.20.10.10\")" \
  "*.* action(type=\"omfile\" file=\"/var/log/site-a.log\")" \
  > /etc/rsyslog.d/10-remote.conf'
docker exec clab-hm-net-collector rsyslogd -N1
docker exec clab-hm-net-collector rsyslogd
```

Pass for the listener:

```bash
docker exec clab-hm-net-collector ss -ltn
```

`10.20.10.10:514` is listening. If the syntax error says `address` is unknown, the packaged rsyslog is older. Bind it another way, or leave it on all interfaces and add an input rule on the collector that accepts TCP `514` only from `10.255.0.1`. Write down which one you did.

On `site-a-fw`, forward the ulogd file with TCP. Use the packaged `imfile` example as the pattern:

```text
module(load="imfile")
input(type="imfile" File="/var/log/nft.log" Tag="site-a-fw" Ruleset="to-site-b")
ruleset(name="to-site-b") {
  action(type="omfwd" Target="10.20.10.10" Port="514" Protocol="tcp")
}
```

`rsyslogd -N1` must succeed before you start the daemon.

Produce one fresh deny and read the collector:

```bash
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 20 /var/log/site-a.log
```

Pass: `/var/log/site-a.log` contains the same `hm-site-a` deny you saw on Site A. That file is the core demo.

Also show the negative cases:

```bash
docker exec clab-hm-net-app-01 ping -c 2 -W 1 10.20.10.10
docker exec clab-hm-net-site-a-fw sh -c 'nc -zvw2 10.20.10.10 514; echo tcp514:$?'
docker exec clab-hm-net-site-a-fw sh -c 'nc -zvw2 10.20.10.10 22; echo tcp22:$?'
```

The host ping fails. TCP `514` from the firewall succeeds. TCP `22` from the firewall fails. Install `netcat-openbsd` with apk if `nc` is missing, and do it before you rely on a drop policy that blocks apk.

## 10. Apply the requirement change

When the day 7 reply arrives:

1. Write one sentence on what it changes: a zone, a port, a path, or a proof.
2. Change only that. Update `docs/topology.md` and `ASSUMPTIONS.md` in the same commit.
3. Re-run the pass check from step 9. A change that breaks the log line is not done.
4. Add a `LEARNING.md` entry with what you would do differently if you had known the change on day 1.

Do not start stretch work in the same session as an unfinished change.

## 11. Stretch, only after step 9 passes

Do these from the top. Stop when time is gone.

S1. Failure test. `ip link set wg0 down` on `site-a-fw`. Repeat the ping from `app-01` to `mgmt-01`. Read `/var/log/site-a.log` before and after. Write three sentences: what still happens on Site A, what never reaches Site B, and which check would tell an operator the tunnel is down (`wg show` has no handshake, or the collector file stops growing). Bring `wg0` back up and show a new line arriving.

S2. Runbook. `docs/runbook.md` with the three failures you actually hit. For each: the symptom, the command that proves it, and the command that fixes it.

S3. One-command rebuild. Move apk, sysctl, routes, `nft -f`, and service starts into `topology.clab.yml` `exec` or into scripts that `exec` calls. Private keys are generated by the script on boot and are not in git. Destroy and deploy on a fresh codespace. Pass: step 9's log line appears with no command typed by hand.

S4. Encrypt the payload. Keep WireGuard. Add rsyslog TLS from `site-a-fw` to collector port `6514`, with a lab certificate generated in the codespace. Show that TCP `514` can be closed and the log still arrives on `6514`. The tunnel encrypts the path. TLS encrypts the log line. Those are different, and the readout needs one sentence on that.

S5. Visibility. Add one Zeek or Suricata container on the Site A apps link. Forward its alert or notice to the same collector. One alert from the cross-zone ping is enough.

## 12. Days 12–14, the readout

1. Rewrite `README.md` as the only page a stranger needs. Order: quota rules, create the 2-core codespace, deploy, the one command that produces a log line, the command that shows the line, destroy, and how to stop the codespace. Link the diagram and the assumptions.
2. Update `docs/topology.md` so every address and port matches `nft list ruleset` and `wg show`.
3. Fill any missing day in `LEARNING.md`.
4. Make readout notes, one page:

- 10 minutes. Start with `tail` of `/var/log/site-a.log` and the failed cross-zone ping. Then walk the path: host route, nftables log, TCP inside `wg0`, UDP `51820` on `192.0.2.0/24`, collector file.
- 5 minutes. Teach one concept that was new to you. Default deny, the tunnel versus the payload, or why the collector needs a route back to `10.255.0.1` are all good. Pick the one you had to look up.
- 5 minutes. The requirement change: what moved, what you edited, what you would redesign.

5. The repo is already public: https://github.com/Douglasdadog/hm-network-home-lab. Submit that link and the readout notes. Add the reviewer as a collaborator only if the brief names an account and asks for it.

Pass: another person can follow the README to the log line, and you can give the readout without reading the nftables file for the first time that morning.

## If time runs short

Keep steps 1 through 9, then step 12. Drop stretch from S5 backward. A collector file with one real deny line, and a README that reproduces it, is the core.
