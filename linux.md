# Raspberry Pi and Linux

This works on a Raspberry Pi 3 or newer, a mini PC, an old laptop that stays plugged in,
or a VPS: anything that runs Linux and stays on.

## 1. Prepare the machine

**Raspberry Pi:** flash **Raspberry Pi OS Lite (64-bit)** to a microSD card or, better, a
USB SSD with [Raspberry Pi Imager](https://www.raspberrypi.com/software/). In its
settings (the gear icon), set a hostname such as `homeserver`, a username and password,
your Wi-Fi if you don't use a cable, and turn on SSH. Start the Pi and, from another
computer, sign in:

```sh
ssh you@homeserver.local
```

**Any other Linux machine:** open a terminal on it, or sign in over SSH.

## 2. Install the apps

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sh
```

The installer:

1. Installs Docker with the official script from get.docker.com if it is missing (it
   asks first, and may ask for your password).
2. Shows the apps and asks which ones you want. Type numbers or names, such as `1 3`.
3. Asks for a folder, `~/selfhostit` by default, and puts each app in its own folder there
   with its database.
4. Asks whether to set up Tailscale, which gives every app an `https://` address that only
   your own devices can reach. Phones need that to install the apps and get notifications.
5. Runs each app's own installer, which may ask a few questions of its own. Pressing Enter
   keeps the suggested answer.
6. With Tailscale, shows a link to sign in (or make a free account), and the first time a
   second link to allow HTTPS. Open them on your computer or phone.

When it is done it lists every app with its address: `https://selfhostit.<your-tailnet>.ts.net:8090`
with Tailscale, or `http://localhost:8090` on the machine itself without it. Each app only
listens on the machine and on your Tailscale network, so nothing is open to the rest of your
network or the internet. Then [install the apps on your phones](phones.md).

## Without the menu

Name the apps after `sh -s --`, and set the folder with `SELFHOSTIT_DIR`:

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh |
  SELFHOSTIT_DIR=/srv/apps sh -s -- splitwiz flowy
```

## Good to know

- **Ports:** Splitwiz 8090, should-we 8091, Flowy 8092, Troye 8093. To change one, edit
  the port in that app's `.env` and run the installer again.
- **Restarts:** the apps start again by themselves when the machine reboots.
- **SD cards** wear out with a database writing to them. A USB SSD is more reliable, and
  you should keep [backups](updates-and-backups.md) either way.
- **Troye** reads food photos with a vision model on a computer with a GPU; see the
  [Troye readme](https://github.com/selfhostit/troye) for its worker.
