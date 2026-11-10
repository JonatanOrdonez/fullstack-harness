# Database init

`src/db/db.ts` exports the pool and an idempotent `initDb()` run once at startup.

```ts
import { Pool } from 'pg';
import { DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, DB_USER } from '../config/config';

export const pool = new Pool({
  host: DB_HOST,
  port: DB_PORT,
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
});

export const initDb = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS public.rooms (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name TEXT NOT NULL
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS public.messages (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
      username TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT now()
    );
  `);
};
```

## Conventions

- Create parents before children (foreign keys).
- `CASCADE` on delete when the child is meaningless without the parent.
- User-scoped tables: `user_id UUID NOT NULL` (Supabase Auth user id). Add an index when queried often: `CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON public.conversations(user_id);`
- Enums as `TEXT` with a `CHECK` constraint: `role TEXT NOT NULL CHECK (role IN ('user', 'assistant'))`.
- Optional columns are nullable (`image_url TEXT`), mapped to `string | null` in types.
- Seed data uses `INSERT ... ON CONFLICT (id) DO NOTHING`.
- `initDb()` only ever *adds*. Changing an existing table needs a written migration that the user reviews and runs; never `DROP` here.

## PostGIS

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS public.points (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#6366f1',
  geom GEOGRAPHY(POINT, 4326) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_points_geom ON public.points USING GIST (geom);
```

Use `GEOGRAPHY(POLYGON, 4326)` for areas. SRID 4326 = WGS84 lat/lng.

## Connection notes

Supabase pooler connections use port `6543` (transaction mode). Keep one pool per process and never create pools inside request handlers.

## Bootstrap

In `index.ts`:

```ts
app.listen(PORT, async () => {
  await initDb();
  await initStorage(); // only when uploads exist
  console.log(`Server is running on http://localhost:${PORT}`);
});
```
