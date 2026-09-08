#!/usr/bin/env bash
# charter/lint-rules.sh — assert generated permission rules against the gotchas.
#
# Contract:
#   in   : $1 = a settings JSON file (project, local, or a candidate written to a temp path)
#   out  : "ok"/"FAIL" lines, then a count. Exit 1 if any check failed.
#   never: writes anything, reads anything other than $1.
#
# The gotcha numbers refer to references/policy.md. Every check here exists
# because the matcher accepts the bad form silently and matches nothing.

set -u
FILE="${1:-}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: lint-rules.sh <settings.json>"; exit 2; }

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s — %s\n' "$1" "$2"; }

# Extract rule strings per list. Prefers jq; falls back to a line scan that is
# good enough for the one-rule-per-line shape Charter writes.
rules() { # rules <allow|deny|ask>
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg k "$1" '.permissions[$k] // [] | .[]' "$FILE" 2>/dev/null
  else
    sed -n "/\"$1\"[[:space:]]*:[[:space:]]*\[/,/\]/p" "$FILE" \
      | grep -oE '"[A-Za-z]+\([^"]*\)"' | tr -d '"'
  fi
}
ALLOW=$(rules allow); DENY=$(rules deny); ASK=$(rules ask)
ALL=$(printf '%s\n%s\n%s\n' "$ALLOW" "$DENY" "$ASK" | grep . || true)

echo "# charter rule lint: $FILE"

# --- 0. the file is JSON at all --------------------------------------------
if command -v jq >/dev/null 2>&1; then
  jq -e . "$FILE" >/dev/null 2>&1 && ok "parses as JSON" || bad "parses as JSON" "invalid"
fi

# --- gotcha 3: the space before a trailing * is part of the rule ------------
# Bash(ls*) has no space, so it matches lsof — a different program. Only the
# FIRST token matters: a * glued to a later argument is fine and intended, as in
# Bash(php artisan migrate*) catching migrate:fresh. So flag single-token rules
# ending in * and nothing else.
B=$(printf '%s\n' "$ALL" | grep -E '^Bash\(' || true)
V=$(printf '%s\n' "$B" | grep -E '^Bash\([^ )]*\*\)$' || true)
[ -z "$V" ] && ok "gotcha 3: no * glued to a program name" \
             || bad "gotcha 3: * glued to program name" "$(echo "$V" | tr '\n' ' ')"

# --- gotcha 4 + 17: a * before the program or the subcommand ----------------
V=$(printf '%s\n' "$B" | grep -E '^Bash\(\*' || true)
[ -z "$V" ] && ok "gotcha 17: no rule starts with *" \
             || bad "gotcha 17: rule starts with *" "$(echo "$V" | tr '\n' ' ')"
# "prog * word" — a wildcard sitting between the program and a later literal.
V=$(printf '%s\n' "$B" | grep -E '^Bash\([a-zA-Z0-9._/-]+ \* [^)]' || true)
[ -z "$V" ] && ok "gotcha 4: no * before a subcommand" \
             || bad "gotcha 4: * before subcommand" "$(echo "$V" | tr '\n' ' ')"

# --- gotcha 6: a bare environment-runner allow is a blank cheque ------------
V=$(printf '%s\n' "$ALLOW" | grep -E '^Bash\((docker exec|npx|devbox run|mise exec|direnv exec) \*\)$' || true)
[ -z "$V" ] && ok "gotcha 6: no bare environment-runner allow" \
             || bad "gotcha 6: bare runner allow" "$(echo "$V" | tr '\n' ' ')"

# --- gotcha 8: path rules that are accepted and never consulted -------------
V=$(printf '%s\n' "$ALL" | grep -E '^(Write|Glob|NotebookEdit|MultiEdit)\(.+\)$' || true)
[ -z "$V" ] && ok "gotcha 8: no ignored path-rule tools" \
             || bad "gotcha 8: ignored path rule" "$(echo "$V" | tr '\n' ' ')"

# --- gotcha 13: field-scoped rules are ignored and warned about -------------
V=$(printf '%s\n' "$ALL" | grep -E '^[A-Za-z]+\((command|file_path|path|notebook_path):' || true)
[ -z "$V" ] && ok "gotcha 13: no field-scoped rules" \
             || bad "gotcha 13: field-scoped rule" "$(echo "$V" | tr '\n' ' ')"

# --- gotcha 10: defaultMode does not apply from project/local --------------
case "$FILE" in
  *.claude/settings.json|*.claude/settings.local.json)
    grep -q '"defaultMode"' "$FILE" \
      && bad "gotcha 10: defaultMode in a project file" "auto/bypassPermissions are ignored here" \
      || ok "gotcha 10: no defaultMode key" ;;
  *) ok "gotcha 10: not a project file, skipped" ;;
esac

# --- gotcha 1 + 9: allow never does safety work ----------------------------
DUP=""
for r in $(printf '%s\n' "$ALLOW" | grep . | tr ' ' '\001'); do
  r=$(printf '%s' "$r" | tr '\001' ' ')
  printf '%s\n%s\n' "$DENY" "$ASK" | grep -Fxq "$r" && DUP="$DUP $r"
done
[ -z "$DUP" ] && ok "gotcha 1: no rule in allow and in deny/ask" \
              || bad "gotcha 1: deny beats allow, the allow is dead" "$DUP"

# --- secrets: enumerated, never globbed ------------------------------------
grep -q 'Read(\./\.env\.\*)' "$FILE" \
  && bad "secrets: Read(./.env.*) glob" "also blocks .env.example, and deny cannot carry exceptions" \
  || ok "secrets: no .env.* glob"
printf '%s\n' "$DENY" | grep -qE '^Read\(\./\*\*/\*\.pem\)$' \
  && ok "secrets: block present" || bad "secrets: block missing" "Read(./**/*.pem) not found in deny"

# --- gotcha 12: the shell re-entry block ------------------------------------
MISS=""
for r in 'Bash(sh -c *)' 'Bash(bash -c *)' 'Bash(eval *)'; do
  printf '%s\n%s\n' "$ASK" "$DENY" | grep -Fxq "$r" || MISS="$MISS $r"
done
[ -z "$MISS" ] && ok "gotcha 12: shell re-entry covered" \
               || bad "gotcha 12: shell re-entry open" "missing:$MISS"

# --- sandbox: the keys Charter must never write -----------------------------
grep -q '"filesystem"' "$FILE" \
  && bad "sandbox: filesystem key present" "once set, only managed settings can change it" \
  || ok "sandbox: no filesystem key"
grep -q '"strictAllowlist"' "$FILE" \
  && bad "sandbox: strictAllowlist present" "no effect from project or local settings" \
  || ok "sandbox: no strictAllowlist"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
