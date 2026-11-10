# `lib/`: config, axios, errors, auth

## `lib/config.ts`

```ts
export const API_URL = process.env.NEXT_PUBLIC_API_URL;

export const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
export const SUPABASE_PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';
export const SOCKET_URL = process.env.NEXT_PUBLIC_SOCKET_URL || '';
```

`client/.env.example`:

```
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=
```

Only public values: anything `NEXT_PUBLIC_*` ships to the browser.

## `lib/axios.ts`

Public API:

```ts
import axios from 'axios';
import { API_URL } from './config';

export const api = axios.create({ baseURL: API_URL });
```

With auth (adds the Bearer token to every request):

```ts
import axios from 'axios';
import { API_URL } from './config';
import { getStoredAuth, parseStoredUser } from './authStorage';

export const api = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config) => {
  const user = parseStoredUser(getStoredAuth());

  if (user?.token) {
    config.headers.Authorization = `Bearer ${user.token}`;
  }

  return config;
});
```

Optional: a response interceptor that clears the session on `401`.

## `lib/errors.ts`

```ts
import { isAxiosError } from 'axios';

export const getErrorMessage = (error: unknown) => {
  if (isAxiosError(error)) {
    return error.response?.data?.message ?? error.message;
  }

  return 'Something went wrong';
};
```

## `lib/types.ts`

Interfaces mirroring the server's responses (`Room`, `Message`, `User`...). Dates arrive as ISO strings (`createdAt: string`). Unions for statuses live here too (`MapStatus`).

## `lib/authStorage.ts`

```ts
import { User } from './types';

export const AUTH_STORAGE_KEY = 'auth';

export const getStoredAuth = () => localStorage.getItem(AUTH_STORAGE_KEY);

export const parseStoredUser = (raw: string | null): User | null => {
  if (!raw) return null;

  try {
    return JSON.parse(raw) as User;
  } catch {
    return null;
  }
};
```

## `context/AuthContext.tsx`

Built on `useSyncExternalStore` so SSR and hydration are safe:

```tsx
'use client';

import { createContext, useContext, useMemo, useSyncExternalStore } from 'react';
import { api } from '@/lib/axios';
import { AUTH_STORAGE_KEY, getStoredAuth, parseStoredUser } from '@/lib/authStorage';
import { User } from '@/lib/types';

const listeners = new Set<() => void>();
const getServerSnapshot = () => null;
const subscribeNoop = () => () => {};
const getHydrated = () => true;
const getServerHydrated = () => false;

const subscribe = (listener: () => void) => {
  listeners.add(listener);
  return () => listeners.delete(listener);
};

const notify = () => listeners.forEach((listener) => listener());

interface AuthContextValue {
  user: User | null;
  isAuthenticated: boolean;
  isReady: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, name: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const raw = useSyncExternalStore(subscribe, getStoredAuth, getServerSnapshot);
  const isReady = useSyncExternalStore(subscribeNoop, getHydrated, getServerHydrated);
  const user = useMemo(() => parseStoredUser(raw), [raw]);

  const saveUser = (value: User) => {
    localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(value));
    notify();
  };

  const login = async (email: string, password: string) => {
    const res = await api.post<User>('/auth/login', { email, password });
    saveUser(res.data);
  };

  // With email confirmation enabled the API returns an empty token: no session yet
  const register = async (email: string, password: string, name: string) => {
    const res = await api.post<User>('/auth/register', { email, password, name });

    if (res.data.token) {
      saveUser(res.data);
    }
  };

  const logout = () => {
    localStorage.removeItem(AUTH_STORAGE_KEY);
    notify();
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated: !!user, isReady, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }

  return context;
};
```

## Route protection

In a page: wait for `isReady`, then `if (!isAuthenticated) router.replace('/login')` inside an effect; render nothing (or a spinner) until then. Feature providers that need a session are keyed by user id (see `contexts.md`).

`localStorage` tokens are readable by any script on the page; keep the CSP tight and never render untrusted HTML.
