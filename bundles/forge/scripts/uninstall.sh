#!/bin/sh
# Claude Forge uninstaller.
#
# Removes everything Forge put on this machine and, when run from a project,
# everything Charter and Craft wrote into it.
#
# Two sources of truth, in this order:
#
#   1. .forge/manifest.tsv — the receipt. Charter and Craft append a line for
#      every artifact they create and every file they edit, so removal is
#      exact rather than inferred. Format is documented in docs/UNINSTALL.md.
#
#   2. Known markers and paths — the fallback for projects set up before the
#      receipt existed. It finds the fence and the state files; it cannot tell
#      which permission rules were Charter's and which were yours, so it
#      reports those instead of guessing.
#
# Nothing is deleted without a copy. Project artifacts are moved into
# .forge-backup-<timestamp>/ and settings files are backed up in place.

set -eu

MARKET="${FORGE_MARKET:-claude-forge}"
CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CFG_DIR/settings.json"
STYLE_FILE="$CFG_DIR/output-styles/TARS.md"
PROJECT="$PWD"
MANIFEST=".forge/manifest.tsv"
TAB=$(printf '\t')

MODE=ask                # ask | yes | plan
KEEP_SETTINGS=0
KEEP_STYLE=0
KEEP_PLUGINS=0
KEEP_PROJECT=0

usage() {
    cat <<'USAGE'
Uninstall the Claude Forge: forge, Charter, Craft and TARS.

Usage:
  ./uninstall.sh [--plan] [--yes] [--keep-project] [--keep-settings]
                 [--keep-style] [--keep-plugins] [--help]

Options:
  --plan, --dry-run   Show what would be removed and change nothing
  --yes, -y           Do not ask for confirmation (required when not a terminal)
  --keep-project      Leave this repository's files alone
  --keep-settings     Leave the user settings.json alone
  --keep-style        Leave ~/.claude/output-styles/TARS.md in place
  --keep-plugins      Leave the plugins and marketplace installed
  --help              Show this message

Machine:
  plugins        forge, charter, craft and tars
  marketplace    the claude-forge marketplace entry
  settings       extraKnownMarketplaces.claude-forge
                 env.FORCE_AUTOUPDATE_PLUGINS
                 enabledPlugins entries ending in @claude-forge
                 outputStyle, only when it is set to TARS
  style file     ~/.claude/output-styles/TARS.md, if install.sh put it there

This repository (from .forge/manifest.tsv, or from known markers):
  files          .forge/, .craft/, .claude/charter.json, Charter's rules files
  CLAUDE.md      the block between the charter:start and charter:end markers
  settings       the permission rules Charter added, and outputStyle
  .gitignore     the lines Charter and Craft added

Everything removed from the project is copied into .forge-backup-<timestamp>/
first. Other repositories are not touched: run this from each of them.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --plan|--dry-run) MODE=plan; shift ;;
        --yes|-y)         MODE=yes; shift ;;
        --keep-project)   KEEP_PROJECT=1; shift ;;
        --keep-settings)  KEEP_SETTINGS=1; shift ;;
        --keep-style)     KEEP_STYLE=1; shift ;;
        --keep-plugins)   KEEP_PLUGINS=1; shift ;;
        --help|-h)        usage; exit 0 ;;
        *) echo "error: unknown option '$1'. Try --help." >&2; exit 1 ;;
    esac
done

have() { command -v "$1" >/dev/null 2>&1; }
HAVE_CLAUDE=0
have claude && HAVE_CLAUDE=1

JSON_BIN=""
if have python3; then JSON_BIN=python3
elif have node;  then JSON_BIN=node
fi

# ------------------------------------------------------------------- survey
# Read-only. Nothing in this section changes anything.

