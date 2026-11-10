---
name: add-auth
description: Adds Bearer-token authentication: Supabase Auth routes and middleware on the server, AuthContext with stored session and axios interceptor on the client. Use when routes must be user-scoped.
---

# Add authentication

1. Read `.claude/docs/server/auth-middleware.md` (register/login services, `authMiddleware`, `getUserFromRequest`, Express type augmentation) and `.claude/docs/client/lib-axios-auth.md` (session storage, interceptor, `AuthContext`).
2. Server:
   - `features/auth/` with the usual layers (`register`, `login`), mounted at `/api/auth`.
   - `middlewares/authMiddleware.ts`; apply it **per route** (`router.get('/x', authMiddleware, handler)`). Never `router.use(authMiddleware)` in a router mounted at `/`: it would make later public routers return 401.
   - User-scoped tables get a `user_id` column; repositories filter by it.
3. Client:
   - `lib/authStorage.ts`, interceptor in `lib/axios.ts`, `context/AuthContext.tsx` (`login`, `register`, `logout`, `isReady`), a login page, and `key={user?.id ?? 'anonymous'}` on session-scoped providers.
   - Handle email-confirmation mode: register may return an empty token (no session yet).
4. Tests: missing/malformed header → 401, invalid token → 401, other user's resource → 404, login stores the session, logout clears it.
5. Run `npm run typecheck`, `npm run lint`, `npm test` in both workspaces.
