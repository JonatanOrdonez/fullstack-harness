---
paths:
  - "server/src/db/**/*.ts"
  - "server/src/config/**/*.ts"
  - "server/src/**/*.repository.ts"
---

# Server database and config

- One shared `pool` (`pg.Pool`) exported from `src/db/db.ts`. Repositories import it; nothing else creates pools.
- Schema lives in `initDb()` as idempotent statements: `CREATE EXTENSION IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS public.<table>`. Never drop tables there.
- Primary keys are `UUID PRIMARY KEY DEFAULT gen_random_uuid()`. Timestamps are `created_at TIMESTAMP NOT NULL DEFAULT now()`. Foreign keys declare `ON DELETE CASCADE` when the child has no meaning without the parent.
- Every query is parameterized. Column lists that repeat go in a constant (`const POINT_COLUMNS = '...'`).
- Delete repositories return `boolean` (`rowCount > 0`) so the service can raise `404`.
- Environment access happens only in `src/config/config.ts` (loads `dotenv`, exports typed constants with defaults). Other modules import the constants, never `process.env`.
- Third-party clients (`supabase`, `groq`, ...) are created once in `src/config/<name>.ts`.
- Adding or renaming an env var means updating `server/.env.example` too. Never read or edit `.env`.

Templates: `.claude/docs/server/db-init.md`, `.claude/docs/server/repository.md`, `.claude/docs/server/env-config.md`.
