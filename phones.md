# Use them on your phones

The apps install on a phone from the browser, like an app from a store, and send
notifications. Phones only allow that over **HTTPS**, so each app needs an `https://`
address. Plain `http://192.168.x.x:8090` works in a browser at home, but not for those two.

Pick one of these.

## Tailscale (recommended)

[Tailscale](https://tailscale.com) is a free private network between your own devices. The
apps get an `https://` address with a real certificate that only your devices can reach, at
home and away, and you don't open anything in your router.

1. Make a free Tailscale account, and install Tailscale on your phones.
2. Install it on the machine running the apps: `curl -fsSL https://tailscale.com/install.sh | sh`
   and then `sudo tailscale up` (on a NAS, install the Tailscale package from its app store).
3. In the [admin console](https://login.tailscale.com/admin/dns), turn on **MagicDNS** and
   **HTTPS Certificates**.
4. Give each app an HTTPS port on the machine's Tailscale address:

   ```sh
   sudo tailscale serve --bg --https=443 http://127.0.0.1:8090    # Splitwiz
   sudo tailscale serve --bg --https=8443 http://127.0.0.1:8091   # should-we
   sudo tailscale serve --bg --https=10000 http://127.0.0.1:8092  # Flowy
   ```

   `tailscale serve status` shows the addresses, such as
   `https://homeserver.your-tailnet.ts.net:8443`. They stay after a restart.

Flowy and Troye can also join Tailscale on their own, each with its own name such as
`https://flowy.your-tailnet.ts.net`: paste an
[auth key](https://login.tailscale.com/admin/settings/keys) when their installer asks for
one, or later set `TS_AUTHKEY` and `COMPOSE_FILE` in their `.env` as described there and run
the installer again.

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
