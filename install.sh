#!/bin/sh
# Installs or updates selfhostit apps on this machine with Docker: a Raspberry Pi,
# a Linux server or VPS, or a NAS with SSH and Docker (Synology, QNAP, Unraid, ...).
#
#   curl -fsSL https://github.com/selfhostit/docs/releases/latest/download/install.sh | sh
#
# That is the newest release of this installer. To read and check it before running it,
# download it first (curl -fsSLO <the same URL>), then run `sh install.sh`; security.md
# says what it does step by step and how to verify it.
#
# It installs a fixed release of each app, listed below with the SHA-256 of every file
# it downloads for it, and stops if a download doesn't match.
#
# It asks which apps you want, gives each one its own folder and port (the next
# free one when another program has the usual port), and runs
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

apps="splitwiz should-we flowy troye shoppa calio"

# name, port, what it does
info() {
	case $1 in
	splitwiz) echo "8090|Split shared costs with your partner or roommate" ;;
	should-we) echo "8091|Pick one option together, as a group" ;;
	flowy) echo "8092|A private period and cycle tracker" ;;
	troye) echo "8093|A private calorie and weight tracker" ;;
	shoppa) echo "8094|A shared shopping list for your household" ;;
	calio) echo "8095|One calendar for your household: plans, pet sitting, trips" ;;
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

# --- Pinned releases ------------------------------------------------------------

# The release of each app this installer sets up, and the SHA-256 of every file it
# downloads from it: app, tag, file, SHA-256. scripts/pin-apps.sh writes this list
# after a release, and CI checks it against GitHub.
pins() {
	cat <<-'EOF'
	# pins start
	splitwiz v1.0.1 scripts/install.sh 52b13f22478f03235122445f5e5af4e9a77c25b73973ae4e6c84e7a410f00592
	splitwiz v1.0.1 docker-compose.yml 2daf2dd844f7766bbe1e145a4954f673299d0ede595d43d748c526a331cec752
	should-we v2.2.1 docker-compose.yml 633a2e85d6e452107137797970f2ff841cebf3d6734f00cf1d941ccdbc48cc65
	flowy v1.0.1 deploy/install.sh 8837d27156bbc06e0add12b73a7b0b95ce39734be0a744b7fbd771d12e3ad2ea
	flowy v1.0.1 deploy/docker-compose.yml 168fd2068af64e78f6e974362fa9600cda5e56fbac732efc374ce641f5352a01
	flowy v1.0.1 deploy/docker-compose.tailscale.yml ab341609f947775a155d97532241fdcf1afdfc028641062aeb8ebbd59b0ba3ae
	flowy v1.0.1 deploy/tailscale-serve.json a04bce87030f08074a9e9ebf5e79d0ce7507531eecdde73ad27e17098fb77a9d
	flowy v1.0.1 deploy/.env.example 60a5432413fab9203a3f8dcc60f900b8448765ee708c8f1eede57e3e162ea6f5
	troye v0.1.1 deploy/install.sh 89b7e96d50869f8c91b935d2507e87bc1119ff704884ed6943a79cc71e4b8220
	troye v0.1.1 deploy/docker-compose.yml 479d3d020918ef56e6e24049e37e805d7d61e24efe147fb3878eb351d2ba7430
	troye v0.1.1 deploy/docker-compose.tailscale.yml b2c98d1a3374481dac364231ac1559daa924e104a7bff04dcb4d936f06f5faea
	troye v0.1.1 deploy/tailscale-serve.json a04bce87030f08074a9e9ebf5e79d0ce7507531eecdde73ad27e17098fb77a9d
	troye v0.1.1 deploy/docker-compose.host.yml 04812d2b8d78e5e0f8af6c94d71be23e246c03a39446fa853a262e13fdacc53a
	troye v0.1.1 deploy/.env.example de3c1e179895c0737793537a9c1c416ba20221fafe55d648d92a78ac9c7c4759
	shoppa v0.1.1 deploy/install.sh 8d06e189c1a0dbb13deb8c2ce9a6de26914fd41acecc6843ed2f1e585ed021fb
	shoppa v0.1.1 deploy/docker-compose.yml 8e9ad2407bb197e63252774cd9e91782a9984fcd924290c8fc66ab8965cb9f0e
	shoppa v0.1.1 deploy/docker-compose.tailscale.yml 3c37d7a5b654176f3de8bee616f0e3164979e43d47d59dd33b38b29e4e215f5c
	shoppa v0.1.1 deploy/tailscale-serve.json a04bce87030f08074a9e9ebf5e79d0ce7507531eecdde73ad27e17098fb77a9d
	shoppa v0.1.1 deploy/.env.example b506f4d369127aa9ea32145a26d60a51f26f65704c43a1177ecd428abab084e2
	calio v0.1.1 deploy/install.sh a81550ca4fecf22d4bd032cbc0e3f93a59f05c209ab63664336ec7a6c1ee9643
	calio v0.1.1 deploy/docker-compose.yml 60be31fe42b628f2f5561998146e1d222e9d18a4c348a72558cb48b4bb311b76
	calio v0.1.1 deploy/docker-compose.tailscale.yml bbe8e5437acc4bfebfc6573f3ee5320a28cccc396d951587e23e1be550f54451
	calio v0.1.1 deploy/docker-compose.funnel.yml 573b7b67cdd9347ef056e74e33558087b3e0b6c59379783b2bf288f1163207ff
	calio v0.1.1 deploy/docker-compose.shoppa.yml 73ff94faf531055ad5ba7f694f878237f6c5213bd49eb0e95dd1e757acb457f6
	calio v0.1.1 deploy/tailscale-serve.json a04bce87030f08074a9e9ebf5e79d0ce7507531eecdde73ad27e17098fb77a9d
	calio v0.1.1 deploy/tailscale-feed-serve.json 64d154aae85ca2e9fe9a462446d9643459313adbabcc754b807ab1a1a4f2d7b2
	calio v0.1.1 deploy/.env.example 1cf7b922f98d60ce8720b6d9801b9c96f07f942ebc026d7ca2c061289d9ad398
	# pins end
	EOF
}

