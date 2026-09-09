#!/bin/sh
# Claude Forge updater, entry point.
#
# The implementation lives in bundles/forge/scripts/update.sh so that the
# installed plugin ships it too, and /forge:update runs the same code this
# script runs. One updater, two ways in.
#
# Prefers the copy next to this script; downloads it when you have no checkout.

set -eu

RAW_URL="https://raw.githubusercontent.com/mohxmmd/claude-toolkit/main/bundles/forge/scripts/update.sh"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCAL="$SCRIPT_DIR/bundles/forge/scripts/update.sh"

if [ -f "$LOCAL" ]; then
    exec sh "$LOCAL" "$@"
fi

TMP=$(mktemp "${TMPDIR:-/tmp}/forge-update.XXXXXX")
cleanup() { rm -f "$TMP"; }
trap cleanup EXIT INT TERM

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_URL" -o "$TMP"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMP" "$RAW_URL"
else
    echo "error: need curl or wget, or run this from a checkout of the repository." >&2
    exit 1
fi
[ -s "$TMP" ] || { echo "error: downloaded updater is empty" >&2; exit 1; }

sh "$TMP" "$@"
