---
paths:
  - "client/components/**/*.tsx"
  - "client/app/**/*.tsx"
---

# Client components and pages

- One component per file in `client/components/`, file named after the component in PascalCase (`MessagesList.tsx`), exported by name: `export const MessagesList = () => {}`.
- Components that use hooks, state, effects or browser APIs start with `'use client';`. Keep server components the default in `app/` when nothing interactive is needed.
- Components are presentational + composition. Data fetching and mutations live in contexts or hooks, consumed through `useX()`. Do not call `api` directly from a component unless it is a one-off form submit with no shared state.
- Props are typed with an inline interface above the component; callbacks are named `onX`.
- Styling is Tailwind utility classes. Shared class strings go in a `const` in the same file (or `components/<name>Styles.ts` when reused).
- Pages in `app/` compose providers + components and stay thin. Dynamic route params are a `Promise` read with `use(params)`.
- Render all states: loading, empty, error. Disable submit buttons while a request is in flight.
- Accessibility: labels for inputs, `role="alert"` for errors, buttons are `<button type="button">` unless submitting.
- Before using any Next.js API, check the version in `client/package.json` and read the matching guide in `client/node_modules/next/dist/docs/` if it exists: this Next.js can differ from what you remember.

Templates: `.claude/docs/client/components.md`.
