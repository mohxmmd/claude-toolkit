#!/usr/bin/env bash
# charter/audit.sh — what this repo loads into EVERY session, and what is wrong with it.
#
# Contract:
#   in   : $1 = repo root (default: $PWD)
#   out  : "key: value" lines, <= 60 lines
#   never: writes anything. Reads instruction files only (never source, never .env).
#
# Token figures are estimates (bytes/4). They are labelled as estimates everywhere.

set -u
ROOT="${1:-$PWD}"
cd "$ROOT" 2>/dev/null || { echo "error: cannot enter $ROOT"; exit 1; }

say() { printf '%s: %s\n' "$1" "$2"; }
est() { [ -f "$1" ] && echo $(( $(wc -c <"$1") / 4 )) || echo 0; }

echo "# charter audit v1"

TOTAL=0
ALWAYS=""

# ---------------------------------------------------------- always-loaded files
for f in CLAUDE.md .claude/CLAUDE.md CLAUDE.local.md; do
  [ -f "$f" ] || continue
  T=$(est "$f"); L=$(wc -l <"$f" | tr -d ' ')
  TOTAL=$((TOTAL + T))
  ALWAYS="$ALWAYS$f"$'\n'
  say "loaded.$f" "${L}L ~${T}tok"
  [ "$L" -gt 200 ] && say "warn.oversize" "$f is ${L} lines; adherence drops past ~200"
done

# rules WITHOUT a paths: front-matter key are loaded every session too
if [ -d .claude/rules ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    T=$(est "$f"); L=$(wc -l <"$f" | tr -d ' ')
    if head -12 "$f" | grep -q '^paths:'; then
      say "conditional.$f" "${L}L ~${T}tok (loads only on matching files)"
    else
      TOTAL=$((TOTAL + T))
      ALWAYS="$ALWAYS$f"$'\n'
      say "loaded.$f" "${L}L ~${T}tok"
      say "hint.scopeable" "$f has no paths: key — it loads every session"
    fi
  done <<EOF
$(find .claude/rules -name '*.md' 2>/dev/null | sort)
EOF
fi

# ---------------------------------------------------------- auto memory
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SLUG=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SLUG=$(printf '%s' "$SLUG" | sed 's#/#-#g')
MEM="$CFG/projects/$SLUG/memory"
if [ -d "$MEM" ]; then
  IDX="$MEM/MEMORY.md"
  T=$(est "$IDX"); L=$([ -f "$IDX" ] && wc -l <"$IDX" | tr -d ' ' || echo 0)
  TOTAL=$((TOTAL + T))
  say "loaded.MEMORY.md" "${L}L ~${T}tok"
  say "memory.dir" "$MEM"
  say "memory.topic_files" "$(find "$MEM" -maxdepth 1 -name '*.md' ! -name MEMORY.md 2>/dev/null | wc -l | tr -d ' ')"
  [ "$L" -gt 200 ] && say "warn.memory_index" "MEMORY.md is ${L} lines; only the first 200 load"
  # topic files by age — promotion candidates are the old, stable ones
  find "$MEM" -maxdepth 1 -name '*.md' ! -name MEMORY.md -printf '%T@ %p\n' 2>/dev/null \
    | sort -n | head -20 | while read -r ts p; do
        d=$(date -d "@${ts%%.*}" +%Y-%m-%d 2>/dev/null || echo unknown)
        printf 'memory.file: %s (%sL, %s)\n' "$(basename "$p")" "$(wc -l <"$p" | tr -d ' ')" "$d"
      done
else
  say "memory.dir" "none"
fi

say "total.always_loaded_est_tokens" "$TOTAL"

# ---------------------------------------------------------- dead references
# Paths named in backticks or markdown links inside always-loaded files.
DEAD=0
printf '%s' "$ALWAYS" | while read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  {
    grep -oE '`[A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,6}`' "$f" | tr -d '`'
    grep -oE '`[A-Za-z0-9_./-]+/`' "$f" | tr -d '`'
    grep -oE '\]\([A-Za-z0-9_./-]+\)' "$f" | sed 's/^](//; s/)$//'
  } 2>/dev/null | sort -u | while read -r p; do
      case "$p" in
        http*|"") continue ;;
        */*/*|*/*.*) ;;          # multi-segment path, or a file with an extension
        *) continue ;;           # bare `name/` is a label, not a repo-rooted path
      esac
      [ -e "$p" ] || [ -e "${p%/}" ] || printf 'dead.ref: %s -> %s\n' "$f" "$p"
    done
done

# ---------------------------------------------------------- derivable content
# Content /doctor's trim pass removes: directory trees, dependency lists.
for f in CLAUDE.md .claude/CLAUDE.md; do
  [ -f "$f" ] || continue
  TREE=$(grep -cE '^[[:space:]]*[│├└|`+-]{1,4}[[:space:]]*[A-Za-z0-9_.-]+/' "$f" 2>/dev/null); TREE=${TREE:-0}
  [ "$TREE" -gt 4 ] && say "hint.derivable" "$f contains a ~${TREE}-line directory tree the model can derive"
done

# ---------------------------------------------------------- enforcement gap
say "settings.project" "$([ -f .claude/settings.json ] && echo yes || echo no)"
say "settings.local" "$([ -f .claude/settings.local.json ] && echo yes || echo no)"
RULES=0
for s in .claude/settings.json .claude/settings.local.json; do
  [ -f "$s" ] || continue
  N=$(grep -cE '"(Bash|Read|Edit|WebFetch|Agent)\(' "$s" 2>/dev/null); N=${N:-0}
  RULES=$((RULES + N))
done
say "permissions.rule_count" "$RULES"
DENY=0
for s in .claude/settings.json .claude/settings.local.json; do
  [ -f "$s" ] && grep -q '"deny"' "$s" 2>/dev/null && DENY=1
done
say "permissions.has_deny" "$([ "$DENY" = 1 ] && echo yes || echo no)"

echo "# end"
