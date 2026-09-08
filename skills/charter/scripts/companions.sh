#!/usr/bin/env bash
# charter/companions.sh — which Forge companions are available, and what is
# already wired. Read-only.
#
# Contract:
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines on stdout, <= 20 lines
#   never: writes, installs, enables, or touches the network.
#
# A companion is "enabled" only when it is both installed AND not switched off.
# Anything less is reported as "absent", because offering to wire a plugin that
# will not load produces a setting that names a style Claude Code cannot find.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
INSTALLED="$CFG/plugins/installed_plugins.json"

have() { command -v "$1" >/dev/null 2>&1; }
JQ=0; have jq && JQ=1

say() { printf '%s: %s\n' "$1" "$2"; }

echo "# charter companions v1"

# ------------------------------------------------------------ plugin state
# installed_plugins.json keys are plugin ids, usually "<name>@<marketplace>".
# We match on the bare name so a fork under another marketplace still counts.
installed() {
  [ -f "$INSTALLED" ] || return 1
  if [ "$JQ" = 1 ]; then
    jq -e --arg n "$1" '.plugins | keys[] | select(. == $n or startswith($n + "@"))' \
      "$INSTALLED" >/dev/null 2>&1
  else
    grep -qE "\"$1(@[^\"]+)?\"[[:space:]]*:" "$INSTALLED"
  fi
}

# enabledPlugins lives in the settings files, local overriding project overriding
# user. An id absent from all three defaults to enabled.
disabled() {
  for f in .claude/settings.local.json .claude/settings.json "$CFG/settings.json"; do
    [ -f "$f" ] || continue
    if [ "$JQ" = 1 ]; then
      jq -e --arg n "$1" \
        '(.enabledPlugins // {}) | to_entries[] | select((.key | split("@")[0]) == $n) | select(.value == false)' \
        "$f" >/dev/null 2>&1 && return 0
    else
      grep -A40 'enabledPlugins' "$f" 2>/dev/null \
        | grep -qE "\"$1(@[^\"]+)?\"[[:space:]]*:[[:space:]]*false" && return 0
    fi
  done
  return 1
}

state() {
  if ! installed "$1"; then echo absent
  elif disabled "$1"; then echo disabled
  else echo enabled; fi
}

say companion.craft "$(state craft)"
say companion.tars  "$(state tars)"

# ------------------------------------------------------------ style resolution
# The plugin install and the file install expose DIFFERENT names. Writing the
# wrong one produces a setting that silently resolves to nothing.
STYLE=none
[ -f "$CFG/output-styles/TARS.md" ] && STYLE=TARS
[ -f .claude/output-styles/TARS.md ] && STYLE=TARS
[ "$(state tars)" = enabled ] && STYLE="tars:TARS"
say style.name "$STYLE"

say style.file_user   "$([ -f "$CFG/output-styles/TARS.md" ] && echo yes || echo no)"
say style.file_project "$([ -f .claude/output-styles/TARS.md ] && echo yes || echo no)"

# ------------------------------------------------------------ what is set now
current() {
  [ -f "$1" ] || return 0
  if [ "$JQ" = 1 ]; then
    jq -r '.outputStyle // empty' "$1" 2>/dev/null
  else
    sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
  fi
}
say style.set_local   "$(current .claude/settings.local.json || true)"
say style.set_project "$(current .claude/settings.json || true)"
say style.set_user    "$(current "$CFG/settings.json" || true)"

# ------------------------------------------------------------ craft wiring
say craft.config "$([ -f .craft/config.md ] && echo yes || echo no)"
FENCE=$(grep -l 'charter:start' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1)
if [ -n "$FENCE" ]; then
  # Only inside the fence. A /craft mention in the user's own prose is theirs,
  # not something Charter wrote and may therefore remove.
  if sed -n '/charter:start/,/charter:end/p' "$FENCE" | grep -qE '/craft'; then
    say craft.referenced yes
  else
    say craft.referenced no
  fi
else
  say craft.referenced no-fence
fi

echo "# end"
