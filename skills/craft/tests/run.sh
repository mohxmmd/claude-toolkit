#!/usr/bin/env bash
# CRAFT's script-level assertions. No model, no network, no cost.
#
#   ./tests/run.sh
#
# Every case here is a measurement failure that shipped once. The fixtures are
# built in temp dirs rather than committed, because each is three files and a
# git init, and a committed fixture drifts from the failure it describes.

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(dirname "$HERE")
M="$ROOT/scripts/measure.mjs"
PASS=0; FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s — %s\n' "$1" "$2"; }
jqp() { node -e "const d=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log($1)"; }

command -v node >/dev/null 2>&1 || { echo "node not found"; exit 1; }
node --check "$M" && ok "measure.mjs parses" || bad "measure.mjs parses" "syntax error"

mk() { T=$(mktemp -d); git -C "$T" init -q .; printf '%s' "$T"; }
commit() { git -C "$1" add -A >/dev/null 2>&1; git -C "$1" -c user.email=t@t -c user.name=t commit -qm x >/dev/null 2>&1; }

echo "generated output"
T=$(mk)
printf 'public/css/bundle-*.css\n' > "$T/.gitignore"
mkdir -p "$T/public/css" "$T/src"
{ for i in $(seq 1 300); do echo ".c$i{color:#77a507;border-radius:4px;padding:8px}"; done; } \
  > "$T/public/css/bundle-core.88f4182ca0.css"
cp "$T/public/css/bundle-core.88f4182ca0.css" "$T/public/css/bundle-core.css"
cp "$T/public/css/bundle-core.88f4182ca0.css" "$T/src/app.min.css"
printf '.header{color:#1a2b4c;padding:16px;border-radius:6px}\n' > "$T/src/site.css"
commit "$T"
J=$(node "$M" --root "$T" --json)
V=$(printf '%s' "$J" | jqp 'd.tokens.colors.top.map(t=>t.value).join(",")')
case "$V" in *77a507*) bad "content-hashed bundle excluded" "#77a507 still leads";; *) ok "content-hashed bundle excluded";; esac
case "$V" in *1a2b4c*) ok "hand-written value survives";; *) bad "hand-written value survives" "got: $V";; esac
N=$(printf '%s' "$J" | jqp 'd.excluded.generated + d.excluded.gitignored')
[ "$N" -ge 2 ] && ok "exclusions counted ($N)" || bad "exclusions counted" "got $N, expected >=2"

echo "derived stylesheet"
T=$(mk); mkdir -p "$T/theme/css" "$T/theme/api/css"
{ echo '.a{color:#123456;padding:8px}'
  for i in $(seq 1 40); do echo ".s$i{margin:${i}px;color:#abcdef;font-size:14px}"; done; } > "$T/theme/css/site.css"
cat "$T/theme/css/site.css" > "$T/theme/api/css/stylesheet.css"
echo '.x{color:#ff0000}' >> "$T/theme/api/css/stylesheet.css"
commit "$T"
J=$(node "$M" --root "$T" --json)
D=$(printf '%s' "$J" | jqp 'd.excluded.derived_files.join(",")')
case "$D" in *api/css/stylesheet.css*) ok "committed duplicate detected as derived";; *) bad "committed duplicate detected" "derived: '$D'";; esac
case "$D" in *theme/css/site.css*) bad "keeps the original" "dropped the smaller file";; *) ok "keeps the original";; esac

echo "file counting"
T=$(mk); mkdir -p "$T/src"
# #aaaaaa: 100 hits in ONE file. #bbbbbb: 1 hit in each of FIVE files.
{ for i in $(seq 1 100); do echo ".x$i{color:#aaaaaa}"; done; } > "$T/src/one.css"
for i in 1 2 3 4 5; do echo ".y$i{color:#bbbbbb}" > "$T/src/m$i.css"; done
commit "$T"
J=$(node "$M" --root "$T" --json)
LEAD=$(printf '%s' "$J" | jqp 'd.tokens.colors.top[0].value')
[ "$LEAD" = "#bbbbbb" ] && ok "ranks on files, not occurrences" \
  || bad "ranks on files, not occurrences" "leader is $LEAD (expected #bbbbbb)"
E=$(printf '%s' "$J" | jqp 'd.tokens.colors.top[0].files + "/" + d.tokens.colors.top[0].evidence')
[ "$E" = "5/5" ] && ok "reports files and evidence separately" || bad "files vs evidence" "got $E"

