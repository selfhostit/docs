#!/bin/sh
# Installs or updates selfhostit apps on this machine with Docker: a Raspberry Pi,
# a Linux server or VPS, or a NAS with SSH and Docker (Synology, QNAP, Unraid, ...).
#
#   curl -fsSL https://raw.githubusercontent.com/selfhostit/docs/main/install.sh | sh
#
# It asks which apps you want, gives each one its own folder and port, and runs
# that app's own installer (or its compose file). Then it can put them all on
# your Tailscale network with https:// addresses, which phones need: you sign in
# with a link, no keys or settings. Run it again to update: every app keeps its
# settings and data.
#
# Pick the apps without the menu:
#   curl -fsSL .../install.sh | sh -s -- splitwiz flowy
# Other settings, all optional: SELFHOSTIT_DIR (the folder that holds one folder
# per app), TZ, and TS_AUTHKEY (a Tailscale auth key, to sign in without the link).
set -eu

apps="splitwiz should-we flowy troye"

# name, port, what it does
info() {
	case $1 in
	splitwiz) echo "8090|Split shared costs with your partner or roommate" ;;
	should-we) echo "8091|Pick one option together, as a group" ;;
	flowy) echo "8092|A private period and cycle tracker" ;;
	troye) echo "8093|A private calorie and weight tracker (work in progress)" ;;
	*) return 1 ;;
	esac
}

say() { printf '\033[1m%s\033[0m\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

# interactive: true when there is a terminal to ask questions on (even with curl | sh)
interactive() { (: </dev/tty) 2>/dev/null; }

# ask "Question" default -> prints the answer
ask() {
	if interactive; then
		printf '%s [%s]: ' "$1" "$2" >/dev/tty
		read -r answer </dev/tty || answer=
		printf '%s\n' "${answer:-$2}"
	else
		printf '%s\n' "$2"
	fi
}

fetch() {
	if command -v curl >/dev/null; then curl -fsSL "$1"; else wget -qO- "$1"; fi
}

# --- Docker -------------------------------------------------------------------

# Synology keeps docker in /usr/local/bin, which is not always on the PATH
[ -x /usr/local/bin/docker ] && PATH=$PATH:/usr/local/bin

if ! command -v docker >/dev/null; then
	if [ "$(uname -s)" != Linux ] || [ -d /volume1 ]; then
		die "Docker is not installed. Install it first (on a NAS, from its app store), then run this again."
	fi
	say "Docker is not installed yet."
	case $(ask "Install it now with the official script from get.docker.com? (y/n)" y) in
	y* | Y*) fetch https://get.docker.com | sudo sh ;;
	*) die "Docker is needed: https://docs.docker.com/engine/install/" ;;
	esac
fi

# Without the docker group (as right after installing Docker), use sudo.
sudo=
if ! docker info >/dev/null 2>&1; then
	if [ "$(id -u)" != 0 ] && command -v sudo >/dev/null; then
		say "Docker needs administrator rights here, so you may be asked for your password."
		sudo=sudo
		sudo docker info >/dev/null 2>&1 || die "Docker is installed but not running."
	else
		die "Docker is installed but not running, or this account may not use it."
	fi
fi
$sudo docker compose version >/dev/null 2>&1 ||
	die "Docker Compose v2 is missing: https://docs.docker.com/compose/install/linux/"

# --- Which apps ---------------------------------------------------------------

chosen=$*
if [ -z "$chosen" ]; then
	echo
	say "selfhostit installer"
	echo
	i=0
	for app in $apps; do
		i=$((i + 1))
		printf '  %d) %-10s %s\n' "$i" "$app" "$(info "$app" | cut -d'|' -f2)"
	done
	echo
	answer=$(ask "Which apps? Numbers or names, separated by spaces, or all" all)
	[ "$answer" = all ] && answer=$apps
	for a in $answer; do
		case $a in
		*[!0-9]*) chosen="$chosen $a" ;;
		*) chosen="$chosen $(echo "$apps" | cut -d' ' -f"$a")" ;;
		esac
	done
