---
paths:
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "server/test/**/*.ts"
  - "client/test/**/*.{ts,tsx}"
---

# Tests

**Server** (`server/test/<feature>/*.test.ts`): `node:test` + `node:assert/strict`, run with `tsx` (`npm test`).
- Service tests replace the repository with `mock.module` (run with `--experimental-test-module-mocks`) and assert behavior: success value, `Boom` status codes, and that ownership is enforced.
- Route tests use `supertest` against the exported `app` (split `app.ts` from `index.ts` so importing the app does not listen).
- Repository tests need a real database; keep them separate (`*.integration.test.ts`) and skip when `DB_HOST` is unset.

**Client** (`client/test/**` or next to the file): Vitest + Testing Library (`@testing-library/react`, `user-event`), jsdom environment.
- Test components through what the user sees and does (`getByRole`, `userEvent.click`), not through implementation details.
- Wrap components in the real provider; mock `@/lib/axios` (`vi.mock`) at the network boundary.
- Hooks: `renderHook`. Assert cleanup (for example that the channel is removed on unmount).

**Both**
- Names describe behavior: `test('createRoom throws 404 when the room does not exist', ...)`.
- Each feature covers: happy path, validation errors, not found, and unauthorized/ownership when applicable.
- Expected values are written by hand, never computed with the code under test.
- One main assertion per test. No `any`, no `@ts-ignore`.
- If a test fails because of a real bug, do not weaken the test: report the bug.

Templates: `.claude/docs/server/testing.md`, `.claude/docs/client/testing.md`.
