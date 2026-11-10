---
paths:
  - "server/src/features/**/*.ts"
---

# Server layers

Each feature lives in `server/src/features/<feature>/` with five files: `<feature>.router.ts`, `.controller.ts`, `.service.ts`, `.repository.ts`, `.types.ts`. Dependencies go one way: router → controller → service → repository.

- **Router:** only maps HTTP verb + path to a controller. No logic. Export the router as `default`. Mounted in `src/app.ts` under `/api` (`index.ts` only listens).
- **Controller:** reads `req`, validates input (throws `Boom.badRequest`), calls **one** service, sends the response with the right status (`201` create, `200` read, `204` delete). No SQL, no business rules.
- **Service:** business rules, ownership checks, orchestration across repositories, external APIs, realtime broadcasts. Throws `Boom` errors (`notFound`, `forbidden`...). Never touches `req`/`res`.
- **Repository:** the only layer that talks to the database. Parameterized SQL only (`$1`, `$2`), never string interpolation of user input. Returns typed rows; maps snake_case columns with `AS "camelCase"`.
- **Types:** domain interfaces and `Create*DTO` interfaces. Shared by all layers of the feature.
- Name functions `<verb><Entity><Layer>`: `createPointController`, `createPointService`, `createPointRepository`.
- A service may call another feature's *service*, never its repository.
- Controllers are `async` and just `throw`: Express 5 forwards rejected promises to `errorHandler`. Do not add try/catch for that.

Patterns and templates: `.claude/docs/server/layers.md`, `.claude/docs/server/router-controller.md`, `.claude/docs/server/service.md`, `.claude/docs/server/repository.md`.
