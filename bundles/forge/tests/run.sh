#!/usr/bin/env bash
# Forge's script-level assertions. No model, no network, no cost.
#
#   ./tests/run.sh

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
D="$ROOT/scripts/doctor.sh"
S="$ROOT/scripts/state.sh"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s — %s\n' "$1" "$2"; }
check(){ case "$3" in *"$2"*) ok "$1";; *) bad "$1" "expected '$2'";; esac; }
absent(){ case "$3" in *"$2"*) bad "$1" "found '$2', expected absent";; *) ok "$1";; esac; }

bash -n "$D" && ok "doctor.sh parses" || bad "doctor.sh parses" "syntax error"
bash -n "$S" && ok "state.sh parses" || bad "state.sh parses" "syntax error"

# A repo with the six-surface problem: overlapping docs, a dead reference,
# a duplicated assertion, and prose claiming an enforcement it does not have.
T=$(mktemp -d); git -C "$T" init -q .
mkdir -p "$T/.claude/rules" "$T/.ai/rules" "$T/.project-context" "$T/.craft"
cat > "$T/CLAUDE.md" <<'MD'
Never commit unless explicitly asked.
Run `npm run test` before every change.
See `docs/architecture.md` for the layout.
Build with `npm run bundle`.
MD
printf 'Never commit unless explicitly asked.\n' > "$T/.ai/rules/console.md"
printf 'Do not run migrations without asking.\n' > "$T/.claude/rules/db.md"
printf 'paths: ["src/**"]\nScoped rule, loads only for src.\n' > "$T/.claude/rules/scoped.md"
printf 'CRAFT will refuse to touch public/theme/bundle.css.\n' > "$T/.craft/config.md"
printf '{"name":"x","scripts":{"test":"jest"}}' > "$T/package.json"
git -C "$T" add -A >/dev/null 2>&1
git -C "$T" -c user.email=t@t -c user.name=t commit -qm x >/dev/null 2>&1
O=$(bash "$D" "$T")

echo "surfaces"
check "counts always-loaded surfaces"  "count.always_loaded_surfaces:"      "$O"
check "warns on surface sprawl"        "warn.surfaces:"                     "$O"
check "sees .ai/rules"                 ".ai/rules/console.md"               "$O"
check "sees .craft"                    ".craft/config.md"                   "$O"
check "scoped rule is conditional"     "surface.conditional: .claude/rules/scoped.md" "$O"
absent "scoped rule is not always"     "surface.always: .claude/rules/scoped.md"      "$O"

echo "dead references"
check "dead file reference"            "dead.ref:"                          "$O"
check "names the missing path"         "docs/architecture.md"               "$O"
check "dead command"                   "npm run bundle"                     "$O"
absent "live command not flagged"      "dead.cmd: CLAUDE.md -> npm run test" "$O"

echo "duplicates and contradictions"
check "duplicate assertion"            "dup.assertion:"                     "$O"
check "commit policy in 2 surfaces"    "contradiction.check: commit"        "$O"

echo "tier violations"
check "enforcement claim found"        "tier.claim:"                        "$O"
check "names the refuse claim"         "refuse to touch"                    "$O"
check "verdict names the gap"          "no permission rules exist"          "$O"

echo "precedence"
check "precedence gap reported"        "precedence.stated_in: nowhere"      "$O"

echo "hygiene"
L=$(printf '%s\n' "$O" | wc -l | tr -d ' ')
[ "$L" -le 120 ] && ok "output ${L} lines (<=120)" || bad "output ${L} lines" ">120"
B=$(find "$T" -newer "$T/package.json" -type f 2>/dev/null | grep -v '/.git/' | wc -l | tr -d ' ')
[ "$B" = "0" ] && ok "doctor writes nothing" || bad "doctor writes nothing" "$B files changed"
case "$O" in *SECRET*|*"KEY="*|*password*) bad "no contents leaked";; *) ok "no contents leaked";; esac

# A clean repo: no surfaces, no findings, no crash.
C=$(mktemp -d); git -C "$C" init -q .
O2=$(bash "$D" "$C")
absent "clean repo: no dead refs"      "dead.ref:"                          "$O2"
absent "clean repo: no tier claims"    "tier.claim:"                        "$O2"
check  "clean repo: still reports"     "# forge doctor v1"                  "$O2"

# Not a git repo at all.
N=$(mktemp -d)
bash "$D" "$N" >/dev/null 2>&1 && ok "runs outside a git repo" || bad "runs outside a git repo" "non-zero exit"

rm -rf "$T" "$C" "$N"
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