fi
for app in $chosen; do
	info "$app" >/dev/null || die "unknown app '$app'; choose from: $apps"
done
[ -n "$chosen" ] || die "no apps chosen"

if [ -n "${SELFHOSTIT_DIR:-}" ]; then
	base=$SELFHOSTIT_DIR
elif [ -d /volume1/docker ]; then
	base=/volume1/docker # Synology
elif [ -d /mnt/user/appdata ]; then
	base=/mnt/user/appdata # Unraid
else
	base=$HOME/selfhostit
fi
base=$(ask "Folder for the apps (one folder each, with its data)" "$base")
mkdir -p "$base" 2>/dev/null || $sudo mkdir -p "$base" || die "could not create $base"

# Tailscale: once set up, keep it; with an auth key, set it up; otherwise ask.
if [ -d "$base/tailscale" ] || [ -n "${TS_AUTHKEY:-}" ]; then
	tailscale=y
elif interactive; then
	echo
	echo "Phones only install the apps and show notifications over https://. Tailscale"
	echo "(free) gives each app an https:// address that only your own devices can reach."
	tailscale=$(ask "Set up Tailscale for the apps? (y/n)" y)
else
	tailscale=n
fi

# --- Install ------------------------------------------------------------------

# The plasto-based apps (Flowy, Troye) come with deploy/install.sh, which takes
# the folder as its argument and PORT for a new install. An empty TS_AUTHKEY
# skips their own Tailscale question: the shared node below covers them.
install_plasto() { # app port dir
	fetch "https://raw.githubusercontent.com/selfhostit/$1/main/deploy/install.sh" |
		$sudo env PORT="$2" TS_AUTHKEY= sh -s -- "$3"
}

install_splitwiz() { # port dir
	fetch https://raw.githubusercontent.com/selfhostit/splitwiz/main/scripts/install.sh |
		SPLITWIZ_DIR="$2" SPLITWIZ_PORT="$1" sh
}

install_should_we() { # port dir
	$sudo mkdir -p "$2/pb_data"
	fetch https://raw.githubusercontent.com/selfhostit/should-we/main/docker-compose.yml |
		$sudo tee "$2/docker-compose.yml" >/dev/null
	if [ ! -f "$2/.env" ]; then
		tz=${TZ:-$(cat /etc/timezone 2>/dev/null || readlink /etc/localtime 2>/dev/null | sed 's|.*zoneinfo/||' || true)}
		printf 'SHOULD_WE_PORT=%s\nTZ=%s\n' "$1" "${tz:-UTC}" | $sudo tee "$2/.env" >/dev/null
	fi
	(cd "$2" && $sudo docker compose pull --quiet && $sudo docker compose up -d --remove-orphans)
}

for app in $chosen; do
	port=$(info "$app" | cut -d'|' -f1)
	dir=$base/$app
	echo
	say "== $app"
	$sudo mkdir -p "$dir"
	# Run each installer from its own folder, so none of them mistakes this
	# folder for a checkout of its repository.
	(
		cd "$dir"
		case $app in
		splitwiz) install_splitwiz "$port" "$dir" ;;
		should-we) install_should_we "$port" "$dir" ;;
		*) install_plasto "$app" "$port" "$dir" ;;
		esac
	) || die "$app did not install; see the messages above"
done

# app_port app: the port the app listens on, from its .env if it was changed
app_port() {
	port=$(sed -n 's/^\(PORT\|SPLITWIZ_PORT\|SHOULD_WE_PORT\)=//p' "$base/$1/.env" 2>/dev/null | head -n 1)
	echo "${port:-$(info "$1" | cut -d'|' -f1)}"
}

# --- Tailscale ----------------------------------------------------------------

# One Tailscale node, "selfhostit", for all the apps: one sign-in, and each app
# at https://selfhostit.<your-tailnet>.ts.net:<its port>. It uses the host's
# network to reach the apps on 127.0.0.1, where they listen.
ts() { $sudo docker exec selfhostit-tailscale tailscale --socket=/tmp/tailscaled.sock "$@"; }