echo "dark mode signal"
T=$(mk); mkdir -p "$T/src"
# The exact shape that produced dark_mode: 1773. No real dark mode here.
printf ':root{--navy-dark:#1a2b4c;--teal-dark:#005}\n.bg-dark{background:#222}\n.btn-dark{color:#000}\n' > "$T/src/fp.css"
commit "$T"
V=$(node "$M" --root "$T" --json | jqp 'd.signals.dark_mode.value')
[ "$V" = "0" ] && ok "no false positive on --x-dark / .bg-dark" || bad "dark false positive" "value $V, expected 0"
printf '@media (prefers-color-scheme: dark){:root{--bg:#000}}\n[data-theme="dark"]{--bg:#111}\n' >> "$T/src/fp.css"
printf 'export const C=()=><div className="bg-white dark:bg-slate-900"/>\n' > "$T/src/c.jsx"
commit "$T"
J=$(node "$M" --root "$T" --json)
V=$(printf '%s' "$J" | jqp 'd.signals.dark_mode.value')
[ "$V" -ge 3 ] && ok "detects real dark mode ($V)" || bad "detects real dark mode" "value $V"
Mx=$(printf '%s' "$J" | jqp 'd.signals.dark_mode.matched.map(m=>m.mechanism).join(",")')
case "$Mx" in *prefers-color-scheme*) ok "names the mechanism";; *) bad "names the mechanism" "matched: $Mx";; esac

echo "css stack"
T=$(mk); mkdir -p "$T/views/pub" "$T/views/admin"
printf '{"dependencies":{"bootstrap":"4.6.0","tailwindcss":"3.4.0"}}' > "$T/package.json"
for i in 1 2 3 4 5 6 7 8; do
  printf '<div class="container-fluid"><div class="row justify-content-center"><div class="col-md-6"><button class="btn btn-primary">x</button></div></div></div>\n' > "$T/views/pub/p$i.html"
done
for i in 1 2; do printf '<div class="flex gap-4 px-6 md:px-8"><span class="hidden md:block">x</span></div>\n' > "$T/views/admin/a$i.html"; done
commit "$T"
J=$(node "$M" --root "$T" --json)
C=$(printf '%s' "$J" | jqp 'd.stack.css')
[ "$C" = "bootstrap" ] && ok "usage beats manifest (css=$C)" \
  || bad "usage beats manifest" "css=$C, expected bootstrap (tailwind is 2 of 10 files)"
S=$(printf '%s' "$J" | jqp 'd.stack.css_split ? "set" : "null"')
[ "$S" = "set" ] && ok "reports the split rather than one canonical" || bad "reports the split" "css_split is null"

echo "components"
T=$(mk); mkdir -p "$T/views"
for i in 1 2 3 4 5; do printf '<x-site.card/>\n<x-site.card/>\n<Button/>\n' > "$T/views/v$i.blade.php"; done
printf '<svg><Path d="M0"/><Circle r="1"/></svg>\n<Modal/>\n<Modal/>\n' > "$T/views/icon.jsx"
commit "$T"
J=$(node "$M" --root "$T" --json)
TOP=$(printf '%s' "$J" | jqp 'd.components.top[0].name')
[ "$TOP" = "site.card" ] && ok "ranks components by file count" || bad "component ranking" "top is $TOP"
NAMES=$(printf '%s' "$J" | jqp 'd.components.top.map(c=>c.name).join(",")')
case "$NAMES" in *Path*|*Circle*) bad "excludes svg tags" "got $NAMES";; *) ok "excludes svg tags";; esac

echo "dial confidence"
T=$(mk); mkdir -p "$T/src"; printf '.a{color:#111}\n' > "$T/src/a.css"; commit "$T"
W=$(node "$M" --root "$T" --json | jqp 'String(d.dials.write_to_config)')
[ "$W" = "false" ] && ok "thin corpus does not write dials" || bad "thin corpus dials" "write_to_config=$W"

echo "robustness"
T=$(mktemp -d); mkdir -p "$T/src"; printf '.a{color:#111}\n' > "$T/src/a.css"   # no git init
node "$M" --root "$T" --json >/dev/null 2>&1 && ok "runs outside a git repo" || bad "runs outside a git repo" "non-zero exit"
T=$(mktemp -d)
node "$M" --root "$T" --json >/dev/null 2>&1 && ok "runs on an empty directory" || bad "runs on an empty directory" "non-zero exit"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
