#!/usr/bin/env bash
# Charter's script-level assertions. No model, no network, no cost.
#
#   ./tests/make-fixtures.sh && ./tests/run.sh

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
F="$HERE/fixtures"
PASS=0; FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
check(){ # check <label> <expected-substring> <actual>
  case "$3" in *"$2"*) ok "$1";; *) bad "$1 — expected '$2', got: $(printf '%s' "$3" | tr '\n' ' ' | cut -c1-120)";; esac
}

[ -d "$F/node-app" ] || { echo "fixtures missing — run ./tests/make-fixtures.sh"; exit 1; }

echo "survey"
S=$(bash "$ROOT/scripts/survey.sh" "$F/node-app")
check "node: size_class small"      "shape.size_class: small"        "$S"
check "node: prisma detected"       "danger.db_tooling: prisma"      "$S"
check "node: scripts found"         "cmd.npm_scripts:"               "$S"
check "node: .env is a secret"      "danger.secret_files: .env"      "$S"
check "node: .env.example is not"   "danger.secret_templates: .env.example" "$S"
L=$(printf '%s\n' "$S" | wc -l | tr -d ' ')
[ "$L" -le 80 ] && ok "node: output ${L} lines (<=80)" || bad "node: output ${L} lines (>80)"
case "$S" in *SECRET*|*password*|*"KEY="*) bad "node: survey leaked file contents";; *) ok "node: no contents leaked";; esac

S=$(bash "$ROOT/scripts/survey.sh" "$F/go-cli")
check "go: make targets"            "cmd.make_targets:"              "$S"
check "go: manifest is go.mod"      "stack.manifests: go.mod"        "$S"
check "go: no db surface"           ""                               "$S"
case "$S" in *danger.db_tooling*) bad "go: false-positive db tooling";; *) ok "go: no db tooling";; esac

S=$(bash "$ROOT/scripts/survey.sh" "$F/infra")
check "infra: danger paths"         "danger.paths:"                  "$S"
case "$S" in *terraform*) ok "infra: terraform seen";; *) bad "infra: terraform missed";; esac

S=$(bash "$ROOT/scripts/survey.sh" "$F/empty-repo")
check "empty: new-project mode"     "shape.size_class: new"          "$S"

echo "fingerprint"
S=$(bash "$ROOT/scripts/fingerprint.sh" "$F/node-app")
check "hash present"                "manifest_hash:"                 "$S"
check "no state yet"                "state: absent"                  "$S"
H1=$(printf '%s\n' "$S" | sed -n 's/^manifest_hash: //p')
printf '\n' >> "$F/node-app/package.json"
H2=$(bash "$ROOT/scripts/fingerprint.sh" "$F/node-app" | sed -n 's/^manifest_hash: //p')
[ "$H1" != "$H2" ] && ok "hash changes when a manifest changes" || bad "hash did not change"
git -C "$F/node-app" checkout -- package.json 2>/dev/null

echo "audit"
S=$(bash "$ROOT/scripts/audit.sh" "$F/node-app")
check "token total reported"        "total.always_loaded_est_tokens" "$S"
check "no deny rules yet"           "permissions.has_deny: no"       "$S"
L=$(printf '%s\n' "$S" | wc -l | tr -d ' ')
[ "$L" -le 60 ] && ok "audit output ${L} lines (<=60)" || bad "audit output ${L} lines (>60)"

echo "companions"
C() { CLAUDE_CONFIG_DIR="$F/$1" bash "$ROOT/scripts/companions.sh" "$F/${2:-go-cli}"; }

S=$(C cfg-none)
check "none: craft absent"          "companion.craft: absent"        "$S"
check "none: tars absent"           "companion.tars: absent"         "$S"
check "none: no style to offer"     "style.name: none"               "$S"

S=$(C cfg-plugin)
check "plugin: craft enabled"       "companion.craft: enabled"       "$S"
check "plugin: tars enabled"        "companion.tars: enabled"        "$S"
check "plugin: namespaced name"     "style.name: tars:TARS"          "$S"

# The pair that catches a constructed name. A file install is NOT "tars:TARS".
S=$(C cfg-file)
check "file: tars not a plugin"     "companion.tars: absent"         "$S"
check "file: bare style name"       "style.name: TARS"               "$S"
case "$S" in *"style.name: tars:TARS"*) bad "file: emitted plugin name for a file install";; *) ok "file: no plugin prefix";; esac

