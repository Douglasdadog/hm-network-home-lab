# Learning log

All of this happened on 2026-11-06, in checkpoint order. The git history is the same day. These are not separate calendar days.

## Days 1–3 — design

Goal: Write a diagram and assumptions that can be checked before the tunnel exists.

Tried: Five containers, two Site A zones (`apps` `10.10.10.0/24`, `mgmt` `10.10.20.0/24`), one Site B collector subnet (`10.20.10.0/24`), WireGuard over the documentation range `192.0.2.0/24`. Wrote `docs/topology.md` and `ASSUMPTIONS.md`.

Broke: The first picture made the dropped ping look like it traveled to Site B. The log path was first described as a kernel message. Both were wrong for this lab.

Learned: The ping dies on `site-a-fw`. Only a copy of the note crosses the tunnel. A plain nftables `log` in this Codespace goes to the shared kernel buffer, so the lab uses NFLOG group 1. Source: the assessment brief, the containerlab topology manual, and this Codespace. AI drafted the first design. The later correction came from watching the running lab.

Next: Build the nodes and the tunnel. The diagram and assumptions are in the repo. They were not sent as a separate day-3 message.

## Days 4–7 — sites, tunnel, firewall

Goal: Connect the sites privately and allow only the log flow.

Tried: `containerlab deploy` for five Linux nodes. `scripts/bringup-core.sh` for WireGuard `10.255.0.1` and `10.255.0.2`, then nftables default drop. Allows are UDP `51820` between `192.0.2.1` and `192.0.2.2`, and TCP `514` from `10.255.0.1` to `10.20.10.10`.

Broke: The first containers had only `eth0` until `containerlab deploy --reconfigure`. A ping to `10.255.0.2` failed with "Required key not available" until `10.255.0.2/32` and `10.255.0.1/32` were added to the peer allowed lists.

Learned: The linux kind does not apply link IP fields, so addresses are set with `exec`. WireGuard `AllowedIPs` is the list of addresses that may enter the tube, not a normal route by itself. Source: containerlab deploy output and `wg show` in the Codespace.

Next: Carry a firewall line to the collector. A day-7 status was not sent. The requirement change has not arrived.

## Days 8–11 — logs, then the failure test

Goal: See one Site A firewall line in `/var/log/site-a.log`.

Tried: ulogd writes NFLOG group 1 to `/var/log/nft.log`. rsyslog on `site-a-fw` forwards that file with TCP to `10.20.10.10:514`. Then `ip link set wg0 down` for the failure test.

Broke: The collector file did not appear until it was created and writable. With `wg0` down, Site A still logged the deny and the collector stayed at 2 lines. `ip link set wg0 up` did not restore the route `10.20.0.0/16 dev wg0`. New lines arrived only after that route was replaced and `rsyslogd` on `site-a-fw` was started again.

Learned: `wg show` can still print an old handshake while the interface is down. The useful checks are `ip -br link show wg0` and whether `/var/log/site-a.log` is still growing while `/var/log/nft.log` is. Source: the failure test in this Codespace, written in `docs/failure-test.md`. rsyslog 8.2608 warned that TCP 514 is plain text. That matches the difference between the tunnel and the letter.

Next: The requirement change is still not here, so it is not applied. TLS on 6514, Zeek or Suricata, and a topology-only rebuild were left.

## Days 12–14 — repo and readout

Goal: Make the repo something another person can rebuild, and prepare the 20 minutes.

Tried: README with the deploy and the proof commands. Three diagrams in `docs/topology.md`. Spoken notes in `docs/readout.md`.

Broke: Nothing in the lab. The readout has not been given yet.

Learned: The demo is the failed ping plus the collector line, in a browser Codespace, not a slide of the files. Source: the brief's readout section.

Next: Present from `docs/readout.md`. When the requirement change arrives, change only that and run the ping and the `tail` again.
