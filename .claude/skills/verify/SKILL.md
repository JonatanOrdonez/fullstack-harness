---
name: verify
description: Runs typecheck, lint and tests in the client and server workspaces and reports a pass/fail table. Use before finishing any task or after fixing review comments.
allowed-tools: Bash, Read, Grep, Glob
---

# Verify

For each workspace that has a `package.json` (`server/`, then `client/`), run in order and stop that workspace at the first failure:

1. `npm run typecheck`
2. `npm run lint`
3. `npm test`

Then report a table:

| Workspace | Typecheck | Lint | Tests |
|-----------|-----------|------|-------|

Rules:

- Do not edit code in this skill; only run and report. On failure include the first relevant error lines and the owner (`server-writer`, `client-writer` or `test-writer`).
- A missing script is reported as `missing`, not as a pass.
- If `node_modules` is absent, say so and ask before running `npm install`.
