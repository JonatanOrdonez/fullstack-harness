---
name: add-realtime
description: Adds realtime events across server and client, using Supabase Realtime Broadcast (default) or socket.io. Use when changes must reach other connected users without a page refresh.
argument-hint: "<events and channel>"
disable-model-invocation: true
---

# Add realtime events

Argument: the events (for example `room-created, room-deleted on channel rooms`).

Choose the provider first, then load **only** that provider's docs:

| Provider | When | Server | Client |
|----------|------|--------|--------|
| Supabase Realtime Broadcast (default) | Supabase is already used; events are server-emitted notifications | `.claude/docs/server/realtime-supabase.md` | `.claude/docs/client/realtime-subscription.md` (Supabase section) |
| socket.io | Need client-to-server events, rooms/acks, or no Supabase | `.claude/docs/server/realtime-socketio.md` | `.claude/docs/client/realtime-subscription.md` (socket.io section) |

Steps:

1. Define the contract: channel/room name, event names (kebab-case, past tense: `room-created`), payload shape. Write it in the plan.
2. Server: emit **from the service** after the repository call succeeds. Emission is fire-and-forget: log failures, never throw.
3. Client: subscribe inside the context's `useEffect`, clean up on unmount, make handlers idempotent (the HTTP response and the event can both deliver the same item).
4. Tests: service emits the event on success and not on failure; the client handler updates state once even when the event arrives twice.
5. Run `npm run typecheck`, `npm run lint`, `npm test` in both workspaces.

Never expose secret keys to the client: the browser only uses the publishable key (Supabase) or the public server URL (socket.io).
