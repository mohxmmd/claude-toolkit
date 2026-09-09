#!/bin/sh
# Claude Forge updater.
#
#   ./update.sh            refresh the marketplace, show what changed, update
#   ./update.sh --check    report installed vs available, change nothing
#   ./update.sh --weekly   check once a week, in the background, from now on
#
# Read this before turning on --weekly:
#
#   Claude Code has its own plugin auto-update, and it runs at EVERY session
#   start, which is more often than weekly. If you want to stay current, that
#   is the better mechanism and it is one command:
#
#       ./setup.sh --auto-update-only
#
#   --weekly exists for the other case: auto-update off on purpose, but not
#   wanting to fall six versions behind without noticing. Running both is
#   pointless and makes two things race for the same plugin directory, so
#   --weekly says so and asks before installing over it.

set -eu

MARKET="${FORGE_MARKET:-claude-forge}"
CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CFG_DIR/settings.json"
STATE_DIR="$CFG_DIR/forge"
HOOK="$STATE_DIR/weekly-update.sh"
STAMP="$STATE_DIR/last-update-check"
LOG="$STATE_DIR/update.log"
INSTALLED_DB="$CFG_DIR/plugins/installed_plugins.json"
MARKET_JSON="$CFG_DIR/plugins/marketplaces/$MARKET/.claude-plugin/marketplace.json"

MODE=update             # update | check | weekly | unweekly
ASSUME_YES=0

usage() {
    cat <<'USAGE'
Update the Claude Forge plugins: forge, Charter, Craft and TARS.

Usage:
  ./update.sh [--check] [--weekly] [--no-weekly] [--yes] [--help]

Options:
  --check       Report installed vs available versions. Changes nothing.
  --weekly      Check for updates once a week, in the background
  --no-weekly   Stop the weekly check
  --yes, -y     Do not ask for confirmation
  --help        Show this message

Before --weekly, know this:

  Claude Code's own plugin auto-update runs at EVERY session start, which is
  more often than weekly and needs no script. If you want to stay current:

      ./setup.sh --auto-update-only

  --weekly is for the other case: auto-update deliberately off, but you would
  still rather not fall six versions behind. Running both is redundant.

What --weekly installs:

  ~/.claude/forge/weekly-update.sh    a small script, nothing else calls it
  a SessionStart hook in settings.json, marked async so it never delays a
  session, which runs that script

  The script exits in milliseconds on six days out of seven. On the seventh it
  refreshes the marketplace, updates the four plugins, and appends the result
  to ~/.claude/forge/update.log. Remove it with --no-weekly, or by uninstalling.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --check)      MODE=check; shift ;;
        --weekly)     MODE=weekly; shift ;;
        --no-weekly)  MODE=unweekly; shift ;;
        --yes|-y)     ASSUME_YES=1; shift ;;
        --help|-h)    usage; exit 0 ;;
        *) echo "error: unknown option '$1'. Try --help." >&2; exit 1 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }
JSON_BIN=""
if have python3; then JSON_BIN=python3
elif have node;  then JSON_BIN=node
fi

confirm() {
    [ "$ASSUME_YES" = 1 ] && return 0
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        printf '%s [y/N] ' "$1" > /dev/tty
        read -r ANS < /dev/tty || ANS=""
        case "$ANS" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
    fi
    echo "error: no terminal to confirm on. Re-run with --yes." >&2
    return 1
}

# ---------------------------------------------------------------- versions
# Installed versions come from the plugin database, available ones from the
# marketplace cache. Both are plain JSON on disk, so this needs no network and
# no parsing of human-readable CLI output.
versions() {
    [ -n "$JSON_BIN" ] || return 1
    [ -f "$INSTALLED_DB" ] || return 1
    [ -f "$MARKET_JSON" ] || return 1
    case "$JSON_BIN" in
        python3) python3 - "$INSTALLED_DB" "$MARKET_JSON" "$MARKET" <<'PY'
import json, sys
db_path, mk_path, market = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    db = json.load(open(db_path))
    mk = json.load(open(mk_path))
