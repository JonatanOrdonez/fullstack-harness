---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript style

- `strict` mode. No `any`, no `@ts-ignore`; use `unknown` and narrow.
- Type every parameter and return value of exported functions.
- Named exports only, except Next.js files that require a default export (`page.tsx`, `layout.tsx`).
- Arrow functions for services, controllers, repositories, hooks and components: `export const name = async () => {}`.
- Style (enforced by ESLint): single quotes, semicolons, 2-space indent, trailing commas in multiline lists, parentheses around arrow params.
- `console.log` is a lint warning: remove it before finishing (`console.error` in a catch that swallows an error on purpose is fine).
- Unused params are prefixed with `_` (`_req`, `_res`).
- Names and comments in English. Comment the *why* (a constraint, a trade-off), not the *what*.
- Always finish with `npm run typecheck` and `npm run lint` clean in the workspace you touched.
