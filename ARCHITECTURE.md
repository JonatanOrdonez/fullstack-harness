# Architecture

How the pieces of this harness fit together. For quick start see `README.md`; for the rules Claude reads on every task see `CLAUDE.md`.

## The idea in one paragraph

The harness turns "build me a feature" into a fixed loop: **plan → server → client → tests → review → verify**. Each step is a specialised **agent** with limited tools. A **skill** (or the headless script) is the orchestrator that runs the agents in order. **Rules** and **docs** tell the agents how the code must look. **Hooks** and **permissions** enforce the parts that must never depend on an agent's good behaviour (secrets, lint, tests).

```
                         you
                          │  /add-feature "rooms count"        ./harness.sh "rooms count"
                          ▼                                              │ (headless, CI)
              ┌───────────────────────┐                                  │
              │   SKILL (orchestrator)│◄─────────────────────────────────┘ same flow,
              │   .claude/skills/     │                                    driven by a script
              └───────────┬───────────┘
        one at a time, in order; each agent has no memory of the others
                          │
   ┌──────────┬───────────┼────────────┬──────────────┬──────────────┐
   ▼          ▼           ▼            ▼              ▼              
 planner → server-writer → client-writer → test-writer → code-reviewer
 (opus)     (sonnet)       (sonnet)        (sonnet)       (opus)
 read-only  server/ only   client/ only    tests only     read-only
   │            │              │              │              │
   └────────────┴──────┬───────┴──────────────┴──────────────┘
                       │ all of them read
         ┌─────────────┼───────────────────────┐
         ▼             ▼                       ▼
     CLAUDE.md    .claude/rules/          .claude/docs/
     (always)     (by file path)          (on demand: templates)
                       │
        enforced around every tool call by
                       ▼
        .claude/settings.json ──► permissions (allow / deny)
                              └─► hooks (PreToolUse, PostToolUse, Stop)
```

## Folder map

```
fullstack-harness/
├── CLAUDE.md                  entry point: stack, commands, conventions, "definition of done"
├── README.md                  how to install and use
├── ARCHITECTURE.md            this file
└── .claude/
    ├── settings.json          permissions + hook registration
    ├── agents/                5 agents (planner, server-writer, client-writer, test-writer, code-reviewer)
    ├── skills/                11 slash commands (orchestrators and single-purpose builders)
    ├── rules/                 9 path-scoped convention files, loaded automatically
    ├── docs/                  on-demand reference: patterns and code templates
    │   ├── server/            layers, repository, auth, uploads, realtime, testing...
    │   ├── client/            components, contexts, hooks, axios/auth, testing...
    │   └── workflow/          api-contract-template.md, review-checklist.md
    └── scripts/
        ├── harness.sh         headless version of the whole flow
        └── hooks/             block-env.sh, post-edit.sh, stop.sh
```

## The five layers and what each one is for

| Layer | Loaded when | Purpose | Can the agent ignore it? |
|-------|-------------|---------|--------------------------|
| `CLAUDE.md` | every session | Stack, commands, conventions, definition of done | Yes (it is guidance) |
| `rules/` | when a file matching its `paths:` is edited | Short, strict conventions for that kind of file | Yes (guidance, but loaded exactly when relevant) |
| `docs/` | only when a skill, agent or rule points to a page | Long templates and examples, kept out of context until needed | Yes |
| `agents/` | when the orchestrator launches them | Role, process, tool limits, required report format | Tool limits: no. Process: yes |
| `settings.json` + hooks | on every tool call | Hard guarantees: secrets, lint, tests | **No** |

The split is deliberate: anything that must hold goes in permissions/hooks; anything that is style or pattern goes in rules/docs; long material stays in docs so the context stays small.

## Agents

Agents never call each other: a subagent cannot launch another one, so the orchestrator passes everything each agent needs (plan, previous report).

| Agent | Model | Tools | Writes to | Reads first | Ends with |
|-------|-------|-------|-----------|-------------|-----------|
| `feature-planner` | opus | Read, Grep, Glob | nothing | `CLAUDE.md`, `docs/README.md`, `docs/workflow/api-contract-template.md`, rules, existing features | Plan: API contract, tables, files, test cases, assumptions |
| `server-writer` | sonnet | + Edit, Write, Bash | `server/` (no tests) | rules `server-*`, `docs/server/*`, one existing feature | Files, route list, env vars, error cases |
| `client-writer` | sonnet | + Edit, Write, Bash | `client/` (no tests) | rules `client-*`, `docs/client/*`, server-writer's report | Files, context values, props, server mismatches |
| `test-writer` | sonnet | + Edit, Write, Bash | test files and test config only | `rules/tests.md`, `docs/*/testing.md`, the code under test | Tests written, pass/fail, real bugs found (never "fixes" them) |
| `code-reviewer` | opus | Read, Grep, Glob, Bash | nothing | `docs/workflow/review-checklist.md`, rules, the diff | Blockers, suggestions, checks, `APPROVED` / `CHANGES REQUIRED` |

