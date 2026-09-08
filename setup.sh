#!/bin/sh
# Claude Forge installer.
#
# Adds the marketplace, installs the bundle (which pulls in Charter, Craft and
# TARS), and turns on auto-update so you receive fixes without doing this again.
#
# Never deletes anything. Your settings file is backed up before it is touched.

set -eu

REPO="${FORGE_REPO:-mohxmmd/claude-toolkit}"
MARKET="claude-forge"
CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CFG_DIR/settings.json"
AUTO_UPDATE=1

usage() {
    cat <<'USAGE'
Install the Claude Forge: Charter, Craft and TARS.

Usage:
  ./setup.sh [--no-auto-update] [--auto-update-only] [--help]

Options:
  --no-auto-update    Install, but do not enable automatic updates
  --auto-update-only  Only turn on auto-update; install nothing
  --help              Show this message

Auto-update, when enabled, writes two things into your Claude Code settings:

  extraKnownMarketplaces.claude-forge.autoUpdate = true
      Refresh this marketplace and its installed plugins at session start.

  env.FORCE_AUTOUPDATE_PLUGINS = "1"
      Let plugins update even when Claude Code's own auto-updater is off, which
      is the default for native and VS Code installs. This affects PLUGINS ONLY
      and never updates Claude Code itself.

This means you will run new versions of these plugins without reviewing them
first. That is the point, and it is also a real trade-off. Use
--no-auto-update if you would rather update by hand.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --no-auto-update)   AUTO_UPDATE=0; shift ;;
        --auto-update-only) AUTO_UPDATE=2; shift ;;
        --help|-h)          usage; exit 0 ;;
        *) echo "error: unknown option '$1'. Try --help." >&2; exit 1 ;;
    esac
done

command -v claude >/dev/null 2>&1 || {
    echo "error: 'claude' is not on your PATH." >&2
    echo "       Install Claude Code first: https://claude.com/claude-code" >&2
    exit 1
}

# ------------------------------------------------------------------ install
if [ "$AUTO_UPDATE" != 2 ]; then
    echo "Adding marketplace $REPO ..."
    claude plugin marketplace add "$REPO"

    echo "Installing forge (with Charter, Craft and TARS) ..."
    claude plugin install "forge@$MARKET"
fi

# ------------------------------------------------------------ auto-update
if [ "$AUTO_UPDATE" = 0 ]; then
    cat <<EOF

Installed. Auto-update was NOT enabled.

To update later:
  claude plugin marketplace update $MARKET
  claude plugin update forge@$MARKET

Next:
  1. Restart Claude Code   (plugins load at session start)
  2. Run /charter:init in a project
EOF
    exit 0
fi

# One of these is needed to edit JSON safely. Hand-rolling it with sed corrupts
# real settings files, which is not an acceptable failure for this script.
EDITOR_BIN=""
if command -v python3 >/dev/null 2>&1; then EDITOR_BIN=python3
elif command -v node >/dev/null 2>&1; then EDITOR_BIN=node
else
    cat <<EOF >&2

warning: neither python3 nor node is available, so auto-update was not enabled.
         Add this to $SETTINGS by hand:

  "env": { "FORCE_AUTOUPDATE_PLUGINS": "1" },
  "extraKnownMarketplaces": {
    "$MARKET": {
      "source": { "source": "github", "repo": "$REPO" },
      "autoUpdate": true
    }
  }
EOF
    exit 0
fi

mkdir -p "$CFG_DIR"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

BACKUP="$SETTINGS.backup-$(date +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$BACKUP"

if [ "$EDITOR_BIN" = python3 ]; then
    python3 - "$SETTINGS" "$MARKET" "$REPO" <<'PY'
import collections, json, sys

path, market, repo = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as fh:
    data = json.load(fh, object_pairs_hook=collections.OrderedDict)

data.setdefault("env", collections.OrderedDict())["FORCE_AUTOUPDATE_PLUGINS"] = "1"

markets = data.setdefault("extraKnownMarketplaces", collections.OrderedDict())
entry = markets.setdefault(market, collections.OrderedDict())
# Preserve an existing source: the user may have added this from a fork.
entry.setdefault("source", collections.OrderedDict(
    [("source", "github"), ("repo", repo)]))
entry["autoUpdate"] = True

with open(path, "w") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
else
    node -e '
      const fs = require("fs");
      const [path, market, repo] = process.argv.slice(1);
      const data = JSON.parse(fs.readFileSync(path, "utf8"));
      data.env = data.env || {};
      data.env.FORCE_AUTOUPDATE_PLUGINS = "1";
      data.extraKnownMarketplaces = data.extraKnownMarketplaces || {};
      const entry = data.extraKnownMarketplaces[market] || {};
      entry.source = entry.source || { source: "github", repo };
      entry.autoUpdate = true;
      data.extraKnownMarketplaces[market] = entry;
      fs.writeFileSync(path, JSON.stringify(data, null, 2) + "\n");
    ' "$SETTINGS" "$MARKET" "$REPO"
fi

cat <<EOF

Auto-update enabled for $MARKET.
Settings backed up to $BACKUP

You will now receive new versions of these plugins automatically, without
reviewing them first. Undo any time by deleting "autoUpdate" from
extraKnownMarketplaces in $SETTINGS.

Next:
  1. Restart Claude Code   (plugins load at session start)
  2. Run /charter:init in a project
EOF
