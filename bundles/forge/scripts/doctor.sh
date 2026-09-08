#!/usr/bin/env bash
# forge/doctor.sh — every context surface in this repo, checked against the others.
#
# The problem this exists for: a repo accumulates CLAUDE.md, MEMORY.md,
# .ai/rules/, .project-context/, .craft/ and a house skill, nothing reconciles
# them, and when two disagree nothing says which wins. Each tool is good at
# writing things down. None of them reads what the others wrote.
#
# Contract:
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines, <= 120 lines
#   never: writes anything. Reads instruction files only, never source, never .env.
#
# Token figures are estimates (bytes/4) and labelled as estimates everywhere.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

say() { printf '%s: %s\n' "$1" "$2"; }
est() { [ -f "$1" ] && echo $(( $(wc -c <"$1") / 4 )) || echo 0; }

echo "# forge doctor v1"

# ---------------------------------------------------------------- the surfaces
# Every place this repo keeps instructions for an AI agent. A surface is
# "always" when it loads into every session regardless of what is being done.
ALWAYS=""; CONDITIONAL=""; TOTAL=0
note_always() {
  [ -f "$1" ] || return 0
  T=$(est "$1"); L=$(wc -l <"$1" | tr -d ' ')
  TOTAL=$((TOTAL + T)); ALWAYS="$ALWAYS$1"$'\n'
  say "surface.always" "$1 (${L}L ~${T}tok)"
}
note_cond() {
  [ -e "$1" ] || return 0
  CONDITIONAL="$CONDITIONAL$1"$'\n'
  say "surface.conditional" "$1 ($2)"
}

for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md AGENTS.md .cursorrules \
         .windsurfrules .clinerules .github/copilot-instructions.md; do
  note_always "$f"
done

# Rule directories. A file with a `paths:` key loads only for matching files;
# one without it loads every session, which is the common and invisible mistake.
for d in .claude/rules .ai/rules .cursor/rules .project-context .craft; do
  [ -d "$d" ] || continue
  C=$(find "$d" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  say "surface.dir" "$d/ (${C} md)"
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    if head -12 "$f" | grep -qE '^(paths|globs|applyTo):'; then
      note_cond "$f" "scoped"
    else
      note_always "$f"
    fi
  done <<EOF
$(find "$d" -name '*.md' 2>/dev/null | sort)
EOF
done

# Auto-memory: the index loads every session, the topic files do not.
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SLUG=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SLUG=$(printf '%s' "$SLUG" | sed 's#/#-#g')
MEM="$CFG/projects/$SLUG/memory"
if [ -f "$MEM/MEMORY.md" ]; then
  T=$(est "$MEM/MEMORY.md"); TOTAL=$((TOTAL + T))
  ALWAYS="$ALWAYS$MEM/MEMORY.md"$'\n'
  say "surface.always" "MEMORY.md (~${T}tok, $(find "$MEM" -maxdepth 1 -name '*.md' ! -name MEMORY.md 2>/dev/null | wc -l | tr -d ' ') topic files)"
fi

NSURF=$(printf '%s' "$ALWAYS" | grep -c . || true)
say "count.always_loaded_surfaces" "$NSURF"
say "total.always_loaded_est_tokens" "$TOTAL"
[ "$TOTAL" -gt 4000 ] && say "warn.budget" "~${TOTAL} tokens load every session across ${NSURF} files; adherence drops as this grows"
[ "$NSURF" -gt 3 ] && say "warn.surfaces" "${NSURF} always-loaded surfaces; nothing states which wins when two disagree"

ALLSURF=$(printf '%s\n%s' "$ALWAYS" "$CONDITIONAL" | grep . || true)

# ---------------------------------------------------------------- dead refs
# Trivial and high-yield: every backticked path and command named in any
# surface, tested for existence. A doc that names a deleted file is worse than
# one that names nothing, because it is followed.
DEADN=0
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  {
    grep -oE '`[A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,6}`' "$f" | tr -d '`'
    grep -oE '`[A-Za-z0-9_./-]+/`' "$f" | tr -d '`'
    grep -oE '\]\([A-Za-z0-9_./-]+\)' "$f" | sed 's/^](//; s/)$//'
  } 2>/dev/null | sort -u | while read -r p; do
      case "$p" in
        http*|"") continue ;;
        */*/*|*/*.*) ;;
        *) continue ;;
      esac
      [ -e "$p" ] || [ -e "${p%/}" ] || printf 'dead.ref: %s -> %s\n' "$f" "$p"
    done
