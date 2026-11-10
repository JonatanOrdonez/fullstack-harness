# Docs index

On-demand reference for skills, agents and rules. Read only the page the task needs.

## Server (`.claude/docs/server/`)

| Page | Read it when |
|------|--------------|
| `layers.md` | Adding any feature; shows the folder map and request flow |
| `router-controller.md` | Writing routes, input validation, status codes |
| `service.md` | Business rules, ownership, calling other services |
| `repository.md` | Writing SQL (CRUD, joins, PostGIS) |
| `db-init.md` | Adding tables, foreign keys, extensions |
| `errors-boom.md` | Choosing error statuses; the error middleware |
| `auth-middleware.md` | Bearer auth, Supabase Auth, user-scoped data |
| `file-upload.md` | multer + Supabase Storage |
| `realtime-supabase.md` | Server broadcasts through Supabase Realtime |
| `realtime-socketio.md` | socket.io server |
| `env-config.md` | `config/`, env vars, `app.ts` / `index.ts` bootstrap |
| `testing.md` | Server tests and tooling setup |

## Client (`.claude/docs/client/`)

| Page | Read it when |
|------|--------------|
| `components.md` | Writing components and pages |
| `contexts.md` | Shared state and API actions |
| `hooks.md` | Reusable logic |
| `lib-axios-auth.md` | `lib/` files, axios, auth session and `AuthContext` |
| `realtime-subscription.md` | Subscribing to Supabase or socket.io events |
| `file-upload.md` | Upload hook with validation and compression |
| `testing.md` | Client tests and tooling setup |

## Workflow (`.claude/docs/workflow/`)

| Page | Read it when |
|------|--------------|
| `api-contract-template.md` | Planning a feature |
| `review-checklist.md` | Reviewing changes |

Stack versions assumed: Node 22.3+ (needed by `node:test` module mocks), TypeScript 5, Express 5, Next.js 16, React 19, Tailwind 4, `pg` 8, `@supabase/supabase-js` 2, `@hapi/boom` 10.
