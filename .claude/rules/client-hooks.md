---
paths:
  - "client/hooks/**/*.ts"
  - "client/hooks/**/*.tsx"
---

# Client hooks

- One hook per file in `client/hooks/`, named `useThing.ts`, exported by name. Always `'use client';`.
- A hook encapsulates reusable stateful logic that is **not** shared app state (that belongs in a context): uploads, debounced values, media queries, subscriptions for one component.
- Return a plain object with state first and actions after: `{ imageUrl, isUploading, error, selectFile, clear }`.
- Errors are converted to user-facing strings with `getErrorMessage` from `@/lib/errors` and returned as `error: string | null`; the hook does not throw to the component.
- Clean up everything created in an effect: object URLs (`URL.revokeObjectURL`), timers, listeners, channels.
- Validate cheap constraints (type, size) before any network call.
- Constants (limits, allowed types) are module-level `const`s; export what components need (for example `IMAGE_ACCEPT`).
- Hooks never render JSX.

Templates: `.claude/docs/client/hooks.md`, `.claude/docs/client/file-upload.md`.
