---
name: add-file-upload
description: Adds file uploads end to end: multer on the server storing in Supabase Storage, and a client hook that validates, compresses and uploads. Use for images or documents attached to features.
---

# Add file uploads

Argument: the file kind and limits (for example `images png/jpeg/webp up to 5 MB`).

1. Read `.claude/docs/server/file-upload.md` (multer config, bucket init, per-user paths, URL ownership check) and `.claude/docs/client/file-upload.md` (the `useImageUpload` hook, FormData rules).
2. Server:
   - Add the bucket name to `config/config.ts` and `.env.example`.
   - Create `features/uploads/` with the usual layers (router, controller, service, types).
   - Authenticate **before** multer. Allow-list MIME types and set `limits.fileSize`.
   - Store at `<userId>/<uuid>.<ext>`; create the bucket idempotently at startup (`initStorage`).
   - If a stored URL is later sent back by clients, validate it with an `isUserImageUrl(url, userId)` check.
3. Client:
   - Add `hooks/use<Kind>Upload.ts` returning `{ url, previewUrl, isUploading, error, selectFile, clear }`.
   - Do not set `Content-Type` manually for `FormData`; revoke object URLs on cleanup.
4. Tests: server rejects wrong MIME type (415), oversize file, missing file (400) and anonymous requests (401); client hook rejects invalid type/size before any request.
5. Run `npm run typecheck`, `npm run lint`, `npm test` in both workspaces.
