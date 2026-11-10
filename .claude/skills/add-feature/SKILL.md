---
name: add-feature
description: Orchestrates a complete fullstack feature (plan, server, client, tests, review) by running the project agents in order. Use when the user asks for a new feature that touches both client and server.
---

# Add a fullstack feature

Argument: the feature description (for example `chat rooms with realtime updates`).

You are the orchestrator: agents do not call each other. Launch them **one at a time, in this order**, because each depends on the previous result. Pass each agent everything it needs; it has no memory of earlier steps.

1. **`feature-planner`**: give it the description. Keep the plan. If the plan shows important assumptions (auth model, realtime provider, destructive changes) or the feature already exists, tell the user before continuing.
2. **`server-writer`**: give it the full plan. Keep its report (routes, env vars, error cases).
3. **`client-writer`**: give it the plan **and** the server report.
4. **`test-writer`**: give it the plan's test cases and both reports.
5. **`code-reviewer`**: ask it to review all changes against the plan.

Then:

- If `test-writer` reports a real bug, send it to the owner agent (`server-writer` or `client-writer`) and re-run `test-writer` (maximum 2 rounds).
- If the reviewer answers `CHANGES REQUIRED`, send each blocker to the agent that owns it and repeat step 5.
- Finish only when the reviewer says `APPROVED` and typecheck, lint and tests pass in every touched workspace (use `/verify`).

Optional deep dives, load only if the plan needs them: `/add-db-table`, `/add-realtime`, `/add-file-upload`, `/add-auth` describe those slices in detail and are what the writers follow.

Finish by summarizing for the user: what was added (routes, tables, components), the number of tests, and the reviewer verdict.
