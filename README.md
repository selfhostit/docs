# Install selfhostit apps

selfhostit apps are small apps you run on your own hardware: a Raspberry Pi, a NAS or a
cheap server. Each one is a single container with its data in one folder, and they all
install the same way, with Docker.

| App | What it does | Port |
|---|---|---|
| [Splitwiz](https://github.com/selfhostit/splitwiz) | Split shared costs with your partner or roommate | 8090 |
| [should-we](https://github.com/selfhostit/should-we) | Pick one option together, as a group | 8091 |
| [Flowy](https://github.com/selfhostit/flowy) | A private period and cycle tracker | 8092 |
| [Troye](https://github.com/selfhostit/troye) | A private calorie and weight tracker (work in progress) | 8093 |

The port is where the installer puts each app, so they can all run on one machine.

## Quick start

On a Raspberry Pi, a Linux server or a NAS you can reach over SSH:

```sh
curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sh
```

It installs Docker if it is missing (on Linux), asks which apps you want and where to keep
them, and starts them. Run it again to update; your settings and data are kept.

It can also set up [Tailscale](phones.md#tailscale-recommended), so your phones reach the apps
over HTTPS, which they need to install an app and get notifications. You only open a link to
sign in; there are no keys or settings to copy. Then [put the apps on your phones](phones.md).

## Guides

- [Raspberry Pi and Linux](linux.md): a Pi, a mini PC, an old laptop or a VPS.
- [Synology NAS](synology.md): with Container Manager, from the DSM web interface.
- [Other NAS and home servers](other-nas.md): QNAP, Unraid, TrueNAS SCALE, Portainer,
  CasaOS and anything else that takes a Compose file.
- [Use them on your phones](phones.md): Tailscale, or a reverse proxy with your own domain.
- [Updates and backups](updates-and-backups.md)

## What you need

Anything that runs Docker containers for `linux/amd64`, `linux/arm64` or `linux/arm/v7`:
x86 and ARM servers, a Raspberry Pi 3 or newer (64-bit Raspberry Pi OS is best), and NAS
models with a Docker app. Each app needs about 128 to 512 MB of memory. NAS models without
Docker support (many budget and older ones) won't work.

## Questions?

Write to kalfasyan@pm.me, or see [selfhostit.org/contact](https://selfhostit.org/contact.html).
Found a bug in an app? Open an issue in that app's repository.