# Installed but switched off must not be offered — writing the name would
# produce a setting that resolves to nothing.
S=$(C cfg-disabled)
check "disabled: craft disabled"    "companion.craft: disabled"      "$S"
check "disabled: tars disabled"     "companion.tars: disabled"       "$S"
check "disabled: nothing to offer"  "style.name: none"               "$S"

S=$(C cfg-plugin wired)
check "wired: craft seen in fence"  "craft.referenced: yes"          "$S"
check "wired: local style read"     "style.set_local: tars:TARS"     "$S"

S=$(C cfg-plugin go-cli)
check "unwired: no fence"           "craft.referenced: no-fence"     "$S"

L=$(C cfg-plugin | wc -l | tr -d ' ')
[ "$L" -le 20 ] && ok "companions output ${L} lines (<=20)" || bad "companions output ${L} lines (>20)"

# Never writes. Nothing under the fixture may change.
B=$(find "$F/wired" -type f -newer "$F/wired/CLAUDE.md" 2>/dev/null | grep -v '/.git/' | wc -l | tr -d ' ')
C cfg-plugin wired > /dev/null
A=$(find "$F/wired" -type f -newer "$F/wired/CLAUDE.md" 2>/dev/null | grep -v '/.git/' | wc -l | tr -d ' ')
[ "$B" = "$A" ] && ok "companions writes nothing" || bad "companions touched the repo"

echo "rule lint"
LT=$(mktemp -d)
mkdir -p "$LT/.claude"
cat > "$LT/.claude/settings.json" <<'JSON'
{ "permissions": {
  "deny": ["Bash(git push --force *)", "Read(./**/*.pem)", "Read(./.env)"],
  "ask":  ["Bash(php artisan migrate*)", "Bash(sh -c *)", "Bash(bash -c *)", "Bash(eval *)"],
  "allow":["Bash(git status *)", "Bash(vendor/bin/pint --dirty*)"] } }
JSON
bash "$ROOT/scripts/lint-rules.sh" "$LT/.claude/settings.json" >/dev/null 2>&1 \
  && ok "clean rules pass" || bad "clean rules pass" "linter rejected a correct file"
# migrate* is a legitimate suffix wildcard, not the ls*/lsof form
bash "$ROOT/scripts/lint-rules.sh" "$LT/.claude/settings.json" 2>&1 | grep -q "FAIL gotcha 3" \
  && bad "no false positive on migrate*" "flagged a valid suffix wildcard" \
  || ok "no false positive on migrate*"
for CASE in 'Bash(ls*)|gotcha 3' 'Bash(* --version)|gotcha 17' 'Bash(git * main)|gotcha 4' \
            'Bash(docker exec *)|gotcha 6' 'Write(secrets/**)|gotcha 8' 'Bash(command:rm *)|gotcha 13'; do
  R="${CASE%%|*}"; G="${CASE##*|}"
  printf '{"permissions":{"allow":["%s"]}}' "$R" > "$LT/one.json"
  bash "$ROOT/scripts/lint-rules.sh" "$LT/one.json" 2>&1 | grep -q "FAIL $G" \
    && ok "catches $R ($G)" || bad "catches $R" "$G did not fire"
done

# A boundary stops an action, never a mechanic. These are the rules that would
# reintroduce prompts in auto mode, so the linter must fail the write on them.
for CASE in 'Bash(cd *)|auto mode: navigation' 'Bash(ls infra*)|auto mode: navigation' \
            'Bash(env *)|auto mode: navigation' 'Bash(python *)|auto mode: bare runner' \
            'Bash(npm *)|auto mode: bare runner' 'Bash(watch *)|gotcha 12: wrapper'; do
  R="${CASE%%|*}"; G="${CASE##*|}"
  printf '{"permissions":{"ask":["%s"]}}' "$R" > "$LT/one.json"
  bash "$ROOT/scripts/lint-rules.sh" "$LT/one.json" 2>&1 | grep -q "FAIL $G" \
    && ok "rejects $R ($G)" || bad "rejects $R" "$G did not fire"
