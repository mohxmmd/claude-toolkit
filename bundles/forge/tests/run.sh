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


# ------------------------------------------------------------------- update
U2="$ROOT/scripts/update.sh"
sh -n "$U2" && ok "update.sh parses" || bad "update.sh parses" "syntax error"
"$U2" --help >/dev/null 2>&1 && ok "update.sh --help exits 0" || bad "update.sh --help" "non-zero exit"

# The weekly check writes a hook into settings.json. What must survive that is
# somebody else's SessionStart hook sitting in the same array.
W=$(mktemp -d)
cat > "$W/settings.json" <<'JSON'
{
  "theme": "dark",
  "hooks": {
    "SessionStart": [ { "hooks": [ { "type": "command", "command": "/not/ours.sh" } ] } ],
    "PostToolUse": [ { "matcher": "Write", "hooks": [ { "type": "command", "command": "fmt" } ] } ]
  }
}
JSON

echo "update: weekly on"
OW=$(CLAUDE_CONFIG_DIR="$W" sh "$U2" --weekly --yes 2>&1)
check "installs the hook script"   "weekly-update.sh"        "$OW"
[ -x "$W/forge/weekly-update.sh" ] && ok "hook script is executable" || bad "hook script is executable" "missing or not +x"
grep -q 'weekly-update.sh' "$W/settings.json" && ok "hook registered in settings" || bad "hook registered in settings" "not found"
grep -q '"async"' "$W/settings.json" && ok "hook is async" || bad "hook is async" "async flag missing"
grep -q '/not/ours.sh' "$W/settings.json" && ok "foreign hook survives install" || bad "foreign hook survives install" "removed"
grep -q '"PostToolUse"' "$W/settings.json" && ok "other events untouched" || bad "other events untouched" "removed"

# A stub claude on PATH, so the gate can be tested without the real CLI and
# without touching a real plugin install.
mkdir -p "$W/bin"
cat > "$W/bin/claude" <<'STUB'
#!/bin/sh
echo "stub claude $*"
exit 0
STUB
chmod +x "$W/bin/claude"

echo "update: the seven-day gate"
PATH="$W/bin:$PATH" CLAUDE_CONFIG_DIR="$W" sh "$W/forge/weekly-update.sh"
L1=$(wc -l < "$W/forge/update.log" 2>/dev/null || echo 0)
[ "$L1" -gt 0 ] && ok "first run checks" || bad "first run checks" "log is empty"
PATH="$W/bin:$PATH" CLAUDE_CONFIG_DIR="$W" sh "$W/forge/weekly-update.sh"
L2=$(wc -l < "$W/forge/update.log" 2>/dev/null || echo 0)
[ "$L1" = "$L2" ] && ok "second run inside 7 days does nothing" || bad "second run does nothing" "log grew"
touch -d '8 days ago' "$W/forge/last-update-check" 2>/dev/null || touch -t "$(date -v-8d +%Y%m%d0000 2>/dev/null || echo 200001010000)" "$W/forge/last-update-check"
PATH="$W/bin:$PATH" CLAUDE_CONFIG_DIR="$W" sh "$W/forge/weekly-update.sh"
L3=$(wc -l < "$W/forge/update.log" 2>/dev/null || echo 0)
[ "$L3" -gt "$L2" ] && ok "run after 8 days checks again" || bad "run after 8 days checks again" "log did not grow"
[ -d "$W/forge/update.lock" ] && bad "lock is released" "still present" || ok "lock is released"

echo "update: weekly off"
OW=$(CLAUDE_CONFIG_DIR="$W" sh "$U2" --no-weekly 2>&1)
grep -q 'weekly-update.sh' "$W/settings.json" && bad "hook deregistered" "still in settings" || ok "hook deregistered"
[ -e "$W/forge/weekly-update.sh" ] && bad "hook script removed" "still present" || ok "hook script removed"
grep -q '/not/ours.sh' "$W/settings.json" && ok "foreign hook survives removal" || bad "foreign hook survives removal" "removed"
[ -f "$W/forge/update.log" ] && ok "log is kept" || bad "log is kept" "deleted"

rm -rf "$W"


# ---------------------------------------------------------------- uninstall
U="$ROOT/scripts/uninstall.sh"
sh -n "$U" && ok "uninstall.sh parses" || bad "uninstall.sh parses" "syntax error"
"$U" --help >/dev/null 2>&1 && ok "uninstall.sh --help exits 0" || bad "uninstall.sh --help" "non-zero exit"

