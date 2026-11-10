---
name: add-client-feature
description: Adds a client feature with components, a context provider and hooks under client/, consuming an existing API. Use when the server endpoints already exist.
argument-hint: "<feature, e.g. rooms list with create and delete>"
disable-model-invocation: true
---

# Add a client feature

Argument: the feature (for example `rooms list with create and delete`).

Steps:

1. Run `feature-planner`; it must confirm the endpoints it will consume already exist (read `server/src/features/**/*.router.ts`). If they do not, stop and suggest `/add-feature`.
2. Run `client-writer` with the plan.
3. Run `test-writer` limited to the client.
4. Run `code-reviewer`; loop on `CHANGES REQUIRED` (max 2 rounds).

Load on demand, only what the plan needs:

- State and API calls: `.claude/docs/client/contexts.md`
- UI building blocks: `.claude/docs/client/components.md`
- Reusable logic: `.claude/docs/client/hooks.md`
- API client, config, errors, auth header: `.claude/docs/client/lib-axios-auth.md`
- Realtime: `.claude/docs/client/realtime-subscription.md`
- Uploads: `.claude/docs/client/file-upload.md`

Done when `npm run typecheck`, `npm run lint`, `npm test` pass in `client/` and the reviewer approves.
