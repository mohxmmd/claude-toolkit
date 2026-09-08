#!/usr/bin/env bash
# toolkit/state.sh — what is set up in THIS repository, and what is not.
#
# Contract:
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines, <= 12 lines
#   never: writes anything, reads any source file, or touches the network.
#
# Deliberately does not call Charter's scripts. The bundle knows where its own
# root is, not where a dependency was unpacked.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
say() { printf '%s: %s\n' "$1" "$2"; }

echo "# toolkit state v1"
say repo "$(basename "$PWD")"

# ---------------------------------------------------------------- charter
say charter.state "$([ -f .claude/charter.json ] && echo yes || echo no)"
FENCE=$(grep -l 'charter:start' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1)
if [ -n "$FENCE" ]; then
  say charter.fence "$FENCE ($(sed -n '/charter:start/,/charter:end/p' "$FENCE" | wc -l | tr -d ' ')L)"
else
  say charter.fence none
fi
# Only deny/ask constrain anything. Allow rules remove prompts and protect nothing.
DENY=no
for f in .claude/settings.json .claude/settings.local.json; do
  [ -f "$f" ] && grep -q '"deny"' "$f" && DENY=yes
done
say charter.boundaries "$DENY"

# ---------------------------------------------------------------- craft
say craft.config "$([ -f .craft/config.md ] && echo yes || echo no)"

# ---------------------------------------------------------------- tars
STYLE=""
for f in .claude/settings.local.json .claude/settings.json "$CFG/settings.json"; do
  [ -f "$f" ] || continue
  V=$(sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1)
  [ -n "$V" ] && { STYLE="$V"; say tars.set_in "$f"; break; }
done
say tars.style "${STYLE:-none}"

echo "# end"