INSTALLED=""
MARKET_PRESENT=no
if [ "$HAVE_CLAUDE" = 1 ] && [ "$KEEP_PLUGINS" = 0 ]; then
    INSTALLED=$(claude plugin list 2>/dev/null \
        | grep -o "[A-Za-z0-9_.-]*@$MARKET" | sort -u | tr '\n' ' ' || true)
    # The bundle goes first: charter, craft and tars are its dependencies, and
    # removing a dependency out from under it is the one order that can fail.
    ORDERED=""
    for p in $INSTALLED; do [ "$p" = "forge@$MARKET" ] && ORDERED="$p"; done
    for p in $INSTALLED; do [ "$p" = "forge@$MARKET" ] || ORDERED="$ORDERED $p"; done
    set -- $ORDERED
    INSTALLED="$*"
    claude plugin marketplace list 2>/dev/null | grep -q "$MARKET" && MARKET_PRESENT=yes
fi

# outputStyle is read the way forge/state.sh reads it, so the two agree.
style_of() {
    [ -f "$1" ] || return 0
    sed -n 's/.*"outputStyle"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}
is_tars() { [ "$1" = "TARS" ] || [ "$1" = "tars:TARS" ]; }

USER_HITS=""
if [ -f "$SETTINGS" ]; then
    grep -q "\"$MARKET\"" "$SETTINGS" && USER_HITS="$USER_HITS extraKnownMarketplaces.$MARKET"
    grep -q 'FORCE_AUTOUPDATE_PLUGINS' "$SETTINGS" && USER_HITS="$USER_HITS env.FORCE_AUTOUPDATE_PLUGINS"
    grep -q "@$MARKET" "$SETTINGS" && USER_HITS="$USER_HITS enabledPlugins"
    is_tars "$(style_of "$SETTINGS")" && USER_HITS="$USER_HITS outputStyle"
fi

# ---------------------------------------------------------- project survey
# Every project fact is collected into these lists, from the receipt when there
# is one and from markers when there is not. The removal pass reads only these,
# so both paths remove the same things the same way.

P_PATHS=""          # newline separated
P_FENCES=""         # file<TAB>start<TAB>end
P_SETTINGS=""       # file<TAB>bucket<TAB>value   (bucket=key means delete key)
P_IGNORES=""        # file<TAB>line
P_UNKNOWN=""        # things found but not attributable, reported only
HAVE_MANIFEST=no

add_line() {
    if [ -z "$1" ]; then printf '%s\n' "$2"; else printf '%s\n%s\n' "$1" "$2"; fi
}

if [ "$KEEP_PROJECT" = 0 ]; then
    if [ -f "$MANIFEST" ]; then
        HAVE_MANIFEST=yes
        while IFS="$TAB" read -r comp kind a b c; do
            case "${comp:-}" in ""|\#*) continue ;; esac
            [ -n "${kind:-}" ] || continue
            case "$kind" in
                path)      [ -e "$a" ] && P_PATHS=$(add_line "$P_PATHS" "$a") ;;
                fence)     [ -f "$a" ] && grep -qF "$b" "$a" 2>/dev/null \
                               && P_FENCES=$(add_line "$P_FENCES" "$a$TAB$b$TAB$c") ;;
                settings)  [ -f "$a" ] && P_SETTINGS=$(add_line "$P_SETTINGS" "$a$TAB$b$TAB$c") ;;
                gitignore) [ -f "$a" ] && grep -qxF "$b" "$a" 2>/dev/null \
                               && P_IGNORES=$(add_line "$P_IGNORES" "$a$TAB$b") ;;
                *) ;;
            esac
        done < "$MANIFEST"
        [ -e ".forge" ] && P_PATHS=$(add_line "$P_PATHS" ".forge")
    else
        # No receipt. Find what can be found without guessing.
        for p in .craft .claude/charter.json .forge; do
            [ -e "$p" ] && P_PATHS=$(add_line "$P_PATHS" "$p")
        done
        for f in CLAUDE.md .claude/CLAUDE.md; do
            [ -f "$f" ] && grep -q 'charter:start' "$f" 2>/dev/null \
                && P_FENCES=$(add_line "$P_FENCES" "$f${TAB}charter:start${TAB}charter:end")
        done
        for f in .claude/settings.local.json .claude/settings.json; do
            is_tars "$(style_of "$f")" && P_SETTINGS=$(add_line "$P_SETTINGS" "$f${TAB}key${TAB}outputStyle")
        done
        # Permission rules cannot be attributed without a receipt. Charter's
        # rules and yours live in the same array and look identical.
        for f in .claude/settings.json .claude/settings.local.json; do
            [ -f "$f" ] && grep -q '"deny"' "$f" \
                && P_UNKNOWN=$(add_line "$P_UNKNOWN" "$f: permission rules, source unknown without a receipt")
        done
        [ -f .gitignore ] && grep -qE '^\.craft/|^\.claude/charter\.json' .gitignore \
            && P_UNKNOWN=$(add_line "$P_UNKNOWN" ".gitignore: entries for .craft/ or .claude/charter.json")
    fi
