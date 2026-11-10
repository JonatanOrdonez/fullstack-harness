# Hooks

Use a hook for reusable **local** logic. Shared app state belongs in a context.

## Template

```ts
'use client';

import { useEffect, useState } from 'react';

export const useDebouncedValue = <T,>(value: T, delayMs = 300): T => {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);

    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
};
```

## Object-returning hook (state + actions)

```ts
export const useToggle = (initial = false) => {
  const [isOn, setIsOn] = useState(initial);

  const toggle = () => setIsOn((prev) => !prev);
  const set = (value: boolean) => setIsOn(value);

  return { isOn, toggle, set };
};
```

## Async hook with error string

```ts
export const useRequest = <T,>(request: () => Promise<T>) => {
  const [data, setData] = useState<T | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const run = async () => {
    setIsLoading(true);
    setError(null);

    try {
      setData(await request());
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsLoading(false);
    }
  };

  return { data, isLoading, error, run };
};
```

## Rules of thumb

- Name starts with `use`, file is `useThing.ts`, named export.
- Return state first, actions after; the component never sees thrown errors, it reads `error`.
- Anything allocated in an effect is released in its cleanup.
- Constants (limits, allowed types) at module level; export those components need.
- Dependencies arrays are complete (the ESLint rule `react-hooks/exhaustive-deps` is on).
- Window/DOM access only inside effects or handlers (SSR-safe).
- Geolocation / media / observers: wrap the browser API in the hook, expose plain values (`position`, `isSupported`, `error`).
