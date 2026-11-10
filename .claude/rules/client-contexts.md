---
paths:
  - "client/context/**/*.tsx"
---

# Client contexts

- One file per context: `<Name>Context.tsx` exporting `<Name>Provider` and the hook `use<Name>`. Always `'use client';`.
- The context value is typed with `<Name>ContextValue`; the context is `createContext<... | null>(null)`.
- The hook throws if the provider is missing: `throw new Error('useX must be used within an XProvider')`.
- The provider owns the state, loads initial data in a `useEffect` (define `onInit` inside and call it), and exposes async actions (`createX`, `deleteX`) that call the API and then update local state.
- Update state with functional setters (`setItems((prev) => ...)`). Make appends idempotent (check `id`) when realtime and HTTP responses can both deliver the same item.
- Realtime: subscribe in a `useEffect` and **always** clean up in the effect's return (`supabase.removeChannel` or `socket.off`/`disconnect`).
- Browser-only external state (`localStorage`) is read with `useSyncExternalStore` plus a server snapshot, never directly during render.
- Session-scoped providers are re-created per user with `key={user?.id ?? 'anonymous'}` so state resets on login/logout.
- Providers are mounted in the page or layout that needs them, as low in the tree as possible. Cross-cutting ones (auth, toasts) go in `app/layout.tsx`.
- Do not put pure UI state used by a single component in a context.

Templates: `.claude/docs/client/contexts.md`, `.claude/docs/client/realtime-subscription.md`.