Handoffs: planner → (plan) → server-writer → (plan + server report) → client-writer → (plan + both reports) → test-writer → (plan's test cases + reports) → code-reviewer.

## Skills

Two kinds:

**Orchestrators** run agents (`disable-model-invocation: true`, so they only run when you type them):

| Skill | Flow |
|-------|------|
| `/add-feature` | planner → server-writer → client-writer → test-writer → code-reviewer, then `/verify`. Loops: test bugs go back to the owner agent (max 2 rounds); `CHANGES REQUIRED` goes back to the owner (repeat review) |
| `/add-server-feature` | planner → server-writer → test-writer (server) → code-reviewer |
| `/add-client-feature` | planner (must confirm the endpoints exist) → client-writer → test-writer (client) → code-reviewer |

**Builders** do one narrow job by following docs directly (no agents): `/add-component`, `/add-context`, `/add-hook`, `/add-db-table`. Large cross-cutting ones (`/add-auth`, `/add-file-upload`, `/add-realtime`) are also manual-only and describe a slice that the writers follow.

`/verify` runs typecheck, lint and tests per workspace and reports a table; it never edits code.

## Rules (path-scoped)

Each rule has `paths:` frontmatter and loads when Claude touches a matching file:

| Rule | Applies to |
|------|-----------|
| `server-layers.md` | `server/src/features/**` — router → controller → service → repository |
| `server-db.md` | `server/src/db`, `config`, `*.repository.ts` — pool, idempotent `initDb`, parameterized SQL |
| `server-errors-auth.md` | middlewares, controllers, services — Boom errors, per-route `authMiddleware`, uploads, ownership |
| `client-components.md` / `client-hooks.md` / `client-contexts.md` / `client-lib.md` | the matching `client/` folders |
| `typescript-style.md` | every `.ts` / `.tsx` |
| `tests.md` | test files |

Rules link to the doc page with the full template (`Templates: .claude/docs/...`), which is how guidance and detail stay separate.

## Docs

A pull-based library. `docs/README.md` is the index. Skills and agents name the exact page to read ("read `docs/server/repository.md`"), so nothing is loaded up front. `docs/workflow/api-contract-template.md` is the shape of the planner's output; `docs/workflow/review-checklist.md` is the reviewer's pass/fail list.

## Hooks and permissions (the hard guarantees)

Registered in `.claude/settings.json`:

| Event | Script | What it does |
|-------|--------|--------------|
| `PreToolUse` (Bash, Read, Edit, Write, Grep, Glob) | `block-env.sh` | Blocks any call whose command or path mentions a real `.env` (`.env.example` allowed). Catches `head .env`, `grep . .env`, `rm -fr` variants that plain deny rules miss |
| `PostToolUse` (Edit, Write) | `post-edit.sh` | Runs ESLint on **only the edited file**. No full typecheck here: writers build bottom-up, so intermediate states do not compile |
| `Stop` | `stop.sh` | Typecheck, lint and tests on workspaces with uncommitted changes. Exit 2 makes Claude keep working. On the second stop (loop guard) it lets Claude stop but prints a loud warning. A missing script is a warning, not silence |

`permissions.allow` pre-approves read-only and check commands (`npm test`, `npm run lint`, `npx tsc`, `git status/diff/log`...). `permissions.deny` blocks `.env` reads/edits, `rm -rf`, `git push`.

```
agent calls a tool
   │
   ├─► PreToolUse  block-env.sh ──(mentions .env?)──► blocked, reason sent back
   │
   ├─► permissions allow/deny ──► run, or ask, or refuse
   │
   ├─► tool runs
   │
   ├─► PostToolUse post-edit.sh ──(eslint fails?)──► exit 2: output sent back, agent fixes
   │
   └─► (turn ends) Stop stop.sh ──(checks fail?)──► exit 2: agent keeps working
```

## The headless flow (`harness.sh`)

Same loop as `/add-feature`, driven from the shell with one `claude -p` per step. Use it for CI or unattended batches; day to day, use the skill.

```
1  plan        feature-planner                      → plan.md
2  implement   server-writer, then client-writer
3  tests       test-writer  → ends with "BUGS: none | <list>"
3b fix bugs    (only if BUGS ≠ none) owner agents fix them
┌─ loop up to MAX_ROUNDS (default 3) ──────────────────────────────┐
4  verify      script: npm install + typecheck/lint/test, per changed workspace
4  review      code-reviewer, must end with "VERDICT: APPROVED|CHANGES REQUIRED"
4b fix         owner agents fix the blockers, then loop
└───────────────────────────────────────────────────────────────────┘
5  verify      final check; exit 0 only if APPROVED **and** checks pass
```

Design decisions worth knowing:

- **The script owns verification.** `verify()` runs the checks itself and hands the summary (`PASS / FAIL / MISSING` per step, plus the head of each failure) to the reviewer. The reviewer never depends on its own ability to run commands.
- **Only changed workspaces are verified** (`git status`; staged-only files do not count), so an untouched client without a `test` script cannot fail a server-only feature.
- **The verdict is a machine-readable last line.** Missing line = not approved.
- **Review is read-only** (`--disallowedTools Edit Write NotebookEdit`).
- **`HARNESS_HEADLESS=1`** turns the Stop hook into a no-op, because the script runs its own verify.
- **Permissions are passed explicitly** with `--allowedTools` as a bash **array** (each pattern contains spaces; an unquoted string would split into invalid rules). Compound commands need every part allowed, which is why `echo`, `cd`, `ls`, `head`, `tail` are in the list.
- **Denials are never silent.** Every `claude` call goes through `run_claude`, which uses JSON output, prints the agent's answer as usual and echoes each denied tool call as `DENIED> ...`; a summary is printed at the end so the allowlist can be fixed with evidence instead of guesses.
- **Denied commands do not stop an agent**: it skips them, finishes what it can and lists them in its answer.
- **Scope policy for the reviewer:** a change outside the plan is a blocker, except a minimal, behaviour-preserving fix to a pre-existing error that blocks a required check (reported as a suggestion). This avoids review loops that never converge.
- **Logs are kept on failure** (the temp directory path is printed), removed on success.

Headless limits: nobody can answer prompts; the folder must be trusted once (`claude` interactively in the project) or `permissions.allow` is ignored; edits to `.claude/` itself are refused as sensitive files, which is the intended behaviour.

## How a feature moves through the system (example)

`/add-feature rooms count`:

1. The skill launches `feature-planner`. It reads `CLAUDE.md`, the docs index and the API contract template, scans `server/src/features/` and `client/context/`, and returns a plan (endpoint, files, test cases).
2. `server-writer` receives the plan. Editing `server/src/features/chat/*.ts` loads `server-layers.md`, `server-db.md`, `server-errors-auth.md` and `typescript-style.md`. Each edit triggers `post-edit.sh` (lint of that file). It reports routes and error cases.
3. `client-writer` receives the plan plus the server report and builds types → context → components, under the `client-*` rules.
4. `test-writer` receives the plan's test cases and both reports, follows `rules/tests.md` and `docs/*/testing.md`, runs the tests and reports real bugs without bending assertions.
5. `code-reviewer` checks the diff against `review-checklist.md`, runs the checks and answers `APPROVED` or `CHANGES REQUIRED`. Blockers go back to the owner agent; the reviewer runs again (max 2 rounds).
6. `/verify` confirms typecheck, lint and tests per workspace. When Claude finishes, `stop.sh` runs once more as a safety net.

## Where to change what

| I want to... | Edit |
|--------------|------|
| Change a convention ("services must not...") | the matching file in `rules/`, and its template in `docs/` |
| Add a new code pattern or template | a page in `docs/`, then link it from the rule/skill/agent that needs it and from `docs/README.md` |
| Change what an agent may touch or its process | `agents/<name>.md` (`tools:`, `model:`, limits) |
| Add a workflow | a new `skills/<name>/SKILL.md` (use `disable-model-invocation: true` for orchestrators) |
| Block or allow a command | `settings.json` (`permissions`), or a hook script for pattern-based blocking |
| Change the definition of done | `CLAUDE.md` "Before calling a task done", `hooks/stop.sh`, `skills/verify`, `scripts/harness.sh` verify |
| Change the stack versions | `CLAUDE.md`, `docs/README.md` (single list), and the docs that cite versions |

## Known limits

- **Consistency is by convention.** The same rules appear in `rules/`, `docs/` and `review-checklist.md`; nothing automatically detects drift between them.
- **The harness is opinionated.** It assumes `client/` + `server/`, Next.js, Express with layers, PostgreSQL/Supabase, Boom errors. Other stacks need rule and doc changes.
- **`mock.module` testing** (Node 22.3+, experimental) is what server service tests rely on.
- **Stop-hook loop guard** means a task can end with failing checks after one retry; the printed warning is the only signal.
- **Permissions in `allow` are broad by nature:** `npm run`/`npx tsc`/`npx tsx` execute project code. Fine for a dev harness, worth remembering on untrusted repos.
