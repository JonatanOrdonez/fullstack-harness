# Review checklist (for `code-reviewer`)

Mark each item pass / fail / not applicable. Every fail is a blocker with `file:line`.

## Server

- [ ] Five-file feature structure; imports only go router → controller → service → repository.
- [ ] No SQL outside repositories; no `req`/`res` in services; no business rules in controllers.
- [ ] All SQL parameterized; no user input interpolated into queries.
- [ ] Controller validates type, shape and ranges; throws `Boom.badRequest`.
- [ ] Correct status codes (201 create, 200 read, 204 delete) and Boom statuses.
- [ ] User-scoped data filters by `user_id`; foreign resources return 404.
- [ ] Protected routes pass `authMiddleware` per route (no `router.use(authMiddleware)` in a router mounted at `/`); handlers use `getUserFromRequest`.
- [ ] Uploads: auth before multer, MIME allow-list, size limit, per-user path; client-sent URLs validated.
- [ ] Realtime emitted after a successful write, never thrown into the request.
- [ ] `initDb` additions are idempotent (`IF NOT EXISTS`) and do not drop or alter existing tables.
- [ ] Env vars only read in `config/config.ts`; `.env.example` updated; `.env` untouched.
- [ ] `errorHandler` is registered after all routers.

## Client

- [ ] One component per file, named export, `'use client'` only where needed.
- [ ] Data and mutations live in contexts/hooks; components render and compose.
- [ ] Context hook throws outside its provider; actions update state with functional setters.
- [ ] Appends from realtime/HTTP are idempotent by `id`.
- [ ] Every subscription, timer, listener and object URL is cleaned up.
- [ ] Loading, empty and error states exist; submit buttons disabled in flight; errors use `role="alert"`.
- [ ] `api` used through `@/lib/axios`; auth via interceptor; errors via `getErrorMessage`.
- [ ] No secrets in the client; only `NEXT_PUBLIC_*` variables; `lib/config.ts` is the only env reader.
- [ ] Accessible labels on inputs and buttons.

## Tests

- [ ] Happy path, validation errors, not found, ownership/unauthorized, side effects.
- [ ] Expected values written by hand; no weakened assertions to hide a bug.
- [ ] No `any`, `@ts-ignore`, `.only`, or skipped tests without a reason.

## General

- [ ] No `any`, no `@ts-ignore`, no leftover `console.log`.
- [ ] Everything in English (code, comments, messages).
- [ ] `typecheck`, `lint` and `test` pass in every touched workspace.
- [ ] Nothing outside the plan's scope was added.
