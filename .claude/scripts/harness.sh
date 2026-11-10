#!/usr/bin/env bash
# Headless harness: Claude plans, implements, tests and reviews a feature using the project agents.
# Exit code is 0 only when typecheck, lint, tests AND the reviewer verdict all pass.
# Review/fix loops up to MAX_ROUNDS times, like the /add-feature skill.
#
# Usage: ./.claude/scripts/harness.sh "rooms: create, list and delete chat rooms with realtime updates"
set -euo pipefail
cd "$(dirname "$0")/../.."

FEATURE="${1:?Usage: harness.sh \"feature description\"}"
MAX_ROUNDS="${MAX_ROUNDS:-2}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
HEADLESS="Headless run: nobody can answer questions or approve prompts. Never ask for permission; if a command is denied, stop and report the exact command in your answer."
INSTALL_TOOLS="Bash(npm install:*) Bash(npm i:*)"
PLAN="$WORK/plan.md"
REVIEW="$WORK/review.md"

if ! grep -q '"hasTrustDialogAccepted": true' <(python3 -c "
import json,os,sys
d=json.load(open(os.path.expanduser('~/.claude.json'))).get('projects',{}).get(os.getcwd(),{})
print(json.dumps(d,indent=1))" 2>/dev/null); then
  echo "WARN: this folder is not trusted yet; permissions.allow will be ignored. Run 'claude' here once and accept the trust dialog." >&2
fi

verify() {
  local ok=0
  for WORKSPACE in server client; do
    [ -f "$WORKSPACE/package.json" ] || continue
    (cd "$WORKSPACE" && npm run typecheck && npm run lint && npm test) || ok=1
  done
  return $ok
}

# The verdict is the last non-empty line, so prose mentioning "APPROVED" cannot fool the script.
verdict_approved() {
  [ "$(grep -v '^[[:space:]]*$' "$REVIEW" | tail -n1 | tr -d '[:space:]*`')" = "VERDICT:APPROVED" ]
}

echo "==> 1 Plan"
claude -p "Use the feature-planner agent to plan this feature: $FEATURE. Output only the plan." \
  --permission-mode plan | tee "$PLAN"

echo "==> 2 Implement server, then client"
claude -p "$HEADLESS Implement this plan. Run the server-writer agent first and, when it finishes, the client-writer agent. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits --max-turns 40

echo "==> 3 Tests"
claude -p "$HEADLESS Run the test-writer agent to write tests for the feature that was just implemented. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits --allowedTools $INSTALL_TOOLS --max-turns 30

APPROVED=0
for ROUND in $(seq 1 "$MAX_ROUNDS"); do
  echo "==> 4 Verify before review (round $ROUND/$MAX_ROUNDS)"
  verify > "$WORK/verify.log" 2>&1 || true
  tail -n 60 "$WORK/verify.log"

  echo "==> 4 Review (round $ROUND/$MAX_ROUNDS)"
  # acceptEdits (not plan): the reviewer must run npm; it has no edit tools, so it stays read-only.
  claude -p "$HEADLESS Use the code-reviewer agent to review the current changes against the plan. Latest typecheck/lint/test output (a failing check is a blocker):
$(tail -n 60 "$WORK/verify.log")

Plan:
$(cat "$PLAN")" \
    --permission-mode acceptEdits | tee "$REVIEW"

  if verdict_approved; then
    APPROVED=1
    break
  fi

  [ "$ROUND" -lt "$MAX_ROUNDS" ] || break
  echo "==> 4b Fix blockers"
  claude -p "$HEADLESS Fix every blocker in this review, sending each to its owner agent (server-writer, client-writer or test-writer), then stop. Review:
$(cat "$REVIEW")" \
    --permission-mode acceptEdits --allowedTools $INSTALL_TOOLS --max-turns 40
done

echo "==> 5 Verify (typecheck + lint + tests)"
VERIFIED=0
verify || VERIFIED=1

if [ "$APPROVED" -eq 1 ] && [ "$VERIFIED" -eq 0 ]; then
  echo "OK: feature implemented"
else
  echo "FAIL: approved=$APPROVED verify_failed=$VERIFIED"
  exit 1
fi
