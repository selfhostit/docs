# Security and privacy

This page says how the selfhostit apps protect your data, what you are trusting when you
install them, and what is not done yet. Each point links to the code or the setting, so you
can check it rather than take it on trust.

Found a security problem? Please don't open a public issue. Write to **kalfasyan@pm.me**
with what you found and how to reproduce it; see [SECURITY.md](https://github.com/selfhostit/.github/blob/main/SECURITY.md).

## In short

- **Your data stays on your machine.** Each app keeps everything in one folder (`pb_data`,
  a SQLite database and its files). There is no selfhostit cloud, account or server, and the
  apps have no analytics or tracking.
- **The apps are not on the internet.** Every app listens on `127.0.0.1` only. You reach
  them through [Tailscale](phones.md#tailscale-recommended), a private network of your own
  devices, or through your own reverse proxy. The guides say not to forward ports.
- **Nobody can claim a new install before you.** A fresh install prints a one-time setup
  code, and the first-run screen asks for it.
- **The code is open** (MIT) and small enough to read: one Go backend on
  [PocketBase](https://pocketbase.io) and one Svelte web app per app.

## What protects an install

| What | Where |
|---|---|
| Apps listen on `127.0.0.1` only, so only this machine (and Tailscale or a reverse proxy on it) can connect | `ports:` in each app's compose file, for example [Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/docker-compose.yml) |
| Containers drop every Linux capability and can't gain new privileges; Flowy and Troye also run as a normal user (Splitwiz and should-we not yet) | same compose files: `cap_drop: [ALL]`, `security_opt`, `user:` |
| One-time setup code: the first account (the owner) can only be made with the code printed at install, which is deleted after setup | `backend/app/setup.go` in [plasto](https://github.com/selfhostit/plasto/blob/main/backend/app/setup.go), Flowy, Troye and Splitwiz |
| Sign-in rate limits: 10 password attempts a minute for people and for the admin UI, 5 a minute for setup | `backend/migrations/*_rate_limits.go` in each app |
| Access rules on every collection: people only see their own records or their group's | the collection API rules in `backend/migrations` |
| Content Security Policy, `nosniff` and a same-origin referrer on the web app, so injected scripts and outside resources don't load | `backend/app/headers.go` in each app |
| Discreet reminders (Flowy, off by default): notifications only say "Reminder from Flowy", for a lock screen others can see | Flowy settings, `discreet_reminders` |
| Nightly database backups, the last 7 kept | [Updates and backups](updates-and-backups.md#backups) |

## How the code and images are built

- Every app is built and tested in GitHub Actions on each pull request and push: Go and
  web tests, type checks, and (for the plasto apps) an end-to-end run of the published
  compose file.
- Workflows run with a read-only token by default (`permissions: contents: read`); only the
  job that publishes images gets `packages: write`.
- Every third-party Action is pinned to a full commit hash, not a movable tag.
- [Dependabot](https://docs.github.com/code-security/dependabot) keeps the Actions up to date
  in every repository, and in plasto, Flowy and Troye also the Go, npm, Python and Docker
  dependencies.
- should-we also scans every push for committed secrets with gitleaks.
- Images are published to [ghcr.io/selfhostit](https://github.com/orgs/selfhostit/packages)
  for amd64, arm64 and armv7. A release (`v1.2.3`, with notes in each app's `CHANGELOG.md`)
  moves `latest`, which installs follow; changes on `main` only go to `edge`.
- Every published image has a signed build provenance attestation, which says which
  workflow run, repository and commit built it. Check one with the
  [GitHub CLI](https://cli.github.com):
  `gh attestation verify oci://ghcr.io/selfhostit/flowy:latest --repo selfhostit/flowy`.

## What you are trusting

Being honest about this matters more than sounding safe.

- **The installer and the images come from this GitHub organization.** The installer
  downloads each app's installer or compose file from that app's `main` branch, and the apps
  run the newest release. An attestation proves an image was built by the app's own CI from
  a commit in its repository, not that the commit is harmless: someone who took over the
  maintainer's GitHub account could still publish a bad release.
- **Docker and the host.** The containers are locked down, but Docker itself runs as root,
  and anyone with access to the machine can read `pb_data`. The data on disk is not
  encrypted, so encrypt backups that leave the machine and wipe the disk before you sell it.
- **Tailscale**, if you use it, to keep your private network private. Turn on two-factor
  sign-in for your Tailscale account and only share the machine with people you trust.
- **What the apps send out:** push notifications go through your phone's browser push
  service (Apple, Google or Mozilla), encrypted end to end so the service can't read them.
  Troye looks up scanned barcodes on Open Food Facts and downloads its food table once a
  month. Nothing else leaves your server.

## Read the installer before you run it

`curl ... | sh` runs a script straight from the internet. To read it first:

```sh
curl -fsSLO https://raw.githubusercontent.com/selfhostit/docs/main/install.sh
less install.sh      # read it
sh install.sh
```

It is one plain shell script with comments. What it does:

1. Installs Docker with Docker's official script, only if Docker is missing and you say yes.
2. Makes one folder per app (in `~/selfhostit`, or `/volume1/docker` on a Synology).
3. For each app you pick, downloads and runs that app's own installer or compose file from
   GitHub ([Flowy](https://github.com/selfhostit/flowy/blob/main/deploy/install.sh),
   [Troye](https://github.com/selfhostit/troye/blob/main/deploy/install.sh),
   [Shoppa](https://github.com/selfhostit/shoppa/blob/main/deploy/install.sh),
   [Calio](https://github.com/selfhostit/calio/blob/main/deploy/install.sh),
   [Splitwiz](https://github.com/selfhostit/splitwiz/blob/main/scripts/install.sh),
   [should-we](https://github.com/selfhostit/should-we/blob/main/docker-compose.yml)).
   Read those too if you want to see every step.
4. If you say yes, starts one Tailscale container and gives each app an `https://` address.

It uses `sudo` only to run Docker when your user can't, and changes nothing outside those
folders and Docker. Rather not run any script? Set the apps up from their compose files
yourself: see [Synology without SSH](synology.md#without-ssh) and
[other NAS and home servers](other-nas.md).

### Pin a version

To decide yourself when to update, pin an image to a release instead of `latest`, in the
app's `.env`: `FLOWY_IMAGE=ghcr.io/selfhostit/flowy:1.2.0` (one release) or `:1` (every 1.x),
or `SPLITWIZ_VERSION=1.2.0`. should-we follows its major version (`:2`). The releases and
what changed in each are on each repository's Releases page and in its `CHANGELOG.md`.

## Project status

selfhostit is young and run by one person, [Yannis Kalfas](https://github.com/kalfasyan).
There has been no independent security audit. The history of every change is public in
each repository, and the hardening above was added in public pull requests.

If the project ever stops, your install keeps working: the images stay on ghcr.io, the code
is MIT licensed so anyone can keep building it, and your data is a SQLite database in
`pb_data` that you own. Splitwiz and Flowy also export everything as CSV.

## Not done yet

These are planned, in roughly this order:

- Splitwiz and should-we running as a normal user inside their containers, like Flowy and Troye.
- A "sign out everywhere" button in every app (Flowy has it), for a lost phone.
- An OpenSSF Scorecard run on each repository.

## Your part

- Keep the apps updated: `selfhostit update all` or the installer again
  ([Updates and backups](updates-and-backups.md)).
- Keep a backup somewhere else, encrypted.
- Don't forward ports to the apps; use Tailscale or your own reverse proxy with HTTPS.
- Use a strong password for the owner account; it is also the admin UI (`/_/`) password.
