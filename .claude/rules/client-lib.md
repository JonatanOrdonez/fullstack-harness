---
paths:
  - "client/lib/**/*.ts"
---

# Client lib

- `lib/config.ts` is the only file that reads `process.env`. Only `NEXT_PUBLIC_*` variables are available in the browser: `API_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SOCKET_URL`.
- `lib/axios.ts` exports one `api` instance (`baseURL: API_URL`). Auth is attached in a **request interceptor** (Bearer token from storage), not per call.
- `lib/types.ts` holds the shared domain interfaces mirroring the server's response shapes (dates arrive as ISO strings).
- `lib/errors.ts` exports `getErrorMessage(error: unknown): string` (axios response message → axios message → generic).
- `lib/supabase.ts` / `lib/socket.ts` export a single shared client instance with the publishable key / public URL only.
- `lib/authStorage.ts` wraps `localStorage` access for the session (key constant, getter, safe JSON parse).
- No React imports in `lib/`: it must be usable from hooks, contexts and tests.
- Never put server secrets here.

Templates: `.claude/docs/client/lib-axios-auth.md`.
