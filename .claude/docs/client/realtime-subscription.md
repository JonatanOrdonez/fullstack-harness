# Realtime subscriptions on the client

Subscribe inside the context's `useEffect`, always unsubscribe in the cleanup, and make state updates idempotent.

## Supabase Broadcast

`lib/supabase.ts` (publishable key only):

```ts
import { createClient } from '@supabase/supabase-js';
import { SUPABASE_PUBLISHABLE_KEY, SUPABASE_URL } from '@/lib/config';

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
```

In the provider:

```tsx
useEffect(() => {
  const roomsChannel = supabase
    .channel('rooms')
    .on('broadcast', { event: 'room-created' }, ({ payload }) => {
      setRooms((prev) => appendRoom(prev, payload as Room));
    })
    .on('broadcast', { event: 'room-deleted' }, ({ payload }) => {
      setRooms((prev) => prev.filter((room) => room.id !== (payload as { id: string }).id));
    })
    .subscribe();

  const onInit = async () => {
    const res = await api.get<Room[]>('/rooms');
    // Merge instead of replace: an event may have arrived before the HTTP response
    setRooms((prev) => res.data.reduce(appendRoom, prev));
  };

  onInit();

  return () => {
    supabase.removeChannel(roomsChannel);
  };
}, []);
```

Per-entity channel: `supabase.channel(\`room:${roomId}\`)` with `[roomId]` in the dependency array.

## socket.io

`lib/socket.ts`:

```ts
import { io } from 'socket.io-client';
import { SOCKET_URL } from '@/lib/config';

// autoConnect false: the provider connects when it mounts
export const socket = io(SOCKET_URL, { autoConnect: false });
```

In the provider:

```tsx
useEffect(() => {
  const onMessage = (message: Message) => setMessages((prev) => appendById(prev, message));

  socket.connect();
  socket.emit('room:join', roomId);
  socket.on('message-created', onMessage);

  return () => {
    socket.emit('room:leave', roomId);
    socket.off('message-created', onMessage);
    socket.disconnect();
  };
}, [roomId]);
```

Authenticated sockets: `socket.auth = { token: user.token };` before `connect()`.

## Rules

- The same item can arrive from the HTTP response and from the event: dedupe by `id` (`appendById`).
- Never forget the cleanup; a missing `removeChannel` / `off` duplicates handlers on every re-mount.
- Merge the initial fetch with events already received (see `reduce(appendRoom, prev)`).
- Event name and payload shape come from the plan's contract; reuse `lib/types.ts` interfaces.
- Connection state (`connected`, `reconnecting`) can be exposed in the context when the UI needs it.
- Test: simulate the event twice and assert one item; unmount and assert cleanup (see `testing.md`).