sha256() {
	if command -v sha256sum >/dev/null; then
		sha256sum | cut -d' ' -f1
	elif command -v shasum >/dev/null; then
		shasum -a 256 | cut -d' ' -f1
	else
		die "sha256sum or shasum is needed to check the downloads"
	fi
}

# fetch_app APP DIR: downloads APP's pinned files into DIR, keeping their paths,
# and stops unless each one has its pinned SHA-256
fetch_app() {
	pins | grep -v '^#' | while read -r name tag path sum; do
		[ "$name" = "$1" ] || continue
		mkdir -p "$2/$(dirname "$path")"
		fetch "https://raw.githubusercontent.com/selfhostit/$name/$tag/$path" >"$2/$path" ||
			die "could not download $path of $name $tag"
		got=$(sha256 <"$2/$path")
		[ "$got" = "$sum" ] || die "$path of $name $tag is not the reviewed file (SHA-256 $got); not installing it"
	done
	[ -n "$(pins | awk -v a="$1" '$1 == a')" ] || die "no pinned release of $1"
}

# app_tag APP: the pinned release of APP
app_tag() { pins | awk -v a="$1" '$1 == a { print $2; exit }'; }

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

# taken_ports: the TCP ports that something on this machine listens on, and the
# ones Docker containers publish (stopped ones too, so they can start again)
taken_ports() {
	{ ss -ltn 2>/dev/null || netstat -an 2>/dev/null | awk '/^tcp/ && /LISTEN/'; } |
		awk '{print $4}' | sed -n 's/.*[:.]\([0-9][0-9]*\)$/\1/p'
	ids=$($sudo docker ps -aq 2>/dev/null) || ids=
	# shellcheck disable=SC2086 # one argument per container
	[ -z "$ids" ] || $sudo docker inspect --format \
		'{{range .HostConfig.PortBindings}}{{range .}}{{.HostPort}} {{end}}{{end}}' $ids 2>/dev/null |
		tr ' ' '\n'
}

# free_port PORT: PORT if nothing uses it, else the first free port after it
free_port() {
	taken=" $(taken_ports | tr '\n' ' ') "
	p=$1
	while :; do
		case $taken in *" $p "*) p=$((p + 1)) ;; *) break ;; esac
	done
	echo "$p"
}

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

# Each app's files are downloaded into a scratch folder and checked first (fetch_app).
# The plasto-based apps (Flowy, Troye, Shoppa, Calio) come with deploy/install.sh, which takes
# the folder as its argument and PORT for a new install (or the next free port
# when that one is taken; Splitwiz's installer does the same). Run from the scratch
# folder, they use the checked files next to them. An empty TS_AUTHKEY skips their
# own Tailscale question: the shared node below covers them.
install_plasto() { # app port dir
	$sudo env PORT="$2" TS_AUTHKEY= sh "$tmp/$1/deploy/install.sh" "$3"
}

install_splitwiz() { # port dir
	SPLITWIZ_DIR="$2" SPLITWIZ_PORT="$1" sh "$tmp/splitwiz/scripts/install.sh"
}

install_should_we() { # port dir
	$sudo mkdir -p "$2/pb_data"
	$sudo cp "$tmp/should-we/docker-compose.yml" "$2/docker-compose.yml"
	if [ ! -f "$2/.env" ]; then
		port=$(free_port "$1")
		[ "$port" = "$1" ] || echo "Port $1 is taken, so should-we gets port $port."
		tz=${TZ:-$(cat /etc/timezone 2>/dev/null || readlink /etc/localtime 2>/dev/null | sed 's|.*zoneinfo/||' || true)}
		printf 'SHOULD_WE_PORT=%s\nTZ=%s\n' "$port" "${tz:-UTC}" | $sudo tee "$2/.env" >/dev/null
	fi
	(cd "$2" && $sudo docker compose pull --quiet && $sudo docker compose up -d --remove-orphans)
}

tmp=$(mktemp -d)
trap 'rm -r "$tmp"' EXIT
for app in $chosen; do
	port=$(info "$app" | cut -d'|' -f1)
	dir=$base/$app
	echo
	say "== $app $(app_tag "$app")"
	fetch_app "$app" "$tmp/$app"
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
	# a new install asks for this one-time code on its setup screen
	code=$($sudo cat "$base/$app/pb_data/setup_code" 2>/dev/null || true)
	[ -z "$code" ] || printf '  %-10s setup code: %s\n' "" "$code"
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
