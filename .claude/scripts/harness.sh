#!/usr/bin/env bash
# Headless harness: Claude plans, implements, tests and reviews a feature using the project agents.
# Exit code is 0 only when typecheck, lint, tests AND the reviewer verdict all pass.
# Review/fix loops up to MAX_ROUNDS times, like the /add-feature skill.
#
# Usage: ./.claude/scripts/harness.sh "rooms: create, list and delete chat rooms with realtime updates"
set -euo pipefail
cd "$(dirname "$0")/../.."

FEATURE="${1:?Usage: harness.sh \"feature description\"}"
MAX_ROUNDS="${MAX_ROUNDS:-3}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
HEADLESS="Headless run: nobody can answer questions or approve prompts. Never ask for permission. Do not run npm install: declare dependencies in package.json and the script installs them. If another command is denied, stop and report it."
# Untrusted folders ignore permissions.allow, so the checks agents need are granted here explicitly.
CHECK_TOOLS="Bash(npm run:*) Bash(npm test:*) Bash(npx tsc:*) Bash(npx eslint:*) Bash(npx vitest:*) Bash(git status:*) Bash(git diff:*)"
# The Stop hook would make these sessions fix failures on their own; the script runs its own verify.
export HARNESS_HEADLESS=1
PLAN="$WORK/plan.md"
REVIEW="$WORK/review.md"

if ! grep -q '"hasTrustDialogAccepted": true' <(python3 -c "
import json,os,sys
d=json.load(open(os.path.expanduser('~/.claude.json'))).get('projects',{}).get(os.getcwd(),{})
print(json.dumps(d,indent=1))" 2>/dev/null); then
  echo "WARN: this folder is not trusted yet; permissions.allow will be ignored. Run 'claude' here once and accept the trust dialog." >&2
fi

# Installs run from the script, not from the agents: headless agents cannot get npm install approved
# (denied even with --allowedTools), but they can declare dependencies in package.json.
install_deps() {
  for WORKSPACE in server client; do
    [ -f "$WORKSPACE/package.json" ] || continue
    echo "==> npm install ($WORKSPACE)"
    (cd "$WORKSPACE" && npm install --no-audit --no-fund) || echo "WARN: npm install failed in $WORKSPACE" >&2
  done
}

has_changes() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  [ -n "$(git status --porcelain -- "$1" 2>/dev/null | grep -v node_modules)" ]
}

has_script() { grep -q "\"$1\"[[:space:]]*:" "$2/package.json"; }

# Runs typecheck, lint and tests only in workspaces with changes (an untouched workspace without a
# test script must not fail the run). Prints a PASS/FAIL/MISSING summary first, then the head of every
# failing step, so the reviewer never loses a result to a long test log.
verify() {
  local ok=0 summary="" details="" out step
  install_deps >/dev/null 2>&1
  for WORKSPACE in server client; do
    [ -f "$WORKSPACE/package.json" ] || continue
    has_changes "$WORKSPACE" || { summary+="$WORKSPACE: unchanged, skipped"$'\n'; continue; }
    for step in typecheck lint test; do
      if ! has_script "$step" "$WORKSPACE"; then
        summary+="$WORKSPACE $step: MISSING script"$'\n'; ok=1; continue
      fi
      out="$(cd "$WORKSPACE" && npm run "$step" --silent 2>&1)" && {
        summary+="$WORKSPACE $step: PASS"$'\n'
      } || {
        summary+="$WORKSPACE $step: FAIL"$'\n'; ok=1
        details+="--- $WORKSPACE $step (first 40 lines) ---"$'\n'"$(printf '%s\n' "$out" | head -n 40)"$'\n'
      }
    done
  done
  printf '%s\n%s\n' "$summary" "$details"
  return $ok
}

# Only an explicit "VERDICT:" line counts (the last one wins), so prose mentioning "APPROVED" cannot fool
# the script, and a missing verdict line counts as not approved.
verdict_approved() {
  local line
  line="$(grep -E '^[[:space:]*`]*VERDICT:' "$REVIEW" | tail -n1 | tr -d '[:space:]*`')"
  [ "$line" = "VERDICT:APPROVED" ]
}

echo "==> 1 Plan"
claude -p "Use the feature-planner agent to plan this feature: $FEATURE. Output only the plan." \
  --permission-mode plan | tee "$PLAN"

echo "==> 2 Implement server, then client"
claude -p "$HEADLESS Implement this plan. Run the server-writer agent first and, when it finishes, the client-writer agent. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits --allowedTools $CHECK_TOOLS --max-turns 40

echo "==> 3 Tests"
claude -p "$HEADLESS Run the test-writer agent to write tests for the feature that was just implemented. Plan:
$(cat "$PLAN")" \
  --permission-mode acceptEdits --allowedTools $CHECK_TOOLS --max-turns 30

APPROVED=0
for ROUND in $(seq 1 "$MAX_ROUNDS"); do
  echo "==> 4 Verify before review (round $ROUND/$MAX_ROUNDS)"
  verify > "$WORK/verify.log" 2>&1 || true
  cat "$WORK/verify.log"

  echo "==> 4 Review (round $ROUND/$MAX_ROUNDS)"
  # Not plan mode (it blocks Bash). Edit/Write are disallowed so the review stays read-only.
  claude -p "$HEADLESS Use the code-reviewer agent to review the current changes against the plan. Do not edit anything and do not fix issues. Reply with the reviewer's complete answer verbatim, ending with its VERDICT line, and add nothing after it. Latest typecheck/lint/test output (a failing check is a blocker):
$(cat "$WORK/verify.log")

Plan:
$(cat "$PLAN")" \
    --permission-mode acceptEdits --allowedTools $CHECK_TOOLS \
    --disallowedTools Edit Write NotebookEdit | tee "$REVIEW"

  if verdict_approved; then
    APPROVED=1
    break
  fi

  [ "$ROUND" -lt "$MAX_ROUNDS" ] || break
  echo "==> 4b Fix blockers"
  claude -p "$HEADLESS Fix every blocker in this review, sending each to its owner agent (server-writer, client-writer or test-writer), then stop. Review:
$(cat "$REVIEW")" \
    --permission-mode acceptEdits --allowedTools $CHECK_TOOLS --max-turns 40
done

echo "==> 5 Verify (typecheck + lint + tests)"
VERIFIED=0
verify > "$WORK/verify.log" 2>&1 || VERIFIED=1
cat "$WORK/verify.log"

if [ "$APPROVED" -eq 1 ] && [ "$VERIFIED" -eq 0 ]; then
  echo "OK: feature implemented"
else
  echo "FAIL: approved=$APPROVED verify_failed=$VERIFIED"
  exit 1
fi
