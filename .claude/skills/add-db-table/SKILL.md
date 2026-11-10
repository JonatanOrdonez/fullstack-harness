---
name: add-db-table
description: Adds a PostgreSQL table to server/src/db/db.ts (idempotent initDb) and the repository functions that use it. Use when a feature needs persistent data.
argument-hint: "<table and columns>"
---

# Add a database table

Argument: the table and its columns (for example `messages(room_id, username, content)`).

1. Read `.claude/rules/server-db.md` and `.claude/docs/server/db-init.md` (table templates, PostGIS example, foreign keys).
2. Read `.claude/docs/server/repository.md` for the repository template.
3. Add the types to `<feature>.types.ts` (entity + `Create*DTO`).
4. Append the `CREATE TABLE IF NOT EXISTS public.<table>` statement to `initDb()` after the tables it references. Never drop or alter existing tables there; for changes to existing tables, write the migration SQL, show it to the user and ask before running anything.
5. Add repository functions: create (`RETURNING`), list, get by id (and by owner when user-scoped), delete (returns `boolean`).
6. Add repository integration tests (skipped when `DB_HOST` is unset) per `.claude/docs/server/testing.md`.
7. Run `npm run typecheck` and `npm run lint` in `server/`.
