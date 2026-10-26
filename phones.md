# Use them on your phones

The apps install on a phone from the browser, like an app from a store, and send
notifications. Phones only allow that over **HTTPS**, so each app needs an `https://`
address. Plain `http://192.168.x.x:8090` works in a browser at home, but not for those two.

Pick one of these.

## Tailscale (recommended)

[Tailscale](https://tailscale.com) is a free private network between your own devices. The
apps get an `https://` address with a real certificate that only your devices can reach, at
home and away, and you don't open anything in your router.

**With the installer.** Say yes when [the installer](README.md#quick-start) asks to set up
Tailscale (run it again if you skipped it). It then:

1. Shows a link: open it, and sign in to Tailscale or make a free account. The machine
   joins your Tailscale network as `selfhostit`.
2. The first time, shows a second link that turns on HTTPS for your Tailscale network: open
   it and allow it.
3. Lists every app's address, such as `https://selfhostit.your-tailnet.ts.net:8090` for
   Splitwiz. The port is the same as the app's port on the machine.

Then, on each phone, install the Tailscale app, sign in with the same account, and
[install the apps](#install-the-app-on-the-phone). The sign-in and the addresses stay after a
restart, and apps you add later get an address when you run the installer for them.

To sign in without the link, for example on a machine without a browser nearby, set an
[auth key](https://login.tailscale.com/admin/settings/keys):
`curl -fsSL .../install.sh | TS_AUTHKEY=tskey-... sh`.

**By hand**, if Tailscale already runs on the machine:

1. In the [admin console](https://login.tailscale.com/admin/dns), turn on **MagicDNS** and
   **HTTPS Certificates**.
2. Give each app an HTTPS port on the machine's Tailscale address:

   ```sh
   sudo tailscale serve --bg --https=8090 http://127.0.0.1:8090   # Splitwiz
   sudo tailscale serve --bg --https=8091 http://127.0.0.1:8091   # should-we
   sudo tailscale serve --bg --https=8092 http://127.0.0.1:8092   # Flowy
   sudo tailscale serve --bg --https=8093 http://127.0.0.1:8093   # Troye
   ```

   `tailscale serve status` shows the addresses. They stay after a restart.

Flowy and Troye can also join Tailscale on their own, each with its own name such as
`https://flowy.your-tailnet.ts.net`, when you install them with their own installer: see
their `docs/deploy.md`.

Everyone who uses the apps needs to be on your tailnet. That suits a household; to share a
should-we decision with friends, use a public address instead.

## Your own domain with a reverse proxy

For public addresses such as `https://splitwiz.example.com`:

- **A NAS:** its built-in reverse proxy with a free certificate. On a Synology, see the
  [Splitwiz Synology guide](https://github.com/selfhostit/splitwiz/blob/main/docs/synology.md).
- **A Linux machine:** [Caddy](https://caddyserver.com) gets certificates by itself. Point a
  DNS record for each name at your home or server address, forward port 443 to the machine,
  and use a `Caddyfile` like this:

  ```
  splitwiz.example.com {
      reverse_proxy 127.0.0.1:8090
  }
  should-we.example.com {
      reverse_proxy 127.0.0.1:8091
  }
  flowy.example.com {
      reverse_proxy 127.0.0.1:8092
  }
  ```

- **Without opening your router:** a Cloudflare Tunnel does the same from the inside.

## Install the app on the phone

Open the app's `https://` address on the phone and sign in. Then:

- **Android, Chrome:** ⋮ > **Install app**.
- **iPhone, Safari:** Share > **Add to Home Screen**. Notifications need iOS 16.4 or newer.

Turn on notifications in the app's settings if it has them.
