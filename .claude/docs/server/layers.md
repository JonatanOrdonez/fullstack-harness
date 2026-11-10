# Server layers

## Folder map

```
server/src/
├── app.ts                    # builds the Express app (no listen) so tests can import it
├── index.ts                  # loads app, runs initDb/initStorage, listens
├── config/
│   ├── config.ts             # dotenv + typed env constants
│   ├── supabase.ts           # supabase client (secret key)
│   └── <other>.ts            # groq, socket server, ...
├── db/db.ts                  # pg Pool + initDb()
├── middlewares/
│   ├── errorMiddleware.ts
│   └── authMiddleware.ts
└── features/<feature>/
    ├── <feature>.router.ts
    ├── <feature>.controller.ts
    ├── <feature>.service.ts
    ├── <feature>.repository.ts
    └── <feature>.types.ts
```

## Request flow

```
HTTP → router → controller → service → repository → PostgreSQL
                    │            │
         validates input    business rules, ownership,
         picks status       broadcasts, external APIs
```

| Layer | Knows about | Must not |
|-------|-------------|----------|
| Router | verbs, paths, middlewares, controllers | contain logic |
| Controller | `req`, `res`, validation, status codes | run SQL or business rules |
| Service | repositories, other services, Boom, external APIs | touch `req`/`res` |
| Repository | `pool`, SQL, row mapping | throw HTTP errors, call services |

## Naming

`<verb><Entity><Layer>`: `createRoomController`, `getRoomsService`, `deleteRoomRepository`. Types: `Room`, `CreateRoomDTO`.

## Adding a feature, in order

1. `types.ts`
2. table in `db/db.ts` (see `db-init.md`)
3. `repository.ts` (see `repository.md`)
4. `service.ts` (see `service.md`)
5. `controller.ts` and `router.ts` (see `router-controller.md`)
6. mount in `app.ts`: `apiRouter.use('/', <feature>Router)` (or `'/<prefix>'` when the router has no path prefix inside)
7. tests (see `testing.md`)

## Mounting

```ts
const apiRouter = Router();
app.use('/api', apiRouter);
apiRouter.use('/auth', authRouter);
apiRouter.use('/', roomsRouter);   // routes declare '/rooms', '/rooms/:id', ...
app.use(errorHandler);             // always last
```
