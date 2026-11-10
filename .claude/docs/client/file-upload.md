# File upload hook

Dependency: `browser-image-compression` (images only). The server contract is in `.claude/docs/server/file-upload.md`: `POST /uploads/images`, field `file`, returns `{ url }`.

```ts
'use client';

import { useEffect, useState } from 'react';
import imageCompression from 'browser-image-compression';
import { api } from '@/lib/axios';
import { getErrorMessage } from '@/lib/errors';

const MAX_SIZE_MB = 5;
const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

export const IMAGE_ACCEPT = ALLOWED_TYPES.join(',');

export const useImageUpload = () => {
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Release the object URL when it is replaced or the component unmounts
  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl);
    };
  }, [previewUrl]);

  const clear = () => {
    setImageUrl(null);
    setPreviewUrl(null);
    setError(null);
  };

  const selectFile = async (file: File) => {
    clear();

    if (!ALLOWED_TYPES.includes(file.type)) {
      setError('Only png, jpeg and webp images are supported');
      return;
    }

    if (file.size > MAX_SIZE_MB * 1024 * 1024) {
      setError(`The image must be smaller than ${MAX_SIZE_MB} MB`);
      return;
    }

    setIsUploading(true);

    try {
      const compressed = await imageCompression(file, {
        maxSizeMB: 1,
        maxWidthOrHeight: 1920,
        useWebWorker: true,
      });

      const formData = new FormData();
      formData.append('file', compressed, file.name);

      // No Content-Type header: axios sets the multipart boundary itself
      const res = await api.post<{ url: string }>('/uploads/images', formData);

      setPreviewUrl(URL.createObjectURL(compressed));
      setImageUrl(res.data.url);
    } catch (err) {
      setError(getErrorMessage(err));
    } finally {
      setIsUploading(false);
    }
  };

  return { imageUrl, previewUrl, isUploading, error, selectFile, clear };
};
```

## Using it in a form

```tsx
const { imageUrl, previewUrl, isUploading, error, selectFile, clear } = useImageUpload();

<input
  type="file"
  accept={IMAGE_ACCEPT}
  disabled={isUploading}
  onChange={(event) => {
    const file = event.target.files?.[0];
    if (file) selectFile(file);
    event.target.value = '';   // allows choosing the same file again
  }}
/>
{previewUrl && <img src={previewUrl} alt="Selected preview" className="max-h-40 rounded" />}
{error && <p role="alert" className="text-sm text-red-600">{error}</p>}
```

Submit sends `imageUrl` (the stored URL), never the file, and call `clear()` after a successful submit. Disable the submit button while `isUploading`.

## Non-image files

Skip compression, keep the type and size validation, and mirror the limits of the server's allow-list. Keep client limits identical to the server's: the server is the authority.
