# Fullstack Harness

Reusable Claude Code harness for monorepos shaped as `client/` (Next.js + React) and `server/` (Express + TypeScript + PostgreSQL/Supabase). Copy `.claude/` (which contains `docs/` and `scripts/`) and this file into a project root; nothing here is project-specific.

All Claude configuration lives in `.claude/`. Long reference material lives in `.claude/docs/` and is loaded on demand (see "Docs").

## Target project shape

```
<project>/
├── client/   Next.js 16 (App Router), React 19, Tailwind 4, axios
└── server/   Express 5, TypeScript, pg, Supabase, @hapi/boom
```

- **Server:** `src/features/<feature>/<feature>.{router,controller,service,repository,types}.ts`, plus `src/config/`, `src/db/`, `src/middlewares/`. Layered: router → controller → service → repository.
- **Client:** `app/` (routes), `components/`, `context/`, `hooks/`, `lib/` (`axios.ts`, `config.ts`, `types.ts`, `errors.ts`). Imports use the `@/` alias.

## Commands

Run inside the workspace you changed.

| Workspace | Install | Dev | Typecheck | Lint | Test |
|-----------|---------|-----|-----------|------|------|
| `server/` | `npm install` | `npm run dev` | `npm run typecheck` | `npm run lint` | `npm test` (`node:test` via `tsx`) |
| `client/` | `npm install` | `npm run dev` | `npm run typecheck` | `npm run lint` | `npm test` (Vitest + Testing Library) |

## Rules (loaded by file path)

Rules in `.claude/rules/` load automatically when a matching file is edited:

- `server-layers.md`, `server-db.md`, `server-errors-auth.md` for `server/src/**`
- `client-components.md`, `client-hooks.md`, `client-contexts.md`, `client-lib.md` for `client/**`
- `typescript-style.md` for every `*.ts` / `*.tsx`
- `tests.md` for test files

## Skills

| Skill | Use it to |
|-------|-----------|
| `/add-feature` | Orchestrate a full feature (plan → server → client → tests → review) |
| `/add-server-feature` | Add a layered server feature |
| `/add-client-feature` | Add a client feature (components + context + hooks) |
| `/add-component`, `/add-context`, `/add-hook` | Add one client building block |
| `/add-db-table` | Add a table, its `initDb` entry and a repository |
| `/add-realtime` | Add realtime events (Supabase Realtime or socket.io) |
| `/add-file-upload` | Add file uploads (multer + Supabase Storage) |
| `/add-auth` | Add Bearer auth on server and client |
| `/verify` | Run typecheck, lint and tests in both workspaces |

## Agents

Agents never call each other: the orchestrating skill runs them **one at a time, in order**.

1. `feature-planner`: read-only; produces the API contract, tables, files and test cases.
2. `server-writer`: writes only under `server/` (no tests).
3. `client-writer`: writes only under `client/` (no tests).
4. `test-writer`: writes only test files.
5. `code-reviewer`: read-only; ends with `APPROVED` or `CHANGES REQUIRED`.

## Docs (on-demand sub-skills)

`.claude/docs/` holds the detailed patterns and code templates. Skills, agents and rules point to specific files; read only what the task needs. Start from `.claude/docs/README.md` (the index). Do not read the whole folder up front.

## Conventions

- Everything written in this repo (code, comments, error messages, docs) is in English.
- Every behavior change ships with tests.
- Never read or edit `.env` files; update `.env.example` instead.
- Secrets stay on the server. Client env vars are `NEXT_PUBLIC_*` and public only.

## Before calling a task done

1. `npm run typecheck` passes in every touched workspace.
2. `npm run lint` passes.
3. `npm test` is green.
4. `code-reviewer` returned `APPROVED`.

Headless version of the whole flow: `./.claude/scripts/harness.sh "feature description"`.
