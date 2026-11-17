# Install selfhostit apps

selfhostit apps are small apps you run on your own hardware: a [Raspberry Pi](words.md#raspberry-pi), a [NAS](words.md#nas) or a
cheap server. Each one is a single container with its data in one folder, and they all
install the same way, with [Docker](words.md#docker).

| App | What it does |
|---|---|
| [Splitwiz](https://github.com/selfhostit/splitwiz) | Split shared costs with your partner or roommate |
| [should-we](https://github.com/selfhostit/should-we) | Pick one option together, as a group |
| [Flowy](https://github.com/selfhostit/flowy) | A private period and cycle tracker |
| [Troye](https://github.com/selfhostit/troye) | A private calorie and weight tracker |
| [Shoppa](https://github.com/selfhostit/shoppa) | A shared shopping list for your household |
| [Calio](https://github.com/selfhostit/calio) | One calendar for your household: plans, pet sitting and trips |

## Before you start

- **About 30 minutes.**
- **A machine that stays on,** such as a Raspberry Pi, a mini PC, an old laptop or a NAS.
  Not sure which? See [which machine?](machine.md)
- **A computer with a [terminal](words.md#terminal)** to type the install line, on that machine or connected to
  it: [open a terminal and connect](terminal.md).
- **An account to sign in to [Tailscale](words.md#tailscale) with** (Google, Microsoft, Apple or GitHub), if you
  want the apps on your phones.
- **The phones of everyone who will use the apps.** Each one gets the free Tailscale app:
  [what that means for a phone](phones.md#tailscale-is-a-vpn-but-not-that-kind).

You can stop at any step and nothing breaks: the apps keep working on the machine, and
running the installer again picks up where you left off. You can also
[remove everything](updates-and-backups.md#remove-an-app) later.

## Quick start

**1. Install the apps you want.** You need a little computer that runs [Linux](words.md#linux), such as an old
laptop, a mini PC, a Raspberry Pi or a NAS (see [what you need](#what-you-need)), and a
terminal on it, or [SSH](words.md#ssh) ([how to open one and connect](terminal.md)). Then:

```sh
curl -fsSL https://github.com/selfhostit/docs/releases/latest/download/install.sh | sh
```

<img src="img/install.svg" width="100%" alt="Three panels: find an old laptop or a Raspberry Pi, paste one line in a terminal and pick your apps, then open every app in a browser at home.">

The installer sets up Docker if it is missing (on Linux), shows the apps and asks which ones
you want: one, a few or all of them. Each app runs on its own and needs none of the others,
so start with the one you came for and add more later the same way. To skip the menu, put
the app names at the end:

```sh
curl -fsSL https://github.com/selfhostit/docs/releases/latest/download/install.sh | sh -s -- flowy
```

It then asks where to keep them and starts them. Run the same line again to update; your
settings and data are kept. Step by step: [a Pi or Linux](linux.md), a
[Synology](synology.md) or [another NAS](other-nas.md).

**2. Open an app and make your account.** At the end the installer lists each app's address
and a one-time [setup code](words.md#setup-code). Open the address, type the code and create your account: you
become the app's [owner](words.md#owner-and-member). [After you install](first-steps.md) says how to add the rest of your
household, and what to do when something doesn't open.

**3. Open them from your phones and other computers.** The apps only answer on the machine
they run on, so nothing else on your network or the internet can reach them by accident. To
use them from your phone or laptop, at home and away, they need an [`https://`](words.md#https) address, which
phones also need to install a [web app](words.md#web-app) and show its notifications. The installer can give all
your apps one with [Tailscale](phones.md#tailscale-recommended), a free private network that
only your own devices can reach: say yes when it asks. There is nothing to install on the
server, because the installer runs Tailscale for you; you sign in once, and each phone gets
the Tailscale app. Then [put the apps on your phones](phones.md#install-the-app-on-the-phone).
Tailscale is a [VPN](words.md#vpn), but not the kind that changes how your phone browses:
[here is what it does on a phone](phones.md#tailscale-is-a-vpn-but-not-that-kind).

<img src="img/phones.svg" width="100%" alt="Three panels: say yes to Tailscale in the installer and open its sign-in link, install the Tailscale app on each phone with the same account, then open each app's https address and add it to the home screen.">

Already have a [domain](words.md#domain)? Use [a reverse proxy](phones.md#your-own-domain-with-a-reverse-proxy)
instead of Tailscale.

Prefer to read and check a script before you run it? Download it, verify it, read it, then
run it:

```sh
curl -fsSLO https://github.com/selfhostit/docs/releases/latest/download/install.sh
gh attestation verify install.sh --repo selfhostit/docs
less install.sh
sh install.sh
```

The installer is a signed release, and it installs a pinned release of each app, checking
every file it downloads against its SHA-256.

[Security and privacy](security.md) says step by step what it does, what the apps protect
and what you are trusting.

## Security in short

The apps keep their data on your machine, in one folder each, with no selfhostit cloud and no
analytics. They listen on `127.0.0.1` only and are reached through Tailscale or your own
reverse proxy, never a [forwarded port](words.md#port-forwarding). Containers run as a normal user with no Linux
capabilities and a read-only filesystem, a new install asks for a one-time setup code,
passwords are stored as bcrypt hashes, sign-ins are rate limited and the web apps send a
Content Security Policy. Every change, and every week, is scanned with CodeQL, govulncheck,
Grype and gitleaks. Updates follow versioned releases, each image has a signed attestation
of the commit that built it, and the installer pins each app's release with SHA-256 checks.
Not done yet: an independent audit.
Details, with links to the code: [Security and privacy](security.md). Report a problem
privately through the app's Security tab on GitHub or to kalfasyan@pm.me
([policy](https://github.com/selfhostit/.github/blob/main/SECURITY.md)).

## Guides

- [Which machine?](machine.md): a NAS, a spare computer, a Raspberry Pi or mini PC, or a
  rented server.
- [Open a terminal and connect](terminal.md): on Windows, Mac, Linux or a Chromebook.
- [Words you'll meet](words.md): SSH, Docker, Tailscale and the other words in these guides.
- [Raspberry Pi and Linux](linux.md): a Pi, a mini PC, an old laptop or a [VPS](words.md#vps).
- [Synology NAS](synology.md): with Container Manager, from the DSM web interface.
- [Other NAS and home servers](other-nas.md): QNAP, Unraid, TrueNAS SCALE, Portainer,
  CasaOS and anything else that takes a [Compose file](words.md#compose-file).
- [Use them on your phones](phones.md): Tailscale, or a reverse proxy with your own domain.
- [After you install](first-steps.md): your first account, adding your household, and what to
  do when an app doesn't open.
- [Updates and backups](updates-and-backups.md)
- [Security and privacy](security.md): how your data is protected, and how to report a problem.

## What you need

Not sure what to run them on? [Which machine?](machine.md) compares the choices.

Anything that runs Docker containers for `linux/amd64`, `linux/arm64` or `linux/arm/v7`:
x86 and ARM servers, a Raspberry Pi 3 or newer (64-bit Raspberry Pi OS is best), and NAS
models with a Docker app. Each app needs about 128 to 512 MB of memory. NAS models without
Docker support (many budget and older ones) won't work.

## Questions or ideas?

Need a hand with setup, or have an idea for an app? Write to kalfasyan@pm.me, or see [selfhostit.org/contact](https://selfhostit.org/contact.html).
Found a bug in an app? Open an issue in that app's repository.
