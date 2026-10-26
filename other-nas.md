# Other NAS and home servers

Every app is one Docker container with a Compose file, so anything that can run a Compose
file can run them.

**With SSH** (QNAP, Unraid, TrueNAS SCALE, OpenMediaVault, Asustor, UGREEN, Proxmox in a
Debian VM or LXC): sign in and run the installer, with `sudo` if your user can't use Docker.

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sudo sh
```

On Unraid it suggests `/mnt/user/appdata`; anywhere else, pick a folder on your data pool
so the apps' databases are part of your NAS backups.

**Without SSH**, paste the app's Compose file into the NAS's Docker app:

| NAS or dashboard | Where |
|---|---|
| QNAP | Container Station > Applications > Create |
| TrueNAS SCALE | Apps > Discover Apps > Custom App (Install via YAML) |
| Unraid | the Compose Manager plugin from Community Applications |
| Portainer | Stacks > Add stack |
| CasaOS, ZimaOS | App Store > Custom Install > Import |

The Compose files are in each app's repository:
[Splitwiz](https://github.com/selfhostit/splitwiz/blob/main/docker-compose.yml),
[should-we](https://github.com/selfhostit/should-we/blob/main/docker-compose.yml),
[Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/docker-compose.yml),
[Troye](https://github.com/selfhostit/troye/blob/main/deploy/docker-compose.yml).
Replace `./pb_data` with a full path on your pool, give each app its own port (Splitwiz
8090, should-we 8091, Flowy 8092, Troye 8093), and set your time zone in `TZ`.

Then follow [phones](phones.md) to reach them over HTTPS.
