# Contexts

A context = state + API actions for one domain, exposed through a `useX` hook.

## Template

```tsx
'use client';

import { createContext, useContext, useEffect, useState } from 'react';
import { api } from '@/lib/axios';
import { Room } from '@/lib/types';

interface RoomsContextValue {
  rooms: Room[];
  createRoom: (name: string) => Promise<void>;
  deleteRoom: (id: string) => Promise<void>;
}

const RoomsContext = createContext<RoomsContextValue | null>(null);

export const RoomsProvider = ({ children }: { children: React.ReactNode }) => {
  const [rooms, setRooms] = useState<Room[]>([]);

  useEffect(() => {
    const onInit = async () => {
      const res = await api.get<Room[]>('/rooms');
      setRooms(res.data);
    };

    onInit();
  }, []);

  const createRoom = async (name: string) => {
    const res = await api.post<Room>('/rooms', { name });
    setRooms((prev) => [...prev, res.data]);
  };

  const deleteRoom = async (id: string) => {
    await api.delete(`/rooms/${id}`);
    setRooms((prev) => prev.filter((room) => room.id !== id));
  };

  return (
    <RoomsContext.Provider value={{ rooms, createRoom, deleteRoom }}>
      {children}
    </RoomsContext.Provider>
  );
};

export const useRooms = () => {
  const context = useContext(RoomsContext);

  if (!context) {
    throw new Error('useRooms must be used within a RoomsProvider');
  }

  return context;
};
```

## Variants

**Status machine** (drawing, wizard flows): `status: 'loading' | 'idle' | 'drawing' | 'setting-shape-config'`, plus a `draft`. Wrap `setStatus` so leaving a state clears related data:

```tsx
const setStatus = (next: MapStatus) => {
  if (next !== 'setting-shape-config') setDraft(null);
  setStatusState(next);
};
```

**Initial load with `finally`:** `try { ... } finally { setStatusState('idle'); }` so the UI never stays in `loading`.

**Param-driven provider** (detail page): `RoomProvider({ roomId, children })`, effect depends on `[roomId]`, use `Promise.all` for parallel loads.

**Idempotent updates** (needed with realtime): 

```tsx
const appendRoom = (rooms: Room[], room: Room) =>
  rooms.some((r) => r.id === room.id) ? rooms : [...rooms, room];
```

**Per-user reset:** split into `XState` (does the work) and `XProvider` that renders `<XState key={user?.id ?? 'anonymous'}>`; state resets on login/logout.

**Context depending on another context:** `const { isAuthenticated } = useAuth();` inside the inner component; fetch only when authenticated, with `[isAuthenticated]` as the dependency.

**Request in flight:** `isSending` boolean set in `try/finally` around the call.

**Browser storage as state** (username, session): `useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot)` with a module-level `listeners` set and a `notify()` after each write. The server snapshot returns `null`, which avoids hydration mismatches. Expose `isReady` (true after hydration) so pages can wait before redirecting.

**Toasts (UI-wide):** `ToastProvider` in `app/layout.tsx` exposing `showToast(message, type)`; keep timers in a ref set and clear them on unmount.

## Mounting

```tsx
// app/layout.tsx
<AuthProvider>
  <ToastProvider>{children}</ToastProvider>
</AuthProvider>
```

Feature providers go in the page that needs them (`MapScreen` wraps `PolygonsProvider` and `PointsProvider`).

## Error handling

Actions may throw (axios errors). Let the calling component catch and show `getErrorMessage(err)`, or catch in the context and call `showToast`. Pick one per feature and keep it consistent.
