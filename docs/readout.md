# Presentation script

About 20 minutes. Speak in this order. Type only the commands in the boxes.

Repo: https://github.com/Douglasdadog/hm-network-home-lab

Diagram: https://github.com/Douglasdadog/hm-network-home-lab/blob/main/docs/topology.md

Assumptions: https://github.com/Douglasdadog/hm-network-home-lab/blob/main/ASSUMPTIONS.md

## Before you start

On their computer, sign in to GitHub as `Douglasdadog`.

1. Open the repo link.
2. Click the green **Code** button.
3. Click **Codespaces**.
4. Click **hm-net**. Do not create a new codespace. Do not open `humble parakeet`.
5. Wait until a terminal is ready. The first resume can take a few minutes.

If `docker ps` shows no names starting with `clab-hm-net-`, rebuild, then wait until the script prints the collector log:

```bash
cd /workspaces/hm-network-home-lab
containerlab deploy -t topology.clab.yml --reconfigure
sh scripts/bringup-core.sh
```

Have the topology page open in another tab. You will point at picture 2, then picture 3.

## Minutes 0–10: show the result, then explain it

Say:

"Site A is the bank. It has two rooms, apps and management. Site B is where a copy of the firewall log is stored. The rooms cannot talk to each other. The only private path between the buildings is a WireGuard tunnel. I will show a blocked packet, and then the log of that block arriving at Site B."

Type:

```bash
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.10.20.10
docker exec clab-hm-net-collector tail -n 5 /var/log/site-a.log
```

Say:

"The ping lost the packet. That is the block. This line is the note about the block. Source `10.10.10.10` is app-01. Destination `10.10.20.10` is mgmt-01. The tag is `hm-site-a`."

Point at picture 2 and say:

"app-01 sent the ping to its gateway, `10.10.10.1`, which is the Site A firewall. The firewall logged that pair and dropped it. mgmt-01 never received it. The ping does not cross to Site B."

Point at picture 3 and say:

"The note takes a different trip. ulogd on the Site A firewall writes it to `/var/log/nft.log`. rsyslog copies that file with TCP port 514, from `10.255.0.1`. WireGuard encrypts that copy and sends it as UDP 51820 from `192.0.2.1` to `192.0.2.2`. The Site B firewall allows only that one flow, and the collector appends `/var/log/site-a.log`."

Then the privacy points, one sentence each:

- "`192.0.2.0/24` is a practice range, not the real internet."
- "Nothing in the lab is published as a public port."
- "app-01 cannot reach the collector. I can show that ping too if you want."
- "The firewall allows the tunnel, and it allows TCP 514 to the collector. A connection to port 22 times out."

Optional, only if they ask for the second ping:

```bash
docker exec clab-hm-net-app-01 ping -c 1 -W 1 10.20.10.10
```

Say: "Also 100% loss. The room has no path to Site B."

## Minutes 10–15: teach one idea

Say:

"WireGuard locks the tube. It does not lock the letter inside the tube. The log line on TCP 514 is still plain text. I know that because rsyslog warned that this forwarding mode is plain TCP, not TLS. Encrypting the letter would be a second step, TLS to port 6514. That is not built. The tunnel and the log encryption are different jobs."

Stop there. Do not apologize for the missing TLS. Name it and move on.

## Minutes 15–20: the requirement change

Say:

"The requirement change has not arrived. I have not invented one. When it arrives, I will change only the part it names, update the diagram and the assumptions, and run this same ping and tail again. If the collector line disappears, the change is not finished."

If they ask what you would redesign: the route `10.20.0.0/16 dev wg0` disappears when the tunnel interface goes down, and it does not come back by itself. You would tie that route to the tunnel so the repair is one action.

## If they ask "what if the tunnel fails?"

Do not take the tunnel down unless they ask. You already have the result.

Say:

"I turned `wg0` down. The ping still failed, and Site A still wrote the local log, because the rooms are on that firewall. The collector file stopped growing. Turning the interface back up was not enough. The route `10.20.0.0/16 dev wg0` was gone, and rsyslog on Site A had to be started again. After both of those, new lines arrived. `wg show` still printed an old handshake while the interface was down, so I do not use that alone. I check whether the interface is down, and whether the collector file has stopped while the local file is still growing."

The commands and the line counts are in `docs/failure-test.md`.

## If they ask how you know it is private

Say:

"The sites can reach each other through the tunnel, and `wg show` had a handshake. When the tunnel was down, the log stopped arriving at Site B, so there was no second path. The zone computers still could not reach Site B. No lab service is published on the Codespace."

## After you finish

```powershell
gh codespace stop -c hm-net-4j65j45p5qrp37rgv
```
