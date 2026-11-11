#!/usr/bin/env bash
# PreToolUse hook (Bash|Read|Edit|Write|Grep|Glob): block any tool call that touches a real .env file.
# Permission deny rules only match exact commands (`head .env` or `rm -fr` slip through); this inspects the
# whole command or path. `.env.example` (and .sample/.template) stay allowed.
# Exit 2 blocks the call and sends the message back to Claude.
set -uo pipefail

python3 -c '
import json, re, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
tool_input = data.get("tool_input") or {}
text = " ".join(str(tool_input.get(k, "")) for k in ("command", "file_path", "path", "pattern", "glob"))
# .env, .env.local, .env.production, ... but not .env.example/.sample/.template
for match in re.finditer(r"(?<![A-Za-z0-9_])\.env(\.[A-Za-z0-9_-]+)?(?![A-Za-z0-9_-])", text):
    suffix = (match.group(1) or "").lstrip(".")
    if suffix not in ("example", "sample", "template"):
        sys.stderr.write("Blocked: .env files hold secrets and are off limits. Use .env.example instead.\n")
        sys.exit(2)
' || exit $?
exit 0