done <<EOF
$ALLSURF
EOF

# Commands named in backticks that are not on PATH and not a project script.
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  grep -oE '`(npm run|composer|make|just|php artisan|bin/rails) [a-z0-9:_-]+`' "$f" 2>/dev/null \
    | tr -d '`' | sort -u | while read -r c; do
        RUNNER=${c%% *}; TASK=${c##* }
        case "$RUNNER" in
          npm)  [ -f package.json ] && grep -q "\"$TASK\"" package.json || printf 'dead.cmd: %s -> %s\n' "$f" "$c" ;;
          make) [ -f Makefile ] && grep -qE "^$TASK:" Makefile || printf 'dead.cmd: %s -> %s\n' "$f" "$c" ;;
        esac
      done
done <<EOF
$ALLSURF
EOF

# ---------------------------------------------------------------- duplicates
# The same assertion written into two surfaces. Not automatically wrong, but
# it is where contradictions start, and it is paid for twice every session.
printf '%s\n' "$ALLSURF" | while read -r f; do
  [ -n "$f" ] && [ -f "$f" ] && sed "s|^|$f\t|" "$f"
done 2>/dev/null \
  | awk -F'\t' '{ line=$2
      gsub(/^[ \t#>*-]+/,"",line); gsub(/[ \t]+$/,"",line)
      gsub(/[`*_]/,"",line); line=tolower(line)
      if (length(line) < 25 || length(line) > 160) next
      if (seen[line] != "" && seen[line] != $1) { print "dup.assertion: " seen[line] " == " $1 " :: " substr($2,1,70); c++ }
      else seen[line]=$1
      if (c > 8) exit }' 2>/dev/null

# ---------------------------------------------------------------- contradictions
# A narrow rule set, because a general one produces noise. These four are the
# policies that actually get written into two places and then diverge.
topic_hits() { # topic_hits <regex>
  printf '%s\n' "$ALLSURF" | while read -r f; do
    [ -n "$f" ] && [ -f "$f" ] || continue
    grep -qiE "$1" "$f" 2>/dev/null && printf '%s\n' "$f"
  done
}
for T in "commit:(never|do not|don't|always) (commit|auto-commit)" \
         "push:(never|do not|don't) (push|force.push)" \
         "database:(never|do not|don't).{0,20}(migration|database|db )" \
         "tests:(always|never|must).{0,20}(run the |the )?(test|suite)"; do
  NAME=${T%%:*}; RE=${T#*:}
  H=$(topic_hits "$RE" | sort -u)
  N=$(printf '%s' "$H" | grep -c . || true)
  [ "$N" -ge 2 ] && say "contradiction.check" "$NAME policy stated in $N surfaces: $(printf '%s' "$H" | tr '\n' ' ')"
done

# ---------------------------------------------------------------- tier violations
# Enforcement vocabulary in a surface that enforces nothing. This is the check
# that caught Forge's own bug: `refuse` written into a file a model reads.
RULEFILE=""
for s in .claude/settings.json .claude/settings.local.json; do [ -f "$s" ] && RULEFILE="$RULEFILE $s"; done
say "permissions.files" "${RULEFILE:-none}"
NRULES=0
for s in $RULEFILE; do
  N=$(grep -cE '"(Bash|Read|Edit|WebFetch|Agent)\(' "$s" 2>/dev/null); NRULES=$((NRULES + ${N:-0}))
done
say "permissions.rule_count" "$NRULES"

printf '%s\n' "$ALLSURF" | while read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  grep -inE '\b(refuse to|will refuse|hard gate|is blocked|cannot be (edited|changed|modified)|will not be able to|is enforced|prevented from)\b' "$f" 2>/dev/null \
    | head -3 | while IFS=: read -r ln rest; do
        printf 'tier.claim: %s:%s :: %s\n' "$f" "$ln" "$(printf '%s' "$rest" | sed 's/^[ \t]*//' | cut -c1-80)"
      done
done
[ "$NRULES" = 0 ] && say "tier.verdict" "no permission rules exist, so every enforcement claim above is a convention" \
                  || say "tier.verdict" "$NRULES rules exist; check each claim above names a path or command those rules cover"

# ---------------------------------------------------------------- precedence
PREC=$(printf '%s\n' "$ALLSURF" | while read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  grep -qiE '(takes precedence|wins over|authoritative|source of truth|overrides)' "$f" 2>/dev/null && printf '%s\n' "$f"
done | head -3 | tr '\n' ' ')
say "precedence.stated_in" "${PREC:-nowhere}"

echo "# end"