except Exception:
    sys.exit(1)
available = {p.get("name"): p.get("version", "?") for p in mk.get("plugins", [])}
for key, entries in sorted((db.get("plugins") or {}).items()):
    if not key.endswith("@" + market) or not entries:
        continue
    name = key.split("@", 1)[0]
    print("%s\t%s\t%s" % (name, entries[0].get("version", "?"),
                          available.get(name, "?")))
PY
        ;;
        node) node -e '
          const fs = require("fs");
          const [dbp, mkp, market] = process.argv.slice(1);
          let db, mk;
          try { db = JSON.parse(fs.readFileSync(dbp, "utf8"));
                mk = JSON.parse(fs.readFileSync(mkp, "utf8")); }
          catch (e) { process.exit(1); }
          const avail = {};
          for (const p of (mk.plugins || [])) avail[p.name] = p.version || "?";
          for (const key of Object.keys(db.plugins || {}).sort()) {
            if (!key.endsWith("@" + market)) continue;
            const rows = db.plugins[key];
            if (!rows || !rows.length) continue;
            const name = key.split("@")[0];
            console.log([name, rows[0].version || "?", avail[name] || "?"].join("\t"));
          }
        ' "$INSTALLED_DB" "$MARKET_JSON" "$MARKET"
        ;;
    esac
}

report() {
    TAB=$(printf '\t')
    OUT=$(versions 2>/dev/null || true)
    if [ -z "$OUT" ]; then
        echo "  (cannot read versions here; 'claude plugin list' shows what is installed)"
        return 0
    fi
    BEHIND=0
    printf '%s\n' "$OUT" | while IFS="$TAB" read -r name have want; do
        if [ "$have" = "$want" ]; then
            printf '  %-10s %-8s up to date\n' "$name" "$have"
        else
            printf '  %-10s %-8s -> %s\n' "$name" "$have" "$want"
        fi
    done
    printf '%s\n' "$OUT" | awk -F"$TAB" '$2 != $3 {n++} END {exit !n}' && BEHIND=1
    return $BEHIND
}

require_claude() {
    have claude || {
        echo "error: 'claude' is not on your PATH." >&2
        echo "       Install Claude Code first: https://claude.com/claude-code" >&2
        exit 1
    }
}

autoupdate_on() {
    [ -f "$SETTINGS" ] || return 1
    grep -A20 "\"$MARKET\"" "$SETTINGS" 2>/dev/null \
        | grep -q '"autoUpdate"[[:space:]]*:[[:space:]]*true'
}

# ------------------------------------------------------------------- check
if [ "$MODE" = check ]; then
    require_claude
    echo
    echo "Refreshing $MARKET ..."
    claude plugin marketplace update "$MARKET" >/dev/null 2>&1 \
        || echo "  warning: could not refresh the marketplace; versions may be stale"
    echo
    echo "Versions"
    if report; then
        echo
        echo "Everything is current."
    else
        echo
        echo "Run ./update.sh to install the newer versions."
    fi
    if autoupdate_on; then
        echo "Auto-update is on: this happens by itself at every session start."
    fi
    echo
    exit 0
fi