done
# ...while the targeted forms of the same commands stay legal.
printf '{"permissions":{"deny":["Bash(python manage.py flush*)","Bash(npm run db:reset*)"],"ask":["Bash(bash -c *)"]}}' > "$LT/ok.json"
bash "$ROOT/scripts/lint-rules.sh" "$LT/ok.json" 2>&1 | grep -q "FAIL auto mode" \
  && bad "no false positive on named destructive commands" "auto-mode guard over-fired" \
  || ok "no false positive on named destructive commands"
# The shell re-entry block is an offer: its absence is not a failure.
printf '{"permissions":{"deny":["Read(./**/*.pem)"],"ask":["Bash(php artisan migrate*)"]}}' > "$LT/nore.json"
bash "$ROOT/scripts/lint-rules.sh" "$LT/nore.json" >/dev/null 2>&1 \
  && ok "shell re-entry absent is not a failure" \
  || bad "shell re-entry absent is not a failure" "linter still requires it"
echo '{"permissions":{"deny":["Read(./.env.*)"]}}' > "$LT/env.json"
bash "$ROOT/scripts/lint-rules.sh" "$LT/env.json" 2>&1 | grep -q "FAIL secrets: Read" \
  && ok "catches .env.* glob" || bad "catches .env.* glob" "did not fire"
bash "$ROOT/scripts/lint-rules.sh" "$LT/env.json" >/dev/null 2>&1 \
  && bad "exits non-zero on failure" "exited 0 with failures" || ok "exits non-zero on failure"
rm -rf "$LT"

echo "destructive scan"
DT=$(mktemp -d)
printf '{"scripts":{"test":"jest","db:reset":"x","build":"y"}}' > "$DT/package.json"
printf 'test:\n\tgo test\ndb-wipe:\n\tpsql\n' > "$DT/Makefile"
mkdir -p "$DT/app/Console/Commands"; touch "$DT/artisan"
printf "protected \$signature = 'cms:restore {--force}';\nprotected \$signature = 'cms:sync';\n" \
  > "$DT/app/Console/Commands/Cms.php"
S=$(bash "$ROOT/scripts/survey.sh" "$DT")
check "finds bespoke artisan restore"  "php artisan cms:restore"  "$S"
check "finds npm db:reset"             "npm run db:reset"         "$S"
check "finds make db-wipe"             "make db-wipe"             "$S"
case "$S" in *"cms:sync"*) bad "no false positive on cms:sync";; *) ok "no false positive on cms:sync";; esac
case "$S" in *"npm run build"*) bad "no false positive on build";; *) ok "no false positive on build";; esac
rm -rf "$DT"

echo "size gates"
# Raised from 2500 to 3000 when policy.md gained tier 0 (sandbox), six more
# matcher gotchas and the shell re-entry block. Raised again to 3200 when the
# setup questions moved into references/questions.md and were rewritten in plain
# language, which costs words: an option nobody understands is answered wrong,
# and the answer is written into enforced settings. These all live in
# references/, which load on demand rather than every session, so the
# always-loaded cost is unchanged. The gate that guards session cost is the
# per-SKILL.md word cap below; this one only stops the plugin sprawling.
N=$(find "$ROOT" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) \
      -not -path '*/tests/fixtures/*' -not -path '*/.git/*' -exec cat {} + | wc -l | tr -d ' ')
[ "$N" -le 3200 ] && ok "repo ${N} lines (<=3200)" || bad "repo ${N} lines (>3200)"

# What actually loads every session is the frontmatter `description` of each
# skill, not the body. A SKILL.md body loads when the skill is invoked, and
# init/ and status/ are `disable-model-invocation: true`, so they load only on
# an explicit slash command. Cap the descriptions, which are the real
# per-session cost, and let the bodies be as long as the task needs.
D=$(awk '/^description:/{print}' "$ROOT"/skills/*/SKILL.md | wc -c | tr -d ' ')
[ "$D" -le 1600 ] && ok "skill descriptions ${D} bytes (<=1600)" \
                  || bad "skill descriptions ${D} bytes (>1600)"
for f in "$ROOT"/skills/*/SKILL.md; do
  W=$(wc -w <"$f" | tr -d ' ')
  [ "$W" -le 2000 ] && ok "$(basename "$(dirname "$f")")/SKILL.md ${W} words (<=2000)" \
                     || bad "$(basename "$(dirname "$f")")/SKILL.md ${W} words (>2000)"
done

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
