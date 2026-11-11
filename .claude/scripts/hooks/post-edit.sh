#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): lint ONLY the edited file.
# Full typecheck is deliberately not run here: writers build bottom-up (types -> repository -> ...),
# so intermediate states do not compile and a per-edit tsc would loop on errors that fix themselves.
# The full typecheck runs in the Stop hook and in /verify.
# Reads the hook JSON from stdin. Does nothing when the workspace, eslint or the file do not exist.
# Exit 2 sends the output back to Claude so it fixes the problem.
set -uo pipefail

FILE="$(python3 -c '
import json, sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("file_path", ""))
except Exception:
    print("")
' 2>/dev/null)"
ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$FILE" in
  "$ROOT"/client/*) WORKSPACE="client" ;;
  "$ROOT"/server/*) WORKSPACE="server" ;;
  *) exit 0 ;;
esac

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs) ;;
  *) exit 0 ;;
esac

DIR="$ROOT/$WORKSPACE"
[ -f "$FILE" ] || exit 0
[ -f "$DIR/package.json" ] || exit 0
[ -x "$DIR/node_modules/.bin/eslint" ] || exit 0

cd "$DIR" || exit 0
"$DIR/node_modules/.bin/eslint" "$FILE" 1>&2 || exit 2

exit 0