# ------------------------------------------------------------------ weekly
write_hook() {
    mkdir -p "$STATE_DIR"
    cat > "$HOOK" <<'HOOK_EOF'
#!/bin/sh
# Forge weekly update check. Installed by update.sh --weekly, removed by
# --no-weekly or by uninstalling. Runs from a SessionStart hook, marked async,
# so it never delays the session it starts in.
#
# Six days out of seven this exits in milliseconds without doing anything.

set -eu
MARKET="${FORGE_MARKET:-claude-forge}"
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DIR="$CFG/forge"
STAMP="$DIR/last-update-check"
LOG="$DIR/update.log"
LOCK="$DIR/update.lock"
DAYS=7

command -v claude >/dev/null 2>&1 || exit 0
mkdir -p "$DIR"

# The gate. -mtime is whole days, which is the right granularity here.
if [ -f "$STAMP" ] && [ -z "$(find "$STAMP" -mtime "+$((DAYS - 1))" 2>/dev/null)" ]; then
    exit 0
fi

# One check at a time. A stale lock older than a day is assumed dead.
if ! mkdir "$LOCK" 2>/dev/null; then
    [ -n "$(find "$LOCK" -maxdepth 0 -mtime +1 2>/dev/null)" ] || exit 0
    rmdir "$LOCK" 2>/dev/null || exit 0
    mkdir "$LOCK" 2>/dev/null || exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT INT TERM

# Stamped before the work, not after: a failing check must not retry on every
# session start for the rest of the week.
: > "$STAMP"

{
    echo "--- $(date '+%Y-%m-%d %H:%M:%S')"
    claude plugin marketplace update "$MARKET" 2>&1 || echo "marketplace update failed"
    for p in forge charter craft tars; do
        claude plugin list 2>/dev/null | grep -q "$p@$MARKET" || continue
        claude plugin update "$p@$MARKET" 2>&1 || echo "update failed: $p"
    done
} >> "$LOG" 2>&1

# Keep the log small enough that nobody has to think about it.
if [ "$(wc -l < "$LOG" 2>/dev/null || echo 0)" -gt 500 ]; then
    tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi
exit 0
HOOK_EOF
    chmod +x "$HOOK"
}

edit_hook_setting() {
    # $1 = add | remove
    ACTION="$1"
    [ -n "$JSON_BIN" ] || {
        echo "error: neither python3 nor node is available, so settings cannot be" >&2
        echo "       edited safely. Add the SessionStart hook by hand:" >&2
        echo "         \"hooks\": { \"SessionStart\": [ { \"hooks\": [" >&2
        echo "           { \"type\": \"command\", \"command\": \"$HOOK\", \"async\": true }" >&2
        echo "         ] } ] }" >&2
        exit 1
    }
    mkdir -p "$CFG_DIR"
    [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
    case "$JSON_BIN" in
        python3) python3 - "$SETTINGS" "$HOOK" "$ACTION" <<'PY'
import collections, json, shutil, sys, time

path, hook, action = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(path) as fh:
        data = json.load(fh, object_pairs_hook=collections.OrderedDict)
except Exception as exc:
    print("error: %s is not valid JSON (%s)" % (path, exc))
    sys.exit(1)

hooks = data.setdefault("hooks", collections.OrderedDict())
groups = hooks.setdefault("SessionStart", [])

def is_ours(group):
    for h in group.get("hooks", []):
        if isinstance(h, dict) and h.get("command") == hook:
            return True
    return False

before = json.dumps(data, sort_keys=True)

if action == "add":
    if not any(is_ours(g) for g in groups if isinstance(g, dict)):
        groups.append(collections.OrderedDict([
            ("hooks", [collections.OrderedDict([
                ("type", "command"),
                ("command", hook),
                ("async", True),
                ("timeout", 300),
            ])]),
        ]))
else:
    # Drop only our hook. Another SessionStart hook in the same group, or a
    # group of someone else's, is left exactly as it was.
    kept = []
    for g in groups:
        if not isinstance(g, dict):
            kept.append(g)
            continue
        inner = [h for h in g.get("hooks", [])
                 if not (isinstance(h, dict) and h.get("command") == hook)]
        if inner:
            g["hooks"] = inner
            kept.append(g)
        elif not g.get("hooks"):
            kept.append(g)
    groups[:] = kept
    if not groups:
        del hooks["SessionStart"]
    if not hooks:
        del data["hooks"]

if json.dumps(data, sort_keys=True) == before:
    print("unchanged")
    sys.exit(0)

backup = path + ".backup-" + time.strftime("%Y%m%d-%H%M%S")
shutil.copyfile(path, backup)
with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
print("edited %s (backup %s)" % (path, backup))
PY
        ;;
        node) node -e '
          const fs = require("fs");
          const [path, hook, action] = process.argv.slice(1);
          let data;
          try { data = JSON.parse(fs.readFileSync(path, "utf8")); }
          catch (e) { console.log("error: " + path + " is not valid JSON (" + e.message + ")"); process.exit(1); }
          data.hooks = data.hooks || {};
          let groups = data.hooks.SessionStart || (data.hooks.SessionStart = []);
          const ours = g => (g && g.hooks || []).some(h => h && h.command === hook);
          const before = JSON.stringify(data);
          if (action === "add") {
            if (!groups.some(ours)) {
              groups.push({ hooks: [{ type: "command", command: hook, async: true, timeout: 300 }] });
            }
          } else {
            const kept = [];
            for (const g of groups) {
              if (!g || typeof g !== "object") { kept.push(g); continue; }
              const inner = (g.hooks || []).filter(h => !(h && h.command === hook));
              if (inner.length) { g.hooks = inner; kept.push(g); }
              else if (!g.hooks) { kept.push(g); }
            }
            data.hooks.SessionStart = kept;
            if (!kept.length) delete data.hooks.SessionStart;
            if (!Object.keys(data.hooks).length) delete data.hooks;
          }
          if (JSON.stringify(data) === before) { console.log("unchanged"); process.exit(0); }
          const pad = n => String(n).padStart(2, "0");
          const d = new Date();
          const stamp = "" + d.getFullYear() + pad(d.getMonth()+1) + pad(d.getDate())
                      + "-" + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds());
          const backup = path + ".backup-" + stamp;
          fs.copyFileSync(path, backup);
          fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
          console.log("edited " + path + " (backup " + backup + ")");
        ' "$SETTINGS" "$HOOK" "$ACTION"
        ;;
    esac
}

