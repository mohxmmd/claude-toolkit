#!/bin/sh
# TARS installer for Claude Code.
# Copies output-styles/TARS.md into your Claude Code output styles directory.
# Never deletes anything. An existing TARS.md is backed up first.

set -eu

RAW_URL="https://raw.githubusercontent.com/mohxmmd/skills/main/tars/output-styles/TARS.md"
DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/output-styles"

usage() {
    cat <<'USAGE'
Install the TARS output style for Claude Code.

Usage:
  ./install.sh [--dir <path>] [--help]

Options:
  --dir <path>   Install into <path> instead of ~/.claude/output-styles
  --help         Show this message

An existing TARS.md is copied to TARS.md.backup-<timestamp> before the new
one is written. Nothing is ever deleted.
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dir)
            [ $# -ge 2 ] || { echo "error: --dir needs a path" >&2; exit 1; }
            DEST_DIR="$2"; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) echo "error: unknown option '$1'. Try --help." >&2; exit 1 ;;
    esac
done

# Prefer the copy sitting next to this script; fall back to downloading.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL_SRC="$SCRIPT_DIR/output-styles/TARS.md"
TMP_SRC=""

cleanup() {
    if [ -n "$TMP_SRC" ]; then rm -f "$TMP_SRC"; fi
}
trap cleanup EXIT INT TERM

if [ -f "$LOCAL_SRC" ]; then
    SRC="$LOCAL_SRC"
else
    TMP_SRC=$(mktemp "${TMPDIR:-/tmp}/tars.XXXXXX")
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$RAW_URL" -o "$TMP_SRC"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$TMP_SRC" "$RAW_URL"
    else
        echo "error: need curl or wget to download TARS.md, or run this script" >&2
        echo "       from a checkout of the repository." >&2
        exit 1
    fi
    [ -s "$TMP_SRC" ] || { echo "error: downloaded TARS.md is empty" >&2; exit 1; }
    SRC="$TMP_SRC"
fi

DEST="$DEST_DIR/TARS.md"
mkdir -p "$DEST_DIR"

if [ -f "$DEST" ]; then
    if cmp -s "$SRC" "$DEST"; then
        echo "TARS is already installed and up to date at $DEST"
        exit 0
    fi
    BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$DEST" "$BACKUP"
    echo "Existing TARS.md backed up to $BACKUP"
fi

cp "$SRC" "$DEST"

cat <<EOF

TARS installed to $DEST

Next:
  1. Open Claude Code
  2. Run /config and pick TARS under "Output style"
  3. Run /clear (output styles load at session start)

To uninstall, delete $DEST and switch back to Default in /config.
EOF
