# Assumptions

Stated so they can be challenged. If one of these is wrong, the topology and the firewall policy both change.

1. **Two zones on Site A are enough for the core.** `apps` and `mgmt` sit on different subnets. The Site A firewall is the only gateway between them, and between either zone and Site B. A third zone (for example a DMZ) is out of scope until a later requirement asks for it.
2. **The "untrusted path" is a lab network, not the real internet.** Both firewalls share one containerlab bridge addressed from `192.0.2.0/24` (RFC 5737). That range is documentation space. It stands in for an untrusted underlay. No container gets a default route to the Codespace host, and no lab port is published.
3. **WireGuard is the tunnel.** It is the encrypted site-to-site path. strongSwan stays unused unless WireGuard cannot run inside this Codespace image. Tunnel encryption and log encryption are different jobs: WireGuard protects the path; rsyslog TLS (stretch) would protect the log records themselves.
4. **Core log transport is TCP syslog inside the tunnel, not TLS yet.** The Site A firewall is the log source. nftables writes prefixed kernel log lines, rsyslog on that firewall forwards them to the collector. UDP 514 is not the core choice, because a dropped datagram is a lost log and is harder to demonstrate. TLS to port 6514 is stretch work, after the plain path works.
5. **The collector is the only Site B server.** Site B is one subnet. There is no second zone there until the brief requires one.
6. **Default deny, and the allow list is only the log flow.** Each firewall starts from drop. Permanent allows are: WireGuard UDP `51820` between the two underlay addresses, and TCP `514` from the Site A firewall's tunnel address to the collector. Return traffic is stateful. Traffic between `apps` and `mgmt` is denied. Hosts in the zones do not send logs and cannot reach Site B.
7. **ICMP is a temporary bring-up tool.** Echo between the two tunnel addresses may be allowed while proving the path, then removed before the "only what the log flow needs" demonstration.
8. **One Linux image per role, built for the lab.** The image includes nftables, wireguard-tools, and rsyslog. containerlab deploys it. Package installs are not a manual step after `containerlab deploy` once the one-command rebuild (stretch) exists. Until that image exists, setup is documented as explicit commands.
9. **Codespaces stays on the 2-core machine.** The containerlab docs show a 4-core example. This lab follows the assessment quota rule: 2-core, idle timeout 10 minutes, stop the codespace when stepping away, no payment method.
10. **A shared L2 underlay is enough to practice routing.** Hosts use their zone gateway. Each firewall routes the remote site's prefix through `wg0`. A third "internet" router is not in the core design.
11. **Names in configs are roles, not organizations.** `site-a-fw`, `site-b-fw`, `app-01`, `mgmt-01`, `collector`.
