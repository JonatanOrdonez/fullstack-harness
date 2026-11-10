#!/usr/bin/env bash
# Headless harness: Claude plans, implements, tests and reviews a feature using the project agents.
# The exit code depends on typecheck, lint, tests and the reviewer verdict. Useful for CI or batches.
#
# Usage: ./scripts/harness.sh "rooms: create, list and delete chat rooms with realtime updates"
set -euo pipefail
cd "$(dirname "$0")/../.."

FEATURE="${1:?Usage: harness.sh \"feature description\"}"
PLAN="$(mktemp)"
REVIEW="$(mktemp)"

echo "==> 1/5 Plan"
claude -p "Use the feature-planner agent to plan this feature: $FEATURE. Output only the plan." \
  --permission-mode plan | tee "$PLAN"

echo "==> 2/5 Implement server and client"
claude -p "Implement this plan. Run the server-writer agent first, and when it finishes, the client-writer agent. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits \
  --max-turns 40

echo "==> 3/5 Tests"
claude -p "Run the test-writer agent to write tests for the feature that was just implemented. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits \
  --max-turns 30

echo "==> 4/5 Review"
claude -p "Use the code-reviewer agent to review the current changes against the plan. End with APPROVED or CHANGES REQUIRED. Plan:
$(cat "$PLAN")" \
  --permission-mode plan | tee "$REVIEW"

echo "==> 5/5 Verify (typecheck + lint + tests)"
for WORKSPACE in server client; do
  [ -f "$WORKSPACE/package.json" ] || continue
  (cd "$WORKSPACE" && npm run typecheck && npm run lint && npm test)
done

if grep -q "APPROVED" "$REVIEW" && ! grep -q "CHANGES REQUIRED" "$REVIEW"; then
  echo "OK: feature implemented"
else
  echo "FAIL: review not approved"
  exit 1
fi
