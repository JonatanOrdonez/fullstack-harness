---
name: add-hook
description: Adds a reusable custom hook to client/hooks (for example uploads, debounce, subscriptions) following the project conventions. Use for stateful logic that is not shared app state.
---

# Add a hook

Argument: hook name and purpose (for example `useDebouncedValue`).

1. Read `.claude/rules/client-hooks.md` and `.claude/docs/client/hooks.md` (template, cleanup, error handling).
2. For uploads, also read `.claude/docs/client/file-upload.md`.
3. Confirm it should be a hook and not a context: shared across distant components → context; local reusable logic → hook.
4. Create `client/hooks/<useName>.ts` with `'use client';`, a named export and an object return.
5. Add `renderHook` tests per `.claude/docs/client/testing.md`, including cleanup on unmount.
6. Run `npm run typecheck`, `npm run lint` and `npm test` in `client/`.
