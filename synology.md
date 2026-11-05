# Synology NAS

Any Synology that runs **Container Manager** (DSM 7.2 or later, x86-64 or ARM) can run the
apps. Each one becomes a project in Container Manager, with its data in the `docker`
shared folder.

## 1. Install Container Manager and turn on SSH

1. Install **Container Manager** from Package Center. It creates the `docker` shared folder.
2. Control Panel > Terminal & SNMP: tick **Enable SSH service**.
3. From your computer, sign in with your DSM account: `ssh you@your-nas.local`
   (on Windows, in PowerShell).

## 2. Install the apps

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sudo sh
```

It asks for your DSM password, which apps you want, and a folder (`/volume1/docker` by
default, one folder per app). The apps show up in Container Manager under **Project**,
where you can see their logs, stop and start them.

Turn SSH off again afterwards (Control Panel > Terminal & SNMP); you only need it to
update, and an SSH login with your DSM password is the easiest way into the NAS.

**Keep the `docker` folder private.** It holds every app's database, backups and setup
code, and anyone who can open it over the network can copy them. In Control Panel >
Shared Folder, select `docker` > **Edit**: on **Permissions**, give *administrators*
Read/Write and every other user and group No access; on **General**, tick *Hide this
shared folder in "My Network Places"*. Don't sync it with Synology Drive or Cloud Sync.

## Without SSH

Container Manager > Project > Create, once per app:

- Name: the app's name, such as `splitwiz`
- Path: create `/volume1/docker/<app>` and a `pb_data` folder inside it in File Station first
- Source: **Create docker-compose.yml**, and paste the app's compose file:
  [Splitwiz](https://github.com/selfhostit/splitwiz/blob/main/docker-compose.yml),
  [should-we](https://github.com/selfhostit/should-we/blob/main/docker-compose.yml),
  [Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/docker-compose.yml),
  [Troye](https://github.com/selfhostit/troye/blob/main/deploy/docker-compose.yml),
  [Shoppa](https://github.com/selfhostit/shoppa/blob/main/deploy/docker-compose.yml),
  [Calio](https://github.com/selfhostit/calio/blob/main/deploy/docker-compose.yml)

In the pasted file, set the port so two apps don't share one (the number after `:-` in the
`ports:` line: Splitwiz 8090, should-we 8091, Flowy 8092, Troye 8093, Shoppa 8094, Calio
8095), and your time zone in the `TZ` line. For Flowy, Troye, Shoppa and Calio, also set `PUID` and `PGID` to your DSM user's ids
(run `id` over SSH, or leave them at 1000 and give that user the folder).

## 3. Reach them from your phones

Two ways, both described in [phones](phones.md):

- **At home and away, without opening your router:** Tailscale. Install the Tailscale
  package from Package Center.
- **On a public address:** DSM's own reverse proxy with a free `*.synology.me` address and
  Let's Encrypt certificate. The [Splitwiz Synology guide](https://github.com/selfhostit/splitwiz/blob/main/docs/synology.md)
  walks through it step by step; repeat the reverse proxy step for each app with its own
  name, such as `flowy.<your-name>.synology.me` to port 8092.

Either way, don't forward the apps' ports (8090 to 8095) or DSM's own ports (5000, 5001) in
your router, and leave DSM's **QuickConnect** off unless you use it: they put the apps or
DSM's sign-in page on the internet, where bots try passwords all day. With a public address,
forward only 443 to DSM's reverse proxy.

## Updating and backups

With SSH on, `selfhostit update splitwiz` (or `flowy`, or `all`) pulls and restarts an app in
one step; see [updates and backups](updates-and-backups.md#one-command-selfhostit-update) to
install it. On a Synology, add `/volume1/docker` to
a **Hyper Backup** task to keep a copy of every app's data off the NAS.