if [ "$MODE" = weekly ]; then
    if autoupdate_on; then
        cat <<EOF

Auto-update is already on for $MARKET.

It refreshes the marketplace and updates these plugins at EVERY session start,
which is more often than weekly and needs no hook. Adding the weekly check on
top of it gains nothing and gives two mechanisms the same job.

EOF
        confirm "Install the weekly check anyway?" || { echo "Nothing was changed."; exit 0; }
        echo
    fi
    write_hook
    echo "Weekly check:"
    echo "  wrote $HOOK"
    edit_hook_setting add | sed 's/^/  /'
    cat <<EOF

  It runs at session start, marked async so it never delays a session, and
  does nothing at all until seven days have passed. Results are appended to
  $LOG

Restart Claude Code for the hook to take effect.
EOF
    exit 0
fi

if [ "$MODE" = unweekly ]; then
    echo "Weekly check:"
    edit_hook_setting remove | sed 's/^/  /'
    for f in "$HOOK" "$STAMP"; do
        [ -e "$f" ] && { rm -f "$f"; echo "  removed $f"; }
    done
    [ -f "$LOG" ] && echo "  kept $LOG"
    rmdir "$STATE_DIR" 2>/dev/null && echo "  removed $STATE_DIR"
    echo
    echo "Restart Claude Code for the change to take effect."
    exit 0
fi

# ------------------------------------------------------------------ update
require_claude

echo
echo "Refreshing $MARKET ..."
claude plugin marketplace update "$MARKET" >/dev/null 2>&1 || {
    echo "error: could not refresh the marketplace." >&2
    echo "       Is it installed? claude plugin marketplace list" >&2
    exit 1
}

echo
echo "Before"
report && CURRENT=1 || CURRENT=0

if [ "$CURRENT" = 1 ]; then
    echo
    echo "Everything is already current. Nothing to do."
    exit 0
fi

echo
echo "Updating"
TAB=$(printf '\t')
LIST=$(versions 2>/dev/null | awk -F"$TAB" '$2 != $3 {print $1}' || true)
[ -n "$LIST" ] || LIST="forge charter craft tars"
for p in $LIST; do
    if claude plugin update "$p@$MARKET" >/dev/null 2>&1; then
        echo "  updated $p"
    else
        echo "  failed  $p  (run: claude plugin update $p@$MARKET)"
    fi
done

echo
echo "After"
report || true

cat <<'EOF'

Restart Claude Code. Plugins load at session start, so the new versions apply
to your next session, not this one.
EOF
