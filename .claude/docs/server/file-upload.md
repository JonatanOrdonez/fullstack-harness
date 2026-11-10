# File uploads (multer + Supabase Storage)

Dependencies: `multer`, `@types/multer`.

## Service

```ts
import Boom from '@hapi/boom';
import { randomUUID } from 'node:crypto';
import { IMAGES_BUCKET } from '../../config/config';
import { supabase } from '../../config/supabase';

export const IMAGE_MAX_SIZE_MB = 5;

const EXTENSIONS: Record<string, string> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/webp': 'webp',
};

export const IMAGE_MIME_TYPES = Object.keys(EXTENSIONS);

// Called at startup; idempotent
export const initStorage = async () => {
  const { error } = await supabase.storage.createBucket(IMAGES_BUCKET, {
    public: true,
    fileSizeLimit: `${IMAGE_MAX_SIZE_MB}MB`,
    allowedMimeTypes: IMAGE_MIME_TYPES,
  });

  if (error && !/already exists/i.test(error.message)) {
    throw error;
  }
};

// Every file lives under a folder named after its owner
const getUserFolderUrl = (userId: string): string =>
  supabase.storage.from(IMAGES_BUCKET).getPublicUrl(`${userId}/`).data.publicUrl;

export const isUserImageUrl = (url: string, userId: string): boolean =>
  url.startsWith(getUserFolderUrl(userId));

export const uploadImageService = async (
  userId: string,
  file: Express.Multer.File,
): Promise<string> => {
  const path = `${userId}/${randomUUID()}.${EXTENSIONS[file.mimetype]}`;

  const { error } = await supabase.storage
    .from(IMAGES_BUCKET)
    .upload(path, file.buffer, { contentType: file.mimetype });

  if (error) {
    throw Boom.badGateway('The image could not be stored', error.message);
  }

  return supabase.storage.from(IMAGES_BUCKET).getPublicUrl(path).data.publicUrl;
};
```

## Router

```ts
import Boom from '@hapi/boom';
import { Router } from 'express';
import multer from 'multer';
import { authMiddleware } from '../../middlewares/authMiddleware';
import { uploadImageController } from './uploads.controller';
import { IMAGE_MAX_SIZE_MB, IMAGE_MIME_TYPES } from './uploads.service';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: IMAGE_MAX_SIZE_MB * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => {
    if (IMAGE_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
      return;
    }

    cb(Boom.unsupportedMediaType('Only png, jpeg and webp images are supported'));
  },
});

const router = Router();

// Authenticate first so anonymous requests never get their body parsed
router.post('/images', authMiddleware, upload.single('file'), uploadImageController);

export default router;
```

## Controller

```ts
export const uploadImageController = async (req: Request, res: Response) => {
  const user = getUserFromRequest(req);

  if (!req.file) {
    throw Boom.badRequest('An image is required in the "file" field');
  }

  const url = await uploadImageService(user.id, req.file);
  res.status(201).json({ url });
};
```

## Security notes

- The `fileFilter` trusts the client's MIME type; the bucket's `allowedMimeTypes` is the second line of defense. For stricter checks sniff magic bytes (`file-type`).
- multer errors (`LIMIT_FILE_SIZE`) are not Boom: map them in `errorHandler` to `413` if you need a clean message.
- A URL later sent back by a client (for example to attach an image to a chat message) must pass `isUserImageUrl(url, user.id)` before it is stored or forwarded to a third party.
- Mount at `/api/uploads`; add `IMAGES_BUCKET` to `config.ts` and `.env.example`.
- Non-image files: same pattern with another bucket, MIME allow-list and size limit; use `public: false` plus `createSignedUrl` when files must not be public.
