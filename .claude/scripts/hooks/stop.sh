#!/usr/bin/env bash
# Stop hook: typecheck + tests for every workspace that has uncommitted changes.
# - Skips workspaces with no changes (pure Q&A turns cost nothing). Without git, it always runs.
# - Exit 2 keeps Claude working until checks pass. The stop_hook_active guard lets the second stop
#   through, so a test that intentionally fails to prove a bug reported by test-writer cannot loop forever.
set -uo pipefail

# harness.sh runs its own verify and must keep review sessions read-only
[ "${HARNESS_HEADLESS:-}" = "1" ] && exit 0

INPUT="$(cat)"
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATUS=0

has_script() { grep -q "\"$1\"[[:space:]]*:" "$2/package.json"; }

has_changes() {
  git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  [ -n "$(git -C "$ROOT" status --porcelain -- "$1" 2>/dev/null)" ]
}

for WORKSPACE in server client; do
  DIR="$ROOT/$WORKSPACE"
  [ -f "$DIR/package.json" ] || continue
  [ -d "$DIR/node_modules" ] || continue
  has_changes "$WORKSPACE" || continue

  if has_script typecheck "$DIR"; then
    echo "==> typecheck: $WORKSPACE" 1>&2
    (cd "$DIR" && npm run typecheck --silent 1>&2) || STATUS=2
  fi

  # Skip the default npm placeholder ("no test specified")
  has_script test "$DIR" || continue
  grep -q 'no test specified' "$DIR/package.json" && continue

  echo "==> tests: $WORKSPACE" 1>&2
  (cd "$DIR" && npm test --silent 1>&2) || STATUS=2
done

exit $STATUS
