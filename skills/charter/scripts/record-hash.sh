#!/usr/bin/env bash
# charter/record-hash.sh — re-sync charter.json to the current repo state.
#
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: old -> new" lines on stderr-free stdout
#   writes: .claude/charter.json only, and only the head / manifest_hash values.
#
# Exists so /charter:check never has to improvise an inline interpreter call to
# patch two scalars. An improvised `python3 -c` cannot be covered by allowed-tools
# and prompts the user every single run.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT" >&2; exit 1; }

STATE=.claude/charter.json
[ -f "$STATE" ] || { echo "error: no $STATE — run /charter:init first" >&2; exit 2; }

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
FP="$HERE/fingerprint.sh"
[ -x "$FP" ] || { echo "error: cannot run $FP" >&2; exit 1; }

FPOUT=$("$FP" .) || { echo "error: fingerprint failed" >&2; exit 1; }
NEW_HEAD=$(printf '%s\n' "$FPOUT" | awk '/^head:/{print $2; exit}')
NEW_HASH=$(printf '%s\n' "$FPOUT" | awk '/^manifest_hash:/{print $2; exit}')

case "$NEW_HEAD" in ''|none) echo "error: no git HEAD to record" >&2; exit 2;; esac
[ -n "$NEW_HASH" ] || { echo "error: fingerprint produced no manifest_hash" >&2; exit 1; }

val() { grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$STATE" | head -1 | sed 's/.*"\([^"]*\)"$/\1/'; }
OLD_HEAD=$(val head)
OLD_HASH=$(val manifest_hash)

TMP=$(mktemp "${TMPDIR:-/tmp}/charter-state.XXXXXX") || exit 1
trap 'rm -f "$TMP"' EXIT

awk -v h="$NEW_HEAD" -v m="$NEW_HASH" '
  !dh && /"head"[[:space:]]*:[[:space:]]*"/ {
    sub(/"head"[ \t]*:[ \t]*"[^"]*"/, "\"head\": \"" h "\""); dh = 1
  }
  !dm && /"manifest_hash"[[:space:]]*:[[:space:]]*"/ {
    sub(/"manifest_hash"[ \t]*:[ \t]*"[^"]*"/, "\"manifest_hash\": \"" m "\""); dm = 1
  }
  { print }
  END { if (!dh) exit 3; if (!dm) exit 4 }
' "$STATE" > "$TMP"

case $? in
  0) ;;
  3) echo "error: $STATE has no string \"head\" key — not touched" >&2; exit 3;;
  4) echo "error: $STATE has no string \"manifest_hash\" key — not touched" >&2; exit 4;;
  *) echo "error: rewrite failed — $STATE not touched" >&2; exit 1;;
esac

# never leave a truncated state file behind
[ -s "$TMP" ] || { echo "error: empty rewrite — $STATE not touched" >&2; exit 1; }

cat "$TMP" > "$STATE" || { echo "error: could not write $STATE" >&2; exit 1; }

printf 'head: %s -> %s\n' "${OLD_HEAD:-unknown}" "$NEW_HEAD"
printf 'manifest_hash: %s -> %s\n' "${OLD_HASH:-unknown}" "$NEW_HASH"
