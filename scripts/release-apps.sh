#!/bin/sh
# Releases every app that has changed since its last release, and returns as soon as
# the releases exist. GitHub does the rest: each release builds and signs its images,
# and .github/workflows/release.yml re-pins the installer and releases it once they're built.
#
#   scripts/release-apps.sh            show the plan, ask once, then release
#   scripts/release-apps.sh --dry-run  only show the plan
#   scripts/release-apps.sh --yes      don't ask (for a scheduled run)
#
# Each app with new commits on main gets a patch release (v1.0.0 -> v1.0.1). An app
# whose latest CI run on main isn't green is skipped. For a minor or major release,
# run `gh release create vX.Y.0 --repo selfhostit/<app> --generate-notes` by hand
# first.
#
# Needs gh, signed in with write access to the selfhostit repos.
set -eu

cd "$(dirname "$0")/.."
mode=ask
case ${1:-} in
--dry-run) mode=dry ;;
--yes) mode=yes ;;
'') ;;
*) echo "usage: $0 [--dry-run|--yes]" >&2; exit 2 ;;
esac

org=selfhostit
say() { printf '%s\n' "$*"; }
die() { printf 'release-apps: %s\n' "$*" >&2; exit 1; }

# next_patch v1.2.3 -> v1.2.4
next_patch() { echo "$1" | awk -F. '{ printf "%s.%s.%d\n", $1, $2, $3 + 1 }'; }

gh auth status >/dev/null 2>&1 || die "gh isn't signed in; run: gh auth login"

# 1. Which apps have something to release?
plan=""
apps=$(sed -n 's/^apps="\(.*\)"$/\1/p' install.sh)
for app in $apps; do
	tag=$(gh release view --repo "$org/$app" --json tagName -q .tagName)
	ahead=$(gh api "repos/$org/$app/compare/$tag...main" -q .ahead_by)
	if [ "$ahead" = 0 ]; then
		say "  $app $tag: nothing new"
		continue
	fi
	ci=$(gh run list --repo "$org/$app" --workflow CI --branch main --event push --limit 1 \
		--json conclusion -q '.[0].conclusion')
	if [ "$ci" != success ]; then
		say "  $app $tag: $ahead new commits, but CI on main is '${ci:-running}', skipping"
		continue
	fi
	next=$(next_patch "$tag")
	say "  $app $tag -> $next ($ahead new commits)"
	plan="$plan $app:$next"
done

if [ -z "$plan" ]; then
	say "Nothing to release."
	exit 0
fi

[ $mode = dry ] && exit 0
if [ $mode = ask ]; then
	printf 'Release these? [y/N] '
	read -r answer
	[ "$answer" = y ] || [ "$answer" = Y ] || exit 1
fi

# 2. Release the apps. Each tag starts a CI run on GitHub that builds, signs and publishes
# the images; the installer's release workflow re-pins them once those runs are green.
for item in $plan; do
	app=${item%%:*} next=${item#*:}
	gh release create "$next" --repo "$org/$app" --target main --generate-notes >/dev/null
	say "Released $app $next"
done
say ""
say "GitHub builds the images now (about 15 minutes); follow them with:"
say "  gh run list --repo $org/<app> --workflow CI --limit 1"
say "Once they're done, 'selfhostit update all' on your server picks them up, and within the"
say "hour the installer re-pins itself and gets a new release for new installs."
