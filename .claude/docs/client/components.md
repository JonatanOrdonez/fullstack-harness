# Components and pages

## Folder map

```
client/
├── app/
│   ├── layout.tsx            # global providers (auth, toasts), fonts, metadata
│   ├── page.tsx              # home: composes providers + components
│   ├── login/page.tsx
│   └── rooms/[id]/page.tsx   # dynamic route
├── components/               # one component per file, PascalCase
├── context/
├── hooks/
└── lib/
```

## Component template

```tsx
'use client';

import { useRooms } from '@/context/RoomsContext';
import { RoomItem } from './RoomItem';

export const RoomsList = () => {
  const { rooms, deleteRoom } = useRooms();

  if (rooms.length === 0) {
    return <p className="text-sm text-neutral-500">No rooms yet.</p>;
  }

  return (
    <ul className="flex flex-col gap-2">
      {rooms.map((room) => (
        <RoomItem key={room.id} room={room} onDelete={() => deleteRoom(room.id)} />
      ))}
    </ul>
  );
};
```

## Form template

```tsx
'use client';

import { FormEvent, useState } from 'react';
import { useRooms } from '@/context/RoomsContext';
import { getErrorMessage } from '@/lib/errors';

export const CreateRoomForm = () => {
  const { createRoom } = useRooms();
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      await createRoom(name.trim());
      setName('');
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <label className="sr-only" htmlFor="room-name">Room name</label>
      <input
        id="room-name"
        value={name}
        onChange={(event) => setName(event.target.value)}
        className="flex-1 rounded border px-3 py-2"
        placeholder="Room name"
      />
      <button
        type="submit"
        disabled={isSubmitting || !name.trim()}
        className="rounded bg-indigo-600 px-4 py-2 text-white disabled:opacity-50"
      >
        Create
      </button>
      {error && <p role="alert" className="text-sm text-red-600">{error}</p>}
    </form>
  );
};
```

## Page template (dynamic route, Next.js 16)

```tsx
'use client';

import { use } from 'react';
import { RoomProvider } from '@/context/RoomContext';

export default function RoomPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);

  return (
    <RoomProvider roomId={id}>
      <main className="mx-auto flex max-w-md flex-col gap-4 px-4 py-10">
        {/* components that call useRoom() */}
      </main>
    </RoomProvider>
  );
}
```

Pattern: a small inner component (`RoomDetails`) calls the context hook, because the hook only works **below** the provider.

## Guidelines

- Server components by default; add `'use client'` only when you need state, effects, handlers or browser APIs.
- Browser-only libraries (Leaflet): load with `next/dynamic` and `{ ssr: false }`.
- Loading/empty/error states are rendered explicitly.
- Redirects after actions: `useRouter().push('/')`.
- Mode/status-driven UI (maps, wizards): keep a `status` union in the context (`'loading' | 'idle' | 'drawing' | ...`) and disable controls according to it.
- Shared Tailwind class strings used by several components: `components/<name>Styles.ts`.
- Next.js 16 may differ from older versions: check `client/node_modules/next/dist/docs/` before using a Next API you are unsure about.
