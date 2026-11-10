# API contract template (for `feature-planner`)

Fill this in the plan before any code is written. Server and client writers implement exactly this.

## Endpoints

| Method + path | Auth | Request body / params | Success | Errors |
|---------------|------|-----------------------|---------|--------|
| `POST /api/rooms` | no | `{ name: string }` (non-empty) | `201` `Room` | `400` name required |
| `GET /api/rooms` | no | none | `200` `Room[]` | none |
| `GET /api/rooms/:id` | no | `:id` uuid | `200` `Room` | `404` not found |
| `DELETE /api/rooms/:id` | no | `:id` | `204` | `404` not found |

## Types (shared shape)

```ts
interface Room { id: string; name: string }
interface Message { id: string; roomId: string; username: string; content: string; createdAt: string }
```

## Database

```
rooms(id uuid pk, name text not null)
messages(id uuid pk, room_id uuid fk -> rooms on delete cascade, username text, content text, created_at timestamp default now())
```

## Realtime (if any)

| Channel / room | Event | Payload | Emitted by | Handled by |
|----------------|-------|---------|------------|------------|
| `rooms` | `room-created` | `Room` | `createRoomService` | `RoomsContext` |
| `rooms` | `room-deleted` | `{ id }` | `deleteRoomService` | `RoomsContext` |

## Server files

- `features/rooms/rooms.{types,repository,service,controller,router}.ts`: list the functions per file.
- `db/db.ts`: tables above. `app.ts`: mount router.

## Client files

- `lib/types.ts`: new interfaces.
- `context/RoomsContext.tsx`: `rooms`, `createRoom`, `deleteRoom`.
- `components/`: `RoomsList`, `RoomItem`, `CreateRoomForm` with props.
- `app/page.tsx`: mounts `RoomsProvider`.

## Test cases

Server: service (happy path, not found), routes (400 validation), side effects (event emitted on success only).
Client: form submit, list empty/non-empty, delete action, event handler dedupes by id.

## Assumptions

Anything decided without asking (auth model, realtime provider, ownership, limits).
