#!/bin/sh
# Pins install.sh to the newest release of every app: for each app it finds the
# release tag, downloads the files the installer uses from that tag, and writes
# their SHA-256 into the pins list in install.sh. Run it after an app's release,
# review the diff, and commit.
#
#   scripts/pin-apps.sh          pin every app to its newest release
#   scripts/pin-apps.sh --check  only check that the pinned files match GitHub (CI)
set -eu

cd "$(dirname "$0")/.."
check=n
[ "${1:-}" = --check ] && check=y

raw=https://raw.githubusercontent.com/selfhostit
sha256() { if command -v sha256sum >/dev/null; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi; }

latest_release() { # app
	curl -fsSI "https://github.com/selfhostit/$1/releases/latest" |
		sed -n 's|.*[Ll]ocation: .*/releases/tag/\([^[:space:]]*\).*|\1|p' | tr -d '\r' | head -n 1
}

# files APP TAG: the files the installer downloads for APP at TAG
files() {
	case $1 in
	splitwiz) echo "scripts/install.sh docker-compose.yml" ;;
	should-we) echo "docker-compose.yml" ;;
	*)
		# the plasto apps list their deploy files in deploy/install.sh
		list=$(curl -fsSL "$raw/$1/$2/deploy/install.sh" | sed -n 's/^files="\(.*\)"$/\1/p')
		[ -n "$list" ] || { echo "no files= line in $1 $2 deploy/install.sh" >&2; exit 1; }
		echo deploy/install.sh
		for f in $list; do echo "deploy/$f"; done
		;;
	esac
}

if [ $check = y ]; then
	bad=0
	sed -n '/^	# pins start/,/^	# pins end/p' install.sh | grep -v '# pins' | while read -r app tag path sum; do
		got=$(curl -fsSL "$raw/$app/$tag/$path" | sha256)
		if [ "$got" = "$sum" ]; then
			echo "ok    $app $tag $path"
		else
			echo "WRONG $app $tag $path: GitHub has $got"
			exit 1
		fi
		newest=$(latest_release "$app")
		[ "$newest" = "$tag" ] || echo "note  $app has a newer release, $newest; run scripts/pin-apps.sh"
	done || bad=1
	exit $bad
fi

apps=$(sed -n 's/^apps="\(.*\)"$/\1/p' install.sh)
list=$(mktemp)
for app in $apps; do
	tag=$(latest_release "$app")
	[ -n "$tag" ] || { echo "$app has no release" >&2; exit 1; }
	for path in $(files "$app" "$tag"); do
		printf '\t%s %s %s %s\n' "$app" "$tag" "$path" "$(curl -fsSL "$raw/$app/$tag/$path" | sha256)" >>"$list"
	done
	echo "$app $tag"
done
awk -v list="$list" '
	/^\t# pins start/ { print; while ((getline line < list) > 0) print line; skip = 1; next }
	/^\t# pins end/ { skip = 0 }
	!skip { print }
' install.sh >install.sh.tmp && mv install.sh.tmp install.sh
rm -f "$list"
echo "Pinned; review with: git diff install.sh"