# A project Charter and Craft have set up, with a receipt, plus rules and prose
# the user wrote. Removal must take the first and leave the second.
P=$(mktemp -d); G=$(mktemp -d)
mkdir -p "$P/.claude/rules" "$P/.craft" "$P/.forge"
printf '{"theme":"dark"}\n' > "$G/settings.json"
printf '# Mine\n\nMy own prose.\n\n<!-- charter:start v1 -->\nagreement\n<!-- charter:end -->\n\nMore of mine.\n' > "$P/CLAUDE.md"
printf '{"permissions":{"deny":["Bash(git push --force*)","Edit(mine.txt)"]}}\n' > "$P/.claude/settings.json"
printf '{"v":1}\n' > "$P/.claude/charter.json"
printf 'rule\n' > "$P/.claude/rules/secrets.md"
printf 'config\n' > "$P/.craft/config.md"
printf 'node_modules/\n.craft/cache/\nmyown.txt\n' > "$P/.gitignore"
{
  printf '# component\tkind\tpath\ta\tb\n'
  printf 'charter\tpath\t.claude/charter.json\n'
  printf 'charter\tpath\t.claude/rules/secrets.md\n'
  printf 'charter\tfence\tCLAUDE.md\t<!-- charter:start v1 -->\t<!-- charter:end -->\n'
  printf 'charter\tsettings\t.claude/settings.json\tdeny\tBash(git push --force*)\n'
  printf 'craft\tpath\t.craft\n'
  printf 'craft\tgitignore\t.gitignore\t.craft/cache/\n'
} > "$P/.forge/manifest.tsv"

echo "uninstall: plan"
OU=$(cd "$P" && CLAUDE_CONFIG_DIR="$G" sh "$U" --plan --keep-plugins 2>&1)
check "plan reads the receipt"     ".forge/manifest.tsv"        "$OU"
check "plan names the fence"       "fence         CLAUDE.md"    "$OU"
check "plan names a settings rule" "deny rule Bash(git push"    "$OU"
[ -f "$P/.claude/charter.json" ] && ok "plan removes nothing" || bad "plan removes nothing" "charter.json is gone"

echo "uninstall: removal"
OU=$(cd "$P" && CLAUDE_CONFIG_DIR="$G" sh "$U" --yes --keep-plugins 2>&1)
grep -q 'charter:start' "$P/CLAUDE.md" && bad "fence removed" "markers still present" || ok "fence removed"
grep -q 'My own prose' "$P/CLAUDE.md"  && ok "prose survives"  || bad "prose survives" "user content lost"
grep -q 'More of mine' "$P/CLAUDE.md"  && ok "tail survives"   || bad "tail survives" "content after fence lost"
grep -q 'Edit(mine.txt)' "$P/.claude/settings.json" && ok "user rule survives" || bad "user rule survives" "removed a rule that was not ours"
grep -q 'git push --force' "$P/.claude/settings.json" && bad "charter rule removed" "still present" || ok "charter rule removed"
grep -q 'myown.txt' "$P/.gitignore" && ok "user gitignore line survives" || bad "user gitignore line survives" "removed"
grep -q '.craft/cache/' "$P/.gitignore" && bad "craft gitignore line removed" "still present" || ok "craft gitignore line removed"
[ -d "$P/.craft" ]              && bad ".craft removed" "still present"        || ok ".craft removed"
[ -e "$P/.claude/charter.json" ] && bad "charter.json removed" "still present" || ok "charter.json removed"
[ -e "$P/.claude/rules" ]        && bad "empty rules dir pruned" "still present" || ok "empty rules dir pruned"
[ -d "$P"/.forge-backup-* ]      && ok "backup copies kept"    || bad "backup copies kept" "no backup directory"
[ -f "$P"/.forge-backup-*/.craft/config.md ] && ok "backup holds the removed files" || bad "backup holds the removed files" "missing"

# A project Forge never touched: nothing to find, no crash, no writes.
Q=$(mktemp -d)
OU=$(cd "$Q" && CLAUDE_CONFIG_DIR="$G" sh "$U" --plan --keep-plugins 2>&1)
check "clean repo: nothing of ours" "nothing of ours here" "$OU"
[ -z "$(ls -A "$Q")" ] && ok "clean repo: writes nothing" || bad "clean repo: writes nothing" "files appeared"

rm -rf "$P" "$G" "$Q"

rm -rf "$T" "$C" "$N"
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
