---
name: add-component
description: Adds one React component to client/components following the project conventions (named export, typed props, Tailwind, loading/empty/error states). Use for a single UI piece.
argument-hint: "<Name and purpose>"
---

# Add a component

Argument: component name and purpose (for example `MessagesList shows the messages of the active room`).

1. Read `.claude/rules/client-components.md` and `.claude/docs/client/components.md` (template, form and list examples).
2. Check `client/components/` for an existing component to reuse or extend.
3. Create `client/components/<Name>.tsx`. Get data from an existing `useX()` hook or accept props; do not create a context here (use `/add-context`).
4. Add a Testing Library test following `.claude/docs/client/testing.md`.
5. Run `npm run typecheck`, `npm run lint` and `npm test` in `client/`.

If the component needs new shared state, new API calls or realtime, stop and use `/add-client-feature` instead.
