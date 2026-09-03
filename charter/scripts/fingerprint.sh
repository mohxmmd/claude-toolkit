#!/usr/bin/env bash
# charter/fingerprint.sh — cheap staleness signal. No rescan, no model.
#
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines
#   never: writes.
#
# manifest_hash covers the files whose change means "commands or deps moved".

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

say() { printf '%s: %s\n' "$1" "$2"; }
sum() { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; }

echo "# charter fingerprint v1"
say head "$(git rev-parse HEAD 2>/dev/null || echo none)"
say branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"

# hash the CONTENT of manifests plus the NAMES of workflow files
H=$( {
  for f in package.json composer.json pyproject.toml go.mod Cargo.toml Gemfile \
           Makefile justfile Taskfile.yml pnpm-workspace.yaml turbo.json; do
    [ -f "$f" ] && printf '%s\n' "$f" && cat "$f"
  done
  ls .github/workflows 2>/dev/null
  ls .claude/rules 2>/dev/null
} | sum | cut -c1-16 )
say manifest_hash "$H"

# a charter exists?
F=$(grep -l 'charter:start' CLAUDE.md .claude/CLAUDE.md 2>/dev/null | head -1)
say fence "${F:-none}"
[ -f .claude/charter.json ] && say state present || say state absent

# if state exists, report the delta since it was written
if [ -f .claude/charter.json ]; then
  OLD=$(grep -o '"head"[[:space:]]*:[[:space:]]*"[^"]*"' .claude/charter.json | sed 's/.*"\([^"]*\)"$/\1/')
  OLDH=$(grep -o '"manifest_hash"[[:space:]]*:[[:space:]]*"[^"]*"' .claude/charter.json | sed 's/.*"\([^"]*\)"$/\1/')
  say state.head "${OLD:-unknown}"
  say manifest_changed "$([ "$OLDH" = "$H" ] && echo no || echo yes)"
  if [ -n "${OLD:-}" ] && git cat-file -e "$OLD" 2>/dev/null; then
    say commits_since "$(git rev-list --count "$OLD"..HEAD 2>/dev/null || echo unknown)"
    say files_changed "$(git diff --name-only "$OLD"..HEAD 2>/dev/null | wc -l | tr -d ' ')"
  else
    say commits_since unknown
  fi
fi

echo "# end"
