#!/bin/sh
# Releases every app that has changed since its last release, then re-pins the
# installer and publishes a new installer release. One command for the whole round:
#
#   scripts/release-apps.sh            show the plan, ask once, then do it all
#   scripts/release-apps.sh --dry-run  only show the plan
#   scripts/release-apps.sh --yes      don't ask (for a scheduled run)
#
# Each app with new commits on main gets a patch release (v1.0.0 -> v1.0.1). An app
# whose latest CI run on main isn't green is skipped. For a minor or major release,
# run `gh release create vX.Y.0 --repo selfhostit/<app> --generate-notes` by hand
# first; this script then only re-pins the installer for it.
#
# Needs gh (signed in, with write access to the selfhostit repos), git and curl.
# Run it from a clone of selfhostit/docs with nothing uncommitted.
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
[ -z "$(git status --porcelain)" ] || die "this docs clone has uncommitted changes"
git checkout -q main
git pull -q --ff-only origin main

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

# Re-pinning is needed when an app was released since the last pin (by this script or by hand).
if [ -z "$plan" ] && scripts/pin-apps.sh --check 2>/dev/null | grep -q '^note'; then
	say "  the installer pins an older release of an app; it will be re-pinned"
elif [ -z "$plan" ]; then
	say "Nothing to release."
	exit 0
fi

last=$(gh release view --repo "$org/docs" --json tagName -q .tagName 2>/dev/null || echo v0.9.9)
installer=$(next_patch "$last")
[ "$last" = v0.9.9 ] && installer=v1.0.0
say "  installer -> $installer"

[ $mode = dry ] && exit 0
if [ $mode = ask ]; then
	printf 'Release these? [y/N] '
	read -r answer
	[ "$answer" = y ] || [ "$answer" = Y ] || exit 1
fi

# 2. Release the apps. Each tag starts a CI run that builds, signs and publishes the images.
for item in $plan; do
	app=${item%%:*} next=${item#*:}
	gh release create "$next" --repo "$org/$app" --target main --generate-notes >/dev/null
	say "Released $app $next"
done

# 3. Wait for every image build; a failed one stops here, before the installer points at it.
for item in $plan; do
	app=${item%%:*} next=${item#*:}
	run=""
	for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
		run=$(gh run list --repo "$org/$app" --workflow CI --branch "$next" --limit 1 \
			--json databaseId -q '.[0].databaseId // empty')
		[ -n "$run" ] && break
		sleep 10
	done
	[ -n "$run" ] || die "no CI run started for $app $next"
	say "Waiting for the $app $next images..."
	gh run watch "$run" --repo "$org/$app" --exit-status >/dev/null ||
		die "the $app $next build failed: gh run view $run --repo $org/$app --log-failed"
	say "  $app $next images published"
done

# 4. Re-pin the installer through a pull request, and merge it once its checks pass.
scripts/pin-apps.sh
if git diff --quiet install.sh; then
	say "The installer already pins these releases."
else
	branch="pin-apps-$installer"
	git checkout -q -b "$branch"
	git commit -q -m "Pin the installer to the new app releases" install.sh
	git push -q -u origin "$branch"
	gh pr create --fill --head "$branch" >/dev/null
	say "Opened the pins pull request; waiting for its checks..."
	sleep 15
	gh pr checks "$branch" --watch --fail-fast >/dev/null || die "the pins pull request failed its checks"
	gh pr merge "$branch" --squash --delete-branch >/dev/null
	git checkout -q main
	git pull -q --ff-only origin main
	say "Merged the new pins"
fi

# 5. Publish the installer release from main.
gh workflow run release.yml --repo "$org/docs" -f version="$installer"
say "Started the installer $installer release: gh run list --repo $org/docs --workflow release.yml"
