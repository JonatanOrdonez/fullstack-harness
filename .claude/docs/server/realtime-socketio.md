# Realtime on the server: socket.io

Use when you need client → server events, acknowledgements, rooms, or no Supabase. Dependencies: `socket.io` (server), `socket.io-client` (client).

## Bootstrap: `app.ts` / `index.ts` with an HTTP server

```ts
// index.ts
import { createServer } from 'node:http';
import app from './app';
import { initSocket } from './config/socket';

const httpServer = createServer(app);
initSocket(httpServer);

httpServer.listen(PORT, async () => {
  await initDb();
  console.log(`Server is running on http://localhost:${PORT}`);
});
```

## `config/socket.ts`

```ts
import { Server as HttpServer } from 'node:http';
import { Server } from 'socket.io';
import { CLIENT_ORIGIN } from './config';

let io: Server | null = null;

export const initSocket = (httpServer: HttpServer): Server => {
  io = new Server(httpServer, { cors: { origin: CLIENT_ORIGIN } });

  io.on('connection', (socket) => {
    socket.on('room:join', (roomId: string) => {
      socket.join(`room:${roomId}`);
    });

    socket.on('room:leave', (roomId: string) => {
      socket.leave(`room:${roomId}`);
    });
  });

  return io;
};

// Services emit through this; a missing server (tests) is a no-op
export const emit = (room: string, event: string, payload: object) => {
  io?.to(room).emit(event, payload);
};
```

Add `CLIENT_ORIGIN` to `config.ts` and `.env.example` (never `*` in production).

## Emit from the service

```ts
import { emit } from '../../config/socket';

export const createMessageService = async (message: CreateMessageDTO): Promise<Message> => {
  await getExistingRoom(message.roomId);
  const created = await createMessageRepository(message);
  emit(`room:${message.roomId}`, 'message-created', created);
  return created;
};
```

## Authenticated sockets

```ts
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token as string | undefined;
  const { data, error } = token ? await supabase.auth.getUser(token) : { data: null, error: true };

  if (error || !data?.user) {
    next(new Error('unauthorized'));
    return;
  }

  socket.data.userId = data.user.id;
  next();
});
```

Validate every client-sent payload in the handler (same rigor as a controller) and check the user may join the room before `socket.join`.

## Conventions

- Event names: `entity-action` for server → client (`message-created`), `scope:action` for client → server (`room:join`).
- Mutations still go through REST (controller → service → repository); sockets are for notifications, so tests and auth stay in one path.
- Handlers never run SQL; they call services.
