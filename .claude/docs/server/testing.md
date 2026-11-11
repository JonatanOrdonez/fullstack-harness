# Server testing

Stack: `node:test` + `node:assert/strict`, run with `tsx`. Optional: `supertest` for HTTP.

## Setup (done by `test-writer` if missing)

```bash
cd server && npm install -D supertest @types/supertest
```

Scripts: see `env-config.md` (`test` uses `--import tsx --experimental-test-module-mocks`, which needs Node 22.3+). `typecheck` is `tsc --noEmit`; typecheck the tests with a separate `tsconfig.test.json` (`extends` the base, `include` `src` and `test`, `rootDir: "."`, `noEmit`) and point the `typecheck` script at it (`tsc --noEmit -p tsconfig.test.json`). Do NOT add `test/**/*` or change `rootDir` in `tsconfig.json`: that moves the build output (`dist/src/...`) and breaks the `start` script.

`tsconfig.test.json` (the build config stays untouched, so `npm run build` still emits `dist/index.js`, next to `src`'s layout, never `dist/src/`):

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "rootDir": ".", "noEmit": true },
  "include": ["src/**/*", "test/**/*"]
}
```

Layout: `server/test/<feature>/<feature>.service.test.ts`, `<feature>.routes.test.ts`, `<feature>.repository.integration.test.ts`.

## Service test (repository mocked)

```ts
import assert from 'node:assert/strict';
import { beforeEach, mock, test } from 'node:test';

const getRoomByIdRepository = mock.fn();
const createMessageRepository = mock.fn();

mock.module('../../src/features/chat/chat.repository', {
  namedExports: { getRoomByIdRepository, createMessageRepository },
});

const { createMessageService } = await import('../../src/features/chat/chat.service');

beforeEach(() => {
  getRoomByIdRepository.mock.resetCalls();
  createMessageRepository.mock.resetCalls();
});

test('createMessageService throws 404 when the room does not exist', async () => {
  getRoomByIdRepository.mock.mockImplementation(async () => undefined);

  await assert.rejects(
    () => createMessageService({ roomId: 'r1', username: 'ana', content: 'hi' }),
    (error: { output?: { statusCode: number } }) => error.output?.statusCode === 404,
  );
});

test('createMessageService stores the message when the room exists', async () => {
  getRoomByIdRepository.mock.mockImplementation(async () => ({ id: 'r1', name: 'general' }));
  createMessageRepository.mock.mockImplementation(async () => ({ id: 'm1', content: 'hi' }));

  const message = await createMessageService({ roomId: 'r1', username: 'ana', content: 'hi' });

  assert.equal(message.id, 'm1');
});
```

Import the module under test **after** `mock.module` (dynamic `await import`). Mock the whole module the service imports (repository, `config/supabase`, `config/socket`).

## Route test (supertest)

```ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import request from 'supertest';
import app from '../../src/app';

test('POST /api/rooms returns 400 when the name is missing', async () => {
  const res = await request(app).post('/api/rooms').send({});

  assert.equal(res.status, 400);
});
```

Pitfall (CommonJS projects, no `"type": "module"`): with `module: nodenext`, `(await import('../../src/app')).default` can be typed as the whole module (TS2740 "missing properties from type Express"). Unwrap it once in a helper: `const mod = await import('../../src/app'); const app = ((mod.default as unknown as { default?: Express }).default ?? mod.default) as Express;`. Alternatively set `"type": "module"`.

Validation and auth failures (400/401) are testable without a database because they fail before the repository. For success paths, mock the service module like above.

## Auth tests

- No header → 401. `Authorization: Basic x` → 401.
- Mock `config/supabase` (`auth.getUser`) to return an error → 401; to return a user → handler runs with `req.user`.
- Other user's resource → 404.

## Repository integration tests

Need a real database; skip when it is not configured:

```ts
import { test } from 'node:test';

const hasDb = Boolean(process.env.DB_HOST);

test('createRoomRepository inserts a room', { skip: !hasDb }, async () => {
  // call repository, assert returned row, delete it afterwards
});
```

Use a dedicated test schema or database; never run them against production data.

## What to cover per feature

Happy path, each validation error, not found, ownership/unauthorized, side effects (broadcast emitted on success and not on failure, external API failure → 502).