fi

count() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | grep -c . ; }

# -------------------------------------------------------------------- plan
echo
echo "FORGE UNINSTALL"
echo
echo "Machine"
if [ "$KEEP_PLUGINS" = 1 ]; then
    echo "  plugins       kept (--keep-plugins)"
elif [ "$HAVE_CLAUDE" = 0 ]; then
    echo "  plugins       'claude' is not on your PATH, so plugins cannot be removed here"
elif [ -n "$INSTALLED" ]; then
    echo "  plugins       $INSTALLED"
else
    echo "  plugins       none installed from $MARKET"
fi
if [ "$KEEP_PLUGINS" = 1 ]; then
    echo "  marketplace   kept (--keep-plugins)"
elif [ "$MARKET_PRESENT" = yes ]; then
    echo "  marketplace   $MARKET"
else
    echo "  marketplace   not configured"
fi
if [ "$KEEP_SETTINGS" = 1 ]; then
    echo "  settings      kept (--keep-settings)"
elif [ -n "$USER_HITS" ]; then
    echo "  settings      $SETTINGS"
    for k in $USER_HITS; do echo "                  $k"; done
else
    echo "  settings      nothing of ours in $SETTINGS"
fi
if [ "$KEEP_STYLE" = 1 ]; then
    echo "  style file    kept (--keep-style)"
elif [ -f "$STYLE_FILE" ]; then
    echo "  style file    $STYLE_FILE"
else
    echo "  style file    not present"
fi

echo
echo "This repository   $PROJECT"
if [ "$KEEP_PROJECT" = 1 ]; then
    echo "  kept (--keep-project)"
else
    if [ "$HAVE_MANIFEST" = yes ]; then
        echo "  receipt       $MANIFEST  ($(count "$P_PATHS") paths, $(count "$P_FENCES") fences, $(count "$P_SETTINGS") settings, $(count "$P_IGNORES") gitignore)"
    else
        echo "  receipt       none — falling back to known markers and paths"
    fi
    [ -n "$P_PATHS" ]    && printf '%s\n' "$P_PATHS"    | sed 's/^/  remove        /'
    [ -n "$P_FENCES" ]   && printf '%s\n' "$P_FENCES"   | awk -F"$TAB" '{printf "  fence         %s  (%s .. %s)\n", $1, $2, $3}'
    [ -n "$P_SETTINGS" ] && printf '%s\n' "$P_SETTINGS" | awk -F"$TAB" '{ if ($2=="key") printf "  settings      %s: drop %s\n", $1, $3; else printf "  settings      %s: %s rule %s\n", $1, $2, $3 }'
    [ -n "$P_IGNORES" ]  && printf '%s\n' "$P_IGNORES"  | awk -F"$TAB" '{printf "  .gitignore    %s: %s\n", $1, $2}'
    [ -n "$P_UNKNOWN" ]  && printf '%s\n' "$P_UNKNOWN"  | sed 's/^/  left alone    /'
    [ -z "$P_PATHS$P_FENCES$P_SETTINGS$P_IGNORES$P_UNKNOWN" ] && echo "  nothing of ours here"
