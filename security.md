# Security and privacy

This page says how the selfhostit apps protect your data, what you are trusting when you
install them, and what is not done yet. Each point links to the code or the setting, so you
can check it rather than take it on trust.

Found a security problem? Please don't open a public issue. Use **Report a vulnerability**
on the app's Security tab on GitHub, or write to **kalfasyan@pm.me**. Every repository has a
`SECURITY.md` with the details: a reply within 7 days, critical fixes released within 7 days,
and a published advisory after each fix ([policy](https://github.com/selfhostit/.github/blob/main/SECURITY.md)).

## In short

- **Your data stays on your machine.** Each app keeps everything in one folder (`pb_data`,
  a SQLite database and its files). There is no selfhostit cloud, account or server, and the
  apps have no analytics or tracking.
- **The apps are not on the internet.** Every app listens on `127.0.0.1` only. You reach
  them through [Tailscale](phones.md#tailscale-recommended), a private network of your own
  devices, or through your own reverse proxy. The guides say not to forward ports.
- **Locked-down containers:** a normal user, no Linux capabilities, a read-only filesystem.
- **Nobody can claim a new install before you.** A fresh install prints a one-time setup
  code, and the first-run screen asks for it.
- **The installer installs reviewed releases,** checks every file it downloads against a
  SHA-256 it pins, and is itself a signed release.
- **Every change is scanned** for vulnerabilities and leaked secrets, and again every week.
- **The code is open** (MIT) and small enough to read: one Go backend on
  [PocketBase](https://pocketbase.io) and one Svelte web app per app.

## What protects an install

| What | Where |
|---|---|
| Apps listen on `127.0.0.1` only, so only this machine (and Tailscale or a reverse proxy on it) can connect | `ports:` in each app's compose file, for example [Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/docker-compose.yml) |
| Containers run as a normal user, drop every Linux capability, can't gain new privileges, and have a read-only filesystem apart from their data folder and `/tmp` | same compose files: `user:`, `cap_drop: [ALL]`, `security_opt`, `read_only: true`. Splitwiz and should-we start as root only to hand their data folder to that user, then switch ([code](https://github.com/selfhostit/splitwiz/blob/main/backend/app/privileges_linux.go)) |
| No Docker socket, no privileged mode, no host network for the apps | the compose files (only the optional Tailscale node uses the host network, to reach the apps on `127.0.0.1`) |
| One-time setup code: the first account (the owner) can only be made with the code printed at install, which is deleted after setup | `backend/app/setup.go` in [plasto](https://github.com/selfhostit/plasto/blob/main/backend/app/setup.go) and each app built on it, and Splitwiz |
| Sign-in rate limits: 10 password attempts a minute for people and for the admin UI, 5 a minute for setup | `backend/migrations/*_rate_limits.go` in each app |
| Access rules on every collection: people only see their own records or their group's. In Flowy, others on the same server see only your name and role, not your cycle settings or day logs, and tests check it | the collection API rules in `backend/migrations` |
| Content Security Policy (`script-src 'self'`), `nosniff`, `frame-ancestors 'none'` and a same-origin referrer, so injected scripts and outside resources don't load | `backend/app/headers.go` in each app |
| Discreet reminders (Flowy, off by default): notifications only say "Reminder from Flowy", for a lock screen others can see | Flowy settings, `discreet_reminders` |
| Nightly database backups, the last 7 kept, and a guide to restore one | [Updates and backups](updates-and-backups.md#backups) |

## Can I put the apps on the internet?

- **Through Tailscale: yes, and the installer offers to set it up.** The apps stay off the
  internet; only your own devices, signed in to your Tailscale account, can reach them, over
  an encrypted connection with an `https://` address.
- **On a public address, with your own reverse proxy:** you can, but then anyone can reach
  the sign-in page and try passwords, and you take on keeping that safe. Only do it with
  HTTPS, with the admin UI (`/_/`) blocked at the proxy, with a long unique password for
  every account, and with the apps kept updated. [Phones](phones.md#your-own-domain-with-a-reverse-proxy)
  shows a proxy setup that does this. The apps limit password attempts, but have no
  two-step sign-in yet.
- **By forwarding an app's port in your router: no.** That serves the app over plain
  `http://`, so passwords cross the internet readable.

## What not to keep in the apps yet

The apps are built for household data: periods, food, expenses, plans. Until the database
is encrypted on disk and there has been an independent review, don't make them the only
place you keep passwords, bank or card details, identity documents or medical records,
and keep an encrypted [backup](updates-and-backups.md#backups) of what you do keep.

## Sign-in, sessions and logs

All of this is PocketBase's standard behavior, which the apps keep.

- **Passwords** are stored only as bcrypt hashes, never in plain text or in a log. The
  owner's password is also the password of the admin UI (`/_/`).
- **Sessions:** signing in gives the app a signed token, which it keeps in the browser's
  local storage (not a cookie, so other sites can't make the browser send it). It expires
  after 5 days, counted from when the app last renewed it: the apps built on plasto renew
  it when you open them, Splitwiz asks you to sign in again. The Content
  Security Policy above is what keeps a script that isn't the app's own from reading it.
- **Changing your password, or your email address, signs out every device** that was
  signed in with the old one. Flowy also has "sign out on all devices".
- **should-we has no passwords:** people join a decision through its link, with a name.
- **Logs:** each app records its requests (time, method, address, status, IP address, and
  who made it) in `pb_data/auxiliary.db` and keeps them 5 days. Request bodies, and with
  them passwords and what you log in the apps, are not recorded. The log only leaves the
  machine if you copy it.
- **On disk,** the database is not encrypted; see [What you are trusting](#what-you-are-trusting).
  Backups can be: [Updates and backups](updates-and-backups.md#backups) shows how to
  encrypt a copy.

## How the code and images are built

- Every app is built and tested in GitHub Actions on each pull request and push: Go and
  web tests, type checks, and an end-to-end run of the published compose file that also
  checks the container's user and read-only filesystem.
- **Security scans** (`.github/workflows/security.yml` in each app) on every pull request,
  every push to `main` and every Monday:
  [CodeQL](https://codeql.github.com) on the Go, web, Python and workflow code;
  [govulncheck](https://go.dev/doc/security/vuln/) on the Go code the app can reach;
  [Grype](https://github.com/anchore/grype) on the web and worker dependencies and on the
  released images; GitHub's dependency review on new dependencies; and
  [gitleaks](https://github.com/gitleaks/gitleaks) on the whole history. A known high or
  critical vulnerability with a fix fails the check. CodeQL's findings are on each
  repository's Security tab.
- GitHub's own protections are on in every repository: secret scanning with push
  protection, Dependabot alerts and security updates, private vulnerability reporting, and
  immutable releases (a published release's tag and files can't be changed).
- Workflows run with a read-only token by default (`permissions: contents: read`); only the
  jobs that publish images or releases get more.
- Every third-party Action is pinned to a full commit hash, not a movable tag.
- [Dependabot](https://docs.github.com/code-security/dependabot) keeps the Actions up to date
  in every repository, and in the apps built on plasto also the Go, npm, Python and Docker
  dependencies.
- Images are published to [ghcr.io/selfhostit](https://github.com/orgs/selfhostit/packages)
  for amd64, arm64 and armv7. A release (`v1.2.3`, with notes in each app's `CHANGELOG.md`)
  moves the major version tag (`:1`), which installs follow; changes on `main` only go to
  `edge`.
- Every published image has a signed build provenance attestation, which says which
  workflow run, repository and commit built it. Check one with the
  [GitHub CLI](https://cli.github.com):
  `gh attestation verify oci://ghcr.io/selfhostit/flowy:1 --repo selfhostit/flowy`.

## What you are trusting

Being honest about this matters more than sounding safe.

- **The installer and the images come from this GitHub organization.** The installer
  installs the app releases it pins, and the apps then update within their major version.
  An attestation proves an image was built by the app's own CI from a commit in its
  repository, and a pinned SHA-256 proves a file is the one that was reviewed, not that
  either is harmless: someone who took over the maintainer's GitHub account could still
  publish a bad release.
- **Docker and the host.** The containers are locked down, but Docker itself runs as root,
  and anyone with access to the machine can read `pb_data`. The data on disk is not
  encrypted, so encrypt backups that leave the machine and wipe the disk before you sell it.
- **Tailscale**, if you use it, to keep your private network private. Turn on two-factor
  sign-in for your Tailscale account and only share the machine with people you trust.
  Its container follows Tailscale's `stable` image.
- **What the apps send out:** push notifications go through your phone's browser push
  service (Apple, Google or Mozilla), encrypted end to end so the service can't read them.
  Troye looks up scanned barcodes on Open Food Facts and downloads its food table once a
  month. Nothing else leaves your server.

## Read and check the installer before you run it

`curl ... | sh` runs a script straight from the internet. To read it and check it first:

```sh
curl -fsSLO https://github.com/selfhostit/docs/releases/latest/download/install.sh
gh attestation verify install.sh --repo selfhostit/docs   # built by this repository's release workflow
less install.sh                                           # read it
sh install.sh
```

Without the GitHub CLI, compare `sha256sum install.sh` with `SHA256SUMS` on the
[release page](https://github.com/selfhostit/docs/releases/latest).

It is one plain shell script with comments. What it does:

1. Installs Docker with Docker's official script, only if Docker is missing and you say yes.
2. Makes one folder per app (in `~/selfhostit`, or `/volume1/docker` on a Synology).
3. For each app you pick, downloads that app's installer or compose file **from the release
   the installer pins**, checks each file against the SHA-256 written in the installer, and
   stops if one doesn't match. Then it runs that installer
   ([Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/install.sh),
   [Troye](https://github.com/selfhostit/troye/blob/main/deploy/install.sh),
   [Shoppa](https://github.com/selfhostit/shoppa/blob/main/deploy/install.sh),
   [Calio](https://github.com/selfhostit/calio/blob/main/deploy/install.sh),
   [Splitwiz](https://github.com/selfhostit/splitwiz/blob/main/scripts/install.sh)) or
   starts the compose file ([should-we](https://github.com/selfhostit/should-we/blob/main/docker-compose.yml)).
4. If you say yes, starts one Tailscale container and gives each app an `https://` address.

The pinned list is updated with `scripts/pin-apps.sh` after an app's release, and CI checks
every week that each pinned file still matches GitHub.

### What needs sudo

The installer changes nothing outside the app folders and Docker. It uses `sudo` only for:

- **Installing Docker**, if it is missing and you say yes: Docker's own script needs root.
- **Running Docker,** when your user isn't in the `docker` group (as right after installing
  Docker): `docker compose pull`, `up`, `ps` and `inspect`, and `docker exec` into the
  Tailscale container.
- **Writing in the apps' folder** when that needs it (`/volume1/docker` on a Synology):
  making each app's folder, its `docker-compose.yml` and `.env`, and giving its `pb_data` to
  the user the app runs as.
- **Reading each new app's one-time setup code** from its `pb_data`, to show it to you.

Rather not run any script? Set the apps up from their compose files
yourself: see [Synology without SSH](synology.md#without-ssh) and
[other NAS and home servers](other-nas.md).

### Pin a version

The compose files follow an app's major version (`:1`), so updates never jump to a new
major version on their own. To decide yourself when to update, pin a release in the app's
`.env`: `FLOWY_IMAGE=ghcr.io/selfhostit/flowy:1.2.0` or `SPLITWIZ_VERSION=1.2.0`. The
releases and what changed in each are on each repository's Releases page and in its
`CHANGELOG.md`.

## Project status

selfhostit is young and run by one person, [Yannis Kalfas](https://github.com/kalfasyan).
There has been no independent security audit. The history of every change is public in
each repository, and the hardening above was added in public pull requests.

If the project ever stops, your install keeps working: the images stay on ghcr.io, the code
is MIT licensed so anyone can keep building it, and your data is a SQLite database in
`pb_data` that you own. Splitwiz and Flowy also export everything as CSV.

## Not done yet

These are planned, in roughly this order:

- A "sign out everywhere" button in every app (Flowy has it), for a lost phone.
- Two-step sign-in, for anyone who puts an app on a public address.
- An OpenSSF Scorecard run on each repository.
- An independent security review. If you do one, please share what you find through the
  reporting route above; findings and fixes will be published as advisories.

## Your part

- Keep the apps updated: `selfhostit update all` or the installer again
  ([Updates and backups](updates-and-backups.md)).
- Keep a backup somewhere else, encrypted.
- Don't forward ports to the apps; use Tailscale, or your own reverse proxy with HTTPS and
  the admin UI (`/_/`) blocked.
- Restore a backup once, to know it works ([how](updates-and-backups.md#restore-a-backup)).
- Use a strong password for the owner account; it is also the admin UI (`/_/`) password.