# ts_status KEY: a string field of `tailscale status --json`
ts_status() {
	ts status --json --peers=false 2>/dev/null |
		sed -n "s/^ *\"$1\": *\"\([^\"]*\)\".*/\1/p" | head -n 1
}

setup_tailscale() {
	dir=$base/tailscale
	$sudo mkdir -p "$dir/state"
	$sudo tee "$dir/docker-compose.yml" >/dev/null <<-'EOF'
		# The shared Tailscale node of the selfhostit apps, written by install.sh.
		# It signs in once; the login and the https:// addresses are kept in ./state.
		name: selfhostit-tailscale
		services:
		  tailscale:
		    image: tailscale/tailscale:stable
		    container_name: selfhostit-tailscale
		    restart: unless-stopped
		    network_mode: host
		    environment:
		      TS_HOSTNAME: selfhostit
		      TS_AUTHKEY: ${TS_AUTHKEY:-}
		      TS_AUTH_ONCE: "true"
		      TS_STATE_DIR: /var/lib/tailscale
		    volumes:
		      - ./state:/var/lib/tailscale
		    mem_limit: 256m
	EOF
	(cd "$dir" && $sudo docker compose pull --quiet &&
		$sudo env TS_AUTHKEY="${TS_AUTHKEY:-}" docker compose up -d --remove-orphans) ||
		return 1

	shown=
	i=0
	while :; do
		state=$(ts_status BackendState)
		case $state in
		Running) break ;;
		NeedsLogin)
			url=$(ts_status AuthURL)
			if [ -n "$url" ] && [ "$url" != "$shown" ]; then
				echo
				say "Sign in to Tailscale (or make a free account) by opening this link:"
				echo
				echo "    $url"
				echo
				echo "Waiting for you to sign in..."
				shown=$url
			fi
			;;
		NeedsMachineAuth)
			[ "$shown" = approve ] || echo "Approve the device 'selfhostit' in https://login.tailscale.com/admin/machines"
			shown=approve
			;;
		esac
		i=$((i + 1))
		if [ "$i" -gt 900 ]; then
			echo "Tailscale is not signed in yet. Run this installer again when you are ready."
			return 1
		fi
		sleep 1
	done

	# The first `tailscale serve` turns on HTTPS for the tailnet if needed: it
	# shows a link to allow that and waits.
	say "Giving each app an https:// address"
	first=y
	for app in $chosen; do
		port=$(app_port "$app")
		if [ $first = y ]; then
			ts serve --bg --https="$port" "http://127.0.0.1:$port" || return 1
			first=n
		else
			ts serve --bg --https="$port" "http://127.0.0.1:$port" >/dev/null || return 1
		fi
	done
	ts serve status --json 2>/dev/null | grep -q "\"$port\"" || {
		echo "HTTPS is not on for your tailnet yet. Allow it with the link above, then run this installer again."
		return 1
	}
	ts_name=$(ts_status DNSName)
	ts_name=${ts_name%.}
}

ts_name=
if [ "$tailscale" = y ] || [ "$tailscale" = Y ] || [ "$tailscale" = yes ]; then
	echo
	say "== Tailscale"
	setup_tailscale || echo "Tailscale is not set up; the apps work on this machine meanwhile."
fi

# --- Done ---------------------------------------------------------------------

echo
say "Done."
for app in $chosen; do
	port=$(app_port "$app")
	if [ -n "$ts_name" ]; then
		printf '  %-10s https://%s:%s\n' "$app" "$ts_name" "$port"
	else
		printf '  %-10s http://localhost:%s   (%s)\n' "$app" "$port" "$base/$app"
	fi
done
echo
if [ -n "$ts_name" ]; then
	echo "On each phone, install the Tailscale app and sign in with the same account,"
	echo "then open these addresses and add each app to the home screen:"
	echo "  https://github.com/selfhostit/docs/blob/main/phones.md#install-the-app-on-the-phone"
	echo "The apps and their data are in $base."
else
	echo "Next, reach them from your phones over HTTPS:"
	echo "  https://github.com/selfhostit/docs/blob/main/phones.md"
fi
echo "To update, run this installer again with the same apps."
