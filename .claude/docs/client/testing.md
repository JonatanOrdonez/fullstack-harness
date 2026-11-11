# Client testing

Stack: Vitest + Testing Library + jsdom.

## Setup (done by `test-writer` if missing)

```bash
cd client && npm install -D vitest @vitejs/plugin-react jsdom \
  @testing-library/react @testing-library/user-event @testing-library/jest-dom
```

`client/vitest.config.ts`:

```ts
import react from '@vitejs/plugin-react';
import path from 'node:path';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    globals: true,
  },
  resolve: {
    alias: { '@': path.resolve(__dirname) },
  },
});
```

`client/test/setup.ts`:

```ts
import '@testing-library/jest-dom/vitest';
```

Scripts: `"test": "vitest run"`, `"typecheck": "tsc --noEmit"`. Add `"types": ["vitest/globals"]` to `tsconfig.json` and include `test/**/*`.

## Component test

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { expect, test, vi } from 'vitest';
import { CreateRoomForm } from '@/components/CreateRoomForm';

const createRoom = vi.fn();

vi.mock('@/context/RoomsContext', () => ({
  useRooms: () => ({ rooms: [], createRoom, deleteRoom: vi.fn() }),
}));

test('CreateRoomForm submits the trimmed name', async () => {
  const user = userEvent.setup();
  render(<CreateRoomForm />);

  await user.type(screen.getByLabelText('Room name'), '  general  ');
  await user.click(screen.getByRole('button', { name: 'Create' }));

  expect(createRoom).toHaveBeenCalledWith('general');
});
```

## Context test (real provider, mocked network)

```tsx
import { renderHook, waitFor, act } from '@testing-library/react';
import { expect, test, vi } from 'vitest';
import { RoomsProvider, useRooms } from '@/context/RoomsContext';
import { api } from '@/lib/axios';

vi.mock('@/lib/axios', () => ({ api: { get: vi.fn(), post: vi.fn(), delete: vi.fn() } }));

test('RoomsProvider loads rooms on mount', async () => {
  vi.mocked(api.get).mockResolvedValue({ data: [{ id: '1', name: 'general' }] });

  const { result } = renderHook(() => useRooms(), { wrapper: RoomsProvider });

  await waitFor(() => expect(result.current.rooms).toHaveLength(1));
});

test('useRooms throws outside its provider', () => {
  expect(() => renderHook(() => useRooms())).toThrow('useRooms must be used within a RoomsProvider');
});
```

## Hook test with cleanup

```ts
test('useImageUpload rejects unsupported types without calling the API', async () => {
  const { result } = renderHook(() => useImageUpload());

  await act(async () => {
    await result.current.selectFile(new File(['x'], 'a.gif', { type: 'image/gif' }));
  });

  expect(result.current.error).toBe('Only png, jpeg and webp images are supported');
  expect(api.post).not.toHaveBeenCalled();
});
```

## Realtime

Mock `@/lib/supabase` so `channel().on().subscribe()` captures handlers; call a captured handler twice with the same payload and assert one item; unmount and assert `removeChannel` was called.

## Guidelines

- Query by role/label/text, never by class or test-id unless there is no accessible alternative.
- Mock at the network boundary (`@/lib/axios`, `@/lib/supabase`), not inside components.
- Always test: initial render states (loading/empty), the main action, an error path (`role="alert"`), and cleanup.
- Hand-written expected values; no snapshots of whole pages.

Note: a fresh Next.js checkout may fail `tsc` with `Cannot find name 'LayoutProps'` (or `PageProps`) until the route types are generated: run `npx next typegen` (or `next dev`/`next build` once) before `npm run typecheck`. Do not rewrite existing layout code to work around it.