fi
echo

if [ "$MODE" = plan ]; then
    echo "Plan only. Nothing was changed. Re-run without --plan to remove."
    exit 0
fi

if [ "$MODE" = ask ]; then
    if [ -r /dev/tty ] && [ -w /dev/tty ]; then
        printf 'Remove all of the above? [y/N] ' > /dev/tty
        read -r ANS < /dev/tty || ANS=""
        case "$ANS" in
            y|Y|yes|YES) ;;
            *) echo "Nothing was changed."; exit 0 ;;
        esac
        echo
    else
        echo "error: no terminal to confirm on. Re-run with --yes, or --plan to preview." >&2
        exit 1
    fi
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$PROJECT/.forge-backup-$STAMP"

keep_copy() {
    # Copy a project file or directory into the backup tree before it changes.
    src="$1"
    case "$src" in /*) return 0 ;; esac
    [ -e "$src" ] || return 0
    dst="$BACKUP_DIR/$src"
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst" 2>/dev/null || true
}

# ---------------------------------------------------------------- settings
# JSON edits come first. The plugin removal deletes the directory this script
# may be running from, so that goes last.

json_edit() {
    # json_edit <file> <scope> [removal ...]
    # scope user   : marketplace, force-update, enabledPlugins and a TARS style
    # scope project: only what the removals name
    FILE="$1"; shift
    SCOPE="$1"; shift
    [ -f "$FILE" ] || return 0
    case "$JSON_BIN" in
        python3) python3 - "$FILE" "$MARKET" "$SCOPE" "$@" <<'PY'
import collections, json, shutil, sys, time

path, market, scope = sys.argv[1], sys.argv[2], sys.argv[3]
removals = sys.argv[4:]
try:
    with open(path) as fh:
        data = json.load(fh, object_pairs_hook=collections.OrderedDict)
except Exception as exc:
    print("  skipped %s (%s)" % (path, exc))
    sys.exit(0)

changed = []

def drop_key(key):
    if key in data:
        del data[key]
        changed.append("%s" % key)

for item in removals:
    bucket, _, value = item.partition("=")
    if bucket == "key":
        if value == "outputStyle" and data.get("outputStyle") not in ("TARS", "tars:TARS"):
            continue
        drop_key(value)
        continue
    perms = data.get("permissions")
    if isinstance(perms, dict) and isinstance(perms.get(bucket), list):
        rules = perms[bucket]
        if value in rules:
            rules.remove(value)
            changed.append("permissions.%s %s" % (bucket, value))
        if not rules:
            del perms[bucket]
        if not perms:
            del data["permissions"]

if scope == "user":
    if data.get("outputStyle") in ("TARS", "tars:TARS"):
        del data["outputStyle"]
        changed.append("outputStyle")
    env = data.get("env")
    if isinstance(env, dict) and "FORCE_AUTOUPDATE_PLUGINS" in env:
        del env["FORCE_AUTOUPDATE_PLUGINS"]
        changed.append("env.FORCE_AUTOUPDATE_PLUGINS")
        if not env:
            del data["env"]
    markets = data.get("extraKnownMarketplaces")
    if isinstance(markets, dict) and market in markets:
        del markets[market]
        changed.append("extraKnownMarketplaces.%s" % market)
        if not markets:
            del data["extraKnownMarketplaces"]
    plugins = data.get("enabledPlugins")
    if isinstance(plugins, dict):
        gone = [k for k in plugins if k.endswith("@" + market)]
        for k in gone:
            del plugins[k]
        if gone:
            changed.append("enabledPlugins: " + ", ".join(gone))
        if gone and not plugins:
            del data["enabledPlugins"]

if not changed:
    print("  unchanged %s" % path)
    sys.exit(0)

backup = path + ".backup-" + time.strftime("%Y%m%d-%H%M%S")
shutil.copyfile(path, backup)
with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
print("  edited %s" % path)
for item in changed:
    print("    removed %s" % item)
print("    backup %s" % backup)
PY
            ;;
        node) node -e '
          const fs = require("fs");
          const [path, market, scope, ...removals] = process.argv.slice(1);
          let data;
          try { data = JSON.parse(fs.readFileSync(path, "utf8")); }
          catch (e) { console.log("  skipped " + path + " (" + e.message + ")"); process.exit(0); }
          const changed = [];
          const styles = ["TARS", "tars:TARS"];
          for (const item of removals) {
            const i = item.indexOf("=");
            const bucket = i < 0 ? item : item.slice(0, i);
            const value  = i < 0 ? ""   : item.slice(i + 1);
            if (bucket === "key") {
              if (value === "outputStyle" && !styles.includes(data.outputStyle)) continue;
              if (data[value] !== undefined) { delete data[value]; changed.push(value); }
              continue;
            }
            const perms = data.permissions;
            if (perms && Array.isArray(perms[bucket])) {
              const at = perms[bucket].indexOf(value);
              if (at !== -1) { perms[bucket].splice(at, 1); changed.push("permissions." + bucket + " " + value); }
              if (perms[bucket].length === 0) delete perms[bucket];
              if (Object.keys(perms).length === 0) delete data.permissions;
            }
          }
          if (scope === "user") {
            if (styles.includes(data.outputStyle)) { delete data.outputStyle; changed.push("outputStyle"); }
            if (data.env && data.env.FORCE_AUTOUPDATE_PLUGINS !== undefined) {
              delete data.env.FORCE_AUTOUPDATE_PLUGINS;
              changed.push("env.FORCE_AUTOUPDATE_PLUGINS");
              if (Object.keys(data.env).length === 0) delete data.env;
            }
            const m = data.extraKnownMarketplaces;
            if (m && m[market] !== undefined) {
              delete m[market];
              changed.push("extraKnownMarketplaces." + market);
              if (Object.keys(m).length === 0) delete data.extraKnownMarketplaces;
            }
            const p = data.enabledPlugins;
            if (p) {
              const gone = Object.keys(p).filter(k => k.endsWith("@" + market));
              gone.forEach(k => delete p[k]);
              if (gone.length) changed.push("enabledPlugins: " + gone.join(", "));
              if (gone.length && Object.keys(p).length === 0) delete data.enabledPlugins;
            }
          }
          if (!changed.length) { console.log("  unchanged " + path); process.exit(0); }
          const pad = n => String(n).padStart(2, "0");
          const d = new Date();
          const stamp = "" + d.getFullYear() + pad(d.getMonth()+1) + pad(d.getDate())
                      + "-" + pad(d.getHours()) + pad(d.getMinutes()) + pad(d.getSeconds());
          const backup = path + ".backup-" + stamp;
          fs.copyFileSync(path, backup);
          fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
          console.log("  edited " + path);
          changed.forEach(c => console.log("    removed " + c));
          console.log("    backup " + backup);
        ' "$FILE" "$MARKET" "$SCOPE" "$@"
            ;;
        *) echo "  warning: neither python3 nor node is available, so $FILE was left alone." >&2 ;;
    esac
}

if [ "$KEEP_SETTINGS" = 0 ] && [ -n "$USER_HITS" ]; then
    echo "User settings:"
    json_edit "$SETTINGS" user
    echo
fi

# -------------------------------------------------------------- style file
if [ "$KEEP_STYLE" = 0 ] && [ -f "$STYLE_FILE" ]; then
    rm -f "$STYLE_FILE"
    echo "Style file:"
    echo "  removed $STYLE_FILE"
    echo
fi

# ----------------------------------------------------------------- project
if [ "$KEEP_PROJECT" = 0 ] && [ -n "$P_PATHS$P_FENCES$P_SETTINGS$P_IGNORES" ]; then
    echo "This repository:"

    # Fences first, while the receipt that describes them still exists.
    if [ -n "$P_FENCES" ]; then
        printf '%s\n' "$P_FENCES" | while IFS="$TAB" read -r file start end; do
            [ -f "$file" ] || continue
            keep_copy "$file"
            TMPF="$file.forge-tmp.$$"
            awk -v s="$start" -v e="$end" '
                index($0, s) { skip = 1 }
                !skip        { print }
                index($0, e) { skip = 0 }
            ' "$file" > "$TMPF"
            mv "$TMPF" "$file"
            echo "  cleared fence in $file"
        done
    fi

    if [ -n "$P_IGNORES" ]; then
        printf '%s\n' "$P_IGNORES" | while IFS="$TAB" read -r file line; do
            [ -f "$file" ] || continue
            keep_copy "$file"
            TMPF="$file.forge-tmp.$$"
            grep -vxF "$line" "$file" > "$TMPF" || true
            mv "$TMPF" "$file"
            echo "  removed '$line' from $file"
        done
    fi

    if [ -n "$P_SETTINGS" ]; then
        # One pass per file, so a file with several rules is edited and backed
        # up once rather than once per rule.
        FILES=$(printf '%s\n' "$P_SETTINGS" | cut -d"$TAB" -f1 | sort -u)
        for file in $FILES; do
            [ -f "$file" ] || continue
            keep_copy "$file"
            set --
            while IFS="$TAB" read -r f bucket value; do
                [ "$f" = "$file" ] && set -- "$@" "$bucket=$value"
            done <<EOF
$P_SETTINGS
EOF
            json_edit "$file" project "$@"
        done
    fi

    if [ -n "$P_PATHS" ]; then
        printf '%s\n' "$P_PATHS" | while read -r p; do
            [ -e "$p" ] || continue
            keep_copy "$p"
            rm -rf "$p"
            echo "  removed $p"
            # rmdir only succeeds on an empty directory, which is exactly when
            # a now-empty .claude/rules/ should go too.
            rmdir "$(dirname "$p")" 2>/dev/null || true
        done
    fi

    [ -d "$BACKUP_DIR" ] && echo "  copies kept in ${BACKUP_DIR#$PROJECT/}"
    echo
fi

if [ "$KEEP_PROJECT" = 0 ] && [ -n "$P_UNKNOWN" ]; then
    echo "Left for you to decide:"
    printf '%s\n' "$P_UNKNOWN" | sed 's/^/  /'
    echo "  No receipt existed, so these cannot be told apart from your own rules."
    echo
fi

# ----------------------------------------------------------------- plugins
# Last, because this deletes the plugin directory this script may be running
# from. On Linux and macOS an unlinked file stays readable through the open
# descriptor, so the rest of this script still runs.
if [ "$KEEP_PLUGINS" = 0 ] && [ "$HAVE_CLAUDE" = 1 ] \
   && { [ -n "$INSTALLED" ] || [ "$MARKET_PRESENT" = yes ]; }; then
    echo "Plugins:"
    for p in $INSTALLED; do
        if claude plugin uninstall "$p" --yes >/dev/null 2>&1; then
            echo "  removed $p"
        else
            echo "  failed  $p  (run: claude plugin uninstall $p --yes)"
        fi
    done
    if [ "$MARKET_PRESENT" = yes ]; then
        if claude plugin marketplace remove "$MARKET" >/dev/null 2>&1; then
            echo "  removed marketplace $MARKET"
        else
            echo "  failed  marketplace $MARKET  (run: claude plugin marketplace remove $MARKET)"
        fi
    fi
    echo
fi

cat <<EOF
Done. Restart Claude Code so the removals take effect.

Backups: settings files as *.backup-$STAMP beside the original.
EOF
[ -d "$BACKUP_DIR" ] && echo "         project files in ${BACKUP_DIR#$PROJECT/}"
cat <<'EOF'

Other repositories are not touched. Run this from each one, or find them with:
  grep -rl 'charter:start' ~/your/projects --include=CLAUDE.md
EOF
