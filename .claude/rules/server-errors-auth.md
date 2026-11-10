---
paths:
  - "server/src/middlewares/**/*.ts"
  - "server/src/**/*.controller.ts"
  - "server/src/**/*.service.ts"
---

# Server errors, auth and uploads

- Errors are `@hapi/boom` objects. Use the status that matches: `badRequest` (400), `unauthorized` (401), `forbidden` (403), `notFound` (404), `unsupportedMediaType` (415), `badGateway` (502, upstream service failed).
- `src/middlewares/errorMiddleware.ts` is the only place that turns errors into JSON. It must be registered **after** all routers. Non-Boom errors become `500` and must not leak internals.
- Validate at the edge (controller). Services trust their typed inputs but still enforce ownership and existence.
- Authenticated routes use `authMiddleware` passed per route (never `router.use(authMiddleware)` in a router mounted at `/`); handlers read the user with `getUserFromRequest(req)`, never `req.user!`.
- Ownership: every query for user data filters by `user_id`. A resource that exists but belongs to someone else returns `404`, not `403`.
- Uploads: multer with `memoryStorage`, `limits.fileSize` and a `fileFilter` allow-list. Put auth middleware **before** multer so anonymous bodies are never parsed. Store files under `<userId>/<uuid>.<ext>`.
- Any URL received from a client that the server (or a third party) will fetch must be validated against an allow-list (for example, only files in the caller's own storage folder).
- Realtime broadcasts are fire-and-forget: a failure is logged, never thrown into the request.

Templates: `.claude/docs/server/errors-boom.md`, `.claude/docs/server/auth-middleware.md`, `.claude/docs/server/file-upload.md`, `.claude/docs/server/realtime-supabase.md`.
