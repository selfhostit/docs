# After you install

The installer ends with a list like this:

```
Done.
  flowy      https://selfhostit.your-tailnet.ts.net:8092
             setup code: K7QM-4XRP
```

Here is what to do next, and what to try when something doesn't open.

## 1. Make your account

Open the app's address and type its setup code. The code is there so nobody else who finds a
fresh install can claim it, and it is only needed once. Then create your account: you become
the app's **owner**, who can add people and open the admin page (`/_/`) with the same email
and password.

Lost the code? It is in the app's folder until the first account exists:

```sh
sudo cat ~/selfhostit/flowy/pb_data/setup_code   # your folder and app
```

## 2. Add your household

Nobody can sign themselves up, so the owner adds everyone else:

| App | How |
|---|---|
| Splitwiz | The setup screen asks for both people at once. That's all. |
| should-we | No accounts. Start a decision, tap **Share** and send the link. |
| Flowy, Troye, Shoppa, Calio | Open the admin page, the app's address with `/_/` at the end, and sign in as the owner. Then **users** > **New record**: their email, a password and the role `member`. Send them the address and the password. |

Each person only sees their own data in Flowy and Troye. In Shoppa and Calio the household
shares one list and one calendar.

## 3. Put it on your phones

On each phone, install the Tailscale app and sign in with your Tailscale account (for someone
else's phone, [share the machine](phones.md#tailscale-recommended) with their account). Then open the app's `https://` address, sign in and add it
to the home screen: [how, on Android and iPhone](phones.md#install-the-app-on-the-phone).
Turn on notifications in the app's settings if it has them.

## 4. Keep it safe and current

- **Update:** run the installer again, or `selfhostit update all` with the
  [selfhostit command](updates-and-backups.md#one-command-selfhostit-update).
- **Backups:** each app keeps a backup of its database every night. Copy them somewhere
  else too: [updates and backups](updates-and-backups.md).
- **Check:** `selfhostit check` looks for common mistakes, such as an app open to your network.

Want another app later? Run the installer again and pick it, or name it:
`curl -fsSL https://github.com/selfhostit/docs/releases/latest/download/install.sh | sh -s -- calio`.
The apps you already have keep their settings and data.

## When something doesn't open

**`http://localhost:8092` doesn't open from my laptop or phone.** That address only works on
the machine the apps run on: the apps answer nowhere else, on purpose. Run the installer
again and say yes to Tailscale, or follow [phones](phones.md) for a reverse proxy. To look
once from your laptop without either, forward the port over SSH:
`ssh -L 8092:127.0.0.1:8092 you@homeserver.local`, then open `http://localhost:8092` on the laptop.

**The Tailscale address says "connection refused" or doesn't load.** Check that:

- it starts with `https://`, not `http://`;
- the phone or laptop has the Tailscale app on and is signed in to the same account, or the
  `selfhostit` machine is shared with its account;
- the installer finished its Tailscale step. If it stopped at "HTTPS is not on for your
  tailnet yet", allow HTTPS with the link it showed and run it again.

**"Port is already allocated" or another app opens instead.** Run the installer again: it moves
an app to the next free port and lists the new address. To pick a port yourself, change it in
the app's `.env` and run the installer again.

**"permission denied" talking to Docker.** Run the installer with `sudo` in front of `sh`
(`... | sudo sh`), or sign out and in again after Docker was installed, so your account is in
the `docker` group.

**An app stopped or keeps restarting.** See what it says: `cd ~/selfhostit/flowy && docker compose logs --tail 50`
(your folder and app). On a Synology, Container Manager > Project > the app > Log shows the same.

**Still stuck?** Open an issue in the app's repository with what you ran and what it printed,
or write to kalfasyan@pm.me.
