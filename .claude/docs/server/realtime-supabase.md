# Realtime on the server: Supabase Broadcast

The server publishes events; browsers subscribe with the publishable key (see `.claude/docs/client/realtime-subscription.md`). Uses the same `supabase` client created in `config/supabase.ts` with the secret key.

## Broadcast helper

```ts
import { supabase } from '../../config/supabase';

// Fire-and-forget: a failed broadcast must never fail the HTTP request
const broadcast = async (channelName: string, event: string, payload: object) => {
  const channel = supabase.channel(channelName);

  try {
    await channel.httpSend(event, payload);
  } catch (error) {
    console.error(`Failed to broadcast ${event}`, error);
  } finally {
    await supabase.removeChannel(channel);
  }
};
```

Put it in `src/config/realtime.ts` (or the feature's service) and reuse it.

## Emit from the service

```ts
export const createRoomService = async (room: CreateRoomDTO): Promise<Room> => {
  const newRoom = await createRoomRepository(room);
  broadcast('rooms', 'room-created', newRoom);   // not awaited on purpose
  return newRoom;
};

export const deleteRoomService = async (id: string): Promise<void> => {
  const deleted = await deleteRoomRepository(id);

  if (!deleted) {
    throw Boom.notFound('Room not found');
  }

  broadcast('rooms', 'room-deleted', { id });
};
```

## Contract conventions

- Channel per resource list (`rooms`) or per entity (`room:<id>` for its messages).
- Event names: kebab-case, past tense: `room-created`, `message-created`.
- Payload equals the REST response shape for that resource (so the client can reuse its types), or `{ id }` for deletions.
- Emit only after the database write succeeded.
- The sender also gets the REST response; clients must dedupe by `id`.

## Private channels

Broadcast on public channels is readable by anyone with the publishable key. For per-user or per-room privacy, use private channels with Realtime authorization policies, or include only ids and let the client refetch through the authenticated REST API.
