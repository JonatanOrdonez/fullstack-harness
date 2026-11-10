# Config, env vars and bootstrap

## `config/config.ts`: the only reader of `process.env`

```ts
import dotenv from 'dotenv';

dotenv.config();

export const PORT = Number(process.env.PORT || 3000);

export const DB_HOST = process.env.DB_HOST;
export const DB_PORT = Number(process.env.DB_PORT || 6543);
export const DB_NAME = process.env.DB_NAME;
export const DB_USER = process.env.DB_USER;
export const DB_PASSWORD = process.env.DB_PASSWORD;

export const SUPABASE_URL = process.env.SUPABASE_URL || '';
export const SUPABASE_SECRET_KEY = process.env.SUPABASE_SECRET_KEY || '';

// Feature-specific examples
export const IMAGES_BUCKET = process.env.IMAGES_BUCKET || 'images';
export const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
export const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || 'http://localhost:3001';
```

Required secrets without a safe default should fail fast: throw at startup if empty (for example `if (!SUPABASE_URL) throw new Error('SUPABASE_URL is required')`) in the module that needs them.

## Third-party clients (`config/<name>.ts`)

```ts
// supabase.ts
import { createClient } from '@supabase/supabase-js';
import { SUPABASE_URL, SUPABASE_SECRET_KEY } from './config';

export const supabase = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);

// groq.ts
import Groq from 'groq-sdk';
import { GROQ_API_KEY } from './config';

export const groq = new Groq({ apiKey: GROQ_API_KEY });
```

## `.env.example` (committed, placeholders only)

```
PORT=3000

# Database
DB_HOST=
DB_PORT=
DB_NAME=
DB_USER=
DB_PASSWORD=

# Supabase
SUPABASE_URL=
SUPABASE_SECRET_KEY=
```

Every new variable is added to `config.ts` **and** `.env.example`. Never read or edit `.env`.

## `app.ts` and `index.ts`

Split them so tests can import the app without opening a port:

```ts
// app.ts
import cors from 'cors';
import express, { Router } from 'express';
import { errorHandler } from './middlewares/errorMiddleware';
import roomsRouter from './features/rooms/rooms.router';

const app = express();
app.use(cors());
app.use(express.json());

const apiRouter = Router();
app.use('/api', apiRouter);

apiRouter.get('/', (_req, res) => {
  res.status(200).send('Hello, world!');
});

apiRouter.use('/', roomsRouter);

app.use(errorHandler);

export default app;
```

```ts
// index.ts
import app from './app';
import { PORT } from './config/config';
import { initDb } from './db/db';

app.listen(PORT, async () => {
  await initDb();
  console.log(`Server is running on http://localhost:${PORT}`);
});
```

## `package.json` scripts (server)

```json
{
  "dev": "tsx watch src/index.ts",
  "build": "tsc",
  "start": "node dist/index.js",
  "typecheck": "tsc --noEmit",
  "lint": "eslint .",
  "lint:fix": "eslint . --fix",
  "test": "node --import tsx --experimental-test-module-mocks --test \"test/**/*.test.ts\""
}
```

## ESLint (server)

Flat config with `@eslint/js`, `typescript-eslint` recommended and `@stylistic`: `indent 2`, `quotes single`, `semi always`, `comma-dangle always-multiline`, `arrow-parens always`, `no-console warn`, unused vars error with `argsIgnorePattern: '^_'`; ignore `dist/` and `node_modules/`.
