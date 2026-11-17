#!/bin/sh
# Runs selfhostit info, list and remove against a made-up apps folder, with a stub
# docker that logs its arguments and answers like a machine where flowy and troye
# run and the shared Tailscale node serves flowy's port.
set -eu

here=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
root=$work/apps
log=$work/docker.log
mkdir -p "$work/bin" "$root"

cat >"$work/bin/docker" <<'STUB'
#!/bin/sh
echo "${PWD##*/}: $*" >>"$DOCKER_LOG"
case "${PWD##*/} $*" in
  *" info") exit 0 ;;
  "flowy compose ps -q") echo cid-flowy ;;
  "troye compose ps -q") printf 'cid-troye\ncid-troye-ts\n' ;;
  "troye compose ps -q tailscale") echo cid-troye-ts ;;
  *" compose ps -q"*) ;;
  *" compose down"*) ;;
  *"inspect -f {{.State.Running}} selfhostit-tailscale") echo true ;;
  *" inspect -f "*" cid-troye") echo "8093 " ;;
  *" inspect -f "*) echo ;;
  *"exec selfhostit-tailscale "*"status --json --peers=false")
    printf '{\n  "Self": {\n    "DNSName": "selfhostit.tail1234.ts.net.",\n' ;;
  *"exec cid-troye-ts "*"status --json --peers=false")
    printf '{\n  "Self": {\n    "DNSName": "troye.tail1234.ts.net.",\n' ;;
  *"serve status --json") echo '{"TCP":{"8092":{"HTTPS":true}}}' ;;
  *"serve --https="*" off") ;;
  *) echo "stub docker: unexpected: $*" >&2; exit 1 ;;
esac
STUB
chmod +x "$work/bin/docker"

for app in flowy troye should-we tailscale; do
  mkdir -p "$root/$app"
  echo 'services: {}' >"$root/$app/docker-compose.yml"
done
echo 'PORT=8092' >"$root/flowy/.env"
mkdir -p "$root/flowy/pb_data"
echo 'K7QM-4XRP' >"$root/flowy/pb_data/setup_code"
printf 'SHOULD_WE_PORT=8091\nTZ=UTC\n' >"$root/should-we/.env"

export DOCKER_LOG="$log" SELFHOSTIT_DIR="$root" PATH="$work/bin:$PATH"
s() { sh "$here/selfhostit" "$@"; }
fail() { echo "FAIL: $*" >&2; exit 1; }
has() { printf '%s\n' "$1" | grep -qF -- "$2" || fail "expected '$2' in:
$1"; }
hasnt() { if printf '%s\n' "$1" | grep -qF -- "$2"; then fail "did not expect '$2' in:
$1"; fi; }

# list and info skip the shared Tailscale folder
out=$(s list)
hasnt "$out" tailscale
has "$out" flowy

out=$(s info)
has "$out" "  folder:             $root/flowy"
has "$out" "  on this machine:    http://localhost:8092"
has "$out" "  from your devices:  https://selfhostit.tail1234.ts.net:8092"
has "$out" "  setup code:         K7QM-4XRP"
has "$out" "  on this machine:    http://localhost:8093"
has "$out" "  from your devices:  https://troye.tail1234.ts.net"
hasnt "$out" "https://selfhostit.tail1234.ts.net:8093"
has "$out" "  on this machine:    not running"
hasnt "$out" "https://selfhostit.tail1234.ts.net:8091"
printf '%s\n' "$out" | grep -qx tailscale && fail "info shows the tailscale folder"

out=$(s info flowy)
hasnt "$out" troye

if out=$(s info nope 2>&1); then fail "info of an unknown app should fail"; fi
has "$out" "Apps found: flowy should-we troye"

# remove refuses what is not one app
for args in tailscale ../flowy "flowy troye" nope; do
  # shellcheck disable=SC2086 # several arguments on purpose
  if s remove $args --yes >/dev/null 2>&1; then fail "remove $args should fail"; fi
done
if ! (: </dev/tty) 2>/dev/null; then
  if s remove flowy >/dev/null 2>&1; then fail "remove without a terminal needs --yes"; fi
fi
[ -d "$root/flowy" ] || fail "a refused remove deleted flowy"
grep -q 'compose down' "$log" && fail "a refused remove ran compose down"

# remove keeps the data, and takes the port off Tailscale
out=$(s remove flowy --yes)
has "$out" "Its data is still in $root/flowy"
grep -q '^flowy: compose down' "$log" || fail "remove flowy did not run compose down"
grep -q 'serve --https=8092 off' "$log" || fail "remove flowy did not turn off port 8092"
[ -f "$root/flowy/pb_data/setup_code" ] || fail "remove flowy deleted its data"

# --delete-data deletes the folder, and only that
: >"$log"
s remove should-we --yes --delete-data >/dev/null
[ ! -e "$root/should-we" ] || fail "should-we is still there"
[ -d "$root/flowy" ] && [ -d "$root/tailscale" ] || fail "remove deleted another folder"
grep -q 'serve --https=.* off' "$log" && fail "should-we was not served, so nothing to turn off"

echo "selfhostit tests passed"
