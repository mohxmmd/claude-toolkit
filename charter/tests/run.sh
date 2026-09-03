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

echo "size gates"
N=$(find "$ROOT" -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' \) \
      -not -path '*/tests/fixtures/*' -not -path '*/.git/*' -exec cat {} + | wc -l | tr -d ' ')
[ "$N" -le 2500 ] && ok "repo ${N} lines (<=2500)" || bad "repo ${N} lines (>2500)"
for f in "$ROOT"/skills/*/SKILL.md; do
  W=$(wc -w <"$f" | tr -d ' ')
  [ "$W" -le 2000 ] && ok "$(basename "$(dirname "$f")")/SKILL.md ${W} words (<=2000)" \
                     || bad "$(basename "$(dirname "$f")")/SKILL.md ${W} words (>2000)"
done

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
