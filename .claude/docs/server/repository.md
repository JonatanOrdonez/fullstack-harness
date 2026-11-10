# Repository

Only layer with SQL. Parameterized queries, typed rows, camelCase aliases.

```ts
import { pool } from '../../db/db';
import { CreateMessageDTO, Message } from './chat.types';

const MESSAGE_COLUMNS =
  'id, room_id AS "roomId", username, content, created_at AS "createdAt"';

export const createMessageRepository = async (message: CreateMessageDTO): Promise<Message> => {
  const result = await pool.query<Message>(
    `INSERT INTO public.messages (room_id, username, content)
     VALUES ($1, $2, $3)
     RETURNING ${MESSAGE_COLUMNS}`,
    [message.roomId, message.username, message.content],
  );

  return result.rows[0];
};

export const getMessagesByRoomIdRepository = async (roomId: string): Promise<Message[]> => {
  const result = await pool.query<Message>(
    `SELECT ${MESSAGE_COLUMNS}
     FROM public.messages
     WHERE room_id = $1
     ORDER BY created_at ASC`,
    [roomId],
  );

  return result.rows;
};

export const getMessageByIdRepository = async (id: string): Promise<Message | undefined> => {
  const result = await pool.query<Message>(
    `SELECT ${MESSAGE_COLUMNS} FROM public.messages WHERE id = $1`,
    [id],
  );

  return result.rows[0];
};

export const deleteMessageRepository = async (id: string): Promise<boolean> => {
  const result = await pool.query('DELETE FROM public.messages WHERE id = $1', [id]);

  return (result.rowCount ?? 0) > 0;
};
```

## Rules

- `${CONSTANT}` interpolation is only for column lists you wrote; **values always go in `$n` params**.
- Single-row reads return `T | undefined` (`result.rows[0]`); the service decides what a miss means.
- Deletes return `boolean`.
- Dynamic `ORDER BY` or table names: map from an allow-list object, never from raw input.
- Optional values: `prompt.imageUrl ?? null`.
- User-scoped: include `WHERE user_id = $n` in every read/update/delete.

## PostGIS (geospatial)

```ts
const POINT_COLUMNS = 'id, name, color, ST_Y(geom::geometry) AS lat, ST_X(geom::geometry) AS lng';

// ST_MakePoint takes (lng, lat), in that order
await pool.query(
  `INSERT INTO public.points (name, color, geom)
   VALUES ($1, $2, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography)
   RETURNING ${POINT_COLUMNS}`,
  [point.name, point.color, point.lng, point.lat],
);

// Nearest point within N meters of a stored location
`SELECT p.id FROM public.points p
 JOIN public.user_coords u ON ST_DWithin(p.geom, u.coords, $2)
 WHERE u.id = $1
 ORDER BY ST_Distance(p.geom, u.coords) LIMIT 1`

// Polygon from [{lat, lng}, ...]: close the ring (first point repeated at the end)
// build WKT as 'POLYGON((lng lat, lng lat, ...))' from numbers you validated, or use ST_GeogFromText($1)
```

## Transactions

```ts
export const withTransaction = async <T>(fn: (client: PoolClient) => Promise<T>): Promise<T> => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
```
