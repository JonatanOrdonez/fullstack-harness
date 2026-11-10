# Errors with Boom

## Which status

| Situation | Call | Status |
|-----------|------|--------|
| Missing/invalid body, bad params | `Boom.badRequest('Name is required')` | 400 |
| No/invalid token | `Boom.unauthorized('Invalid or expired token')` | 401 |
| Authenticated but not allowed | `Boom.forbidden('...')` | 403 |
| Not found or not owned by caller | `Boom.notFound('Room not found')` | 404 |
| Duplicate / state conflict | `Boom.conflict('...')` | 409 |
| Wrong file type | `Boom.unsupportedMediaType('Only png, jpeg and webp images are supported')` | 415 |
| Upstream API/storage failed | `Boom.badGateway('The AI service failed to respond')` | 502 |

Messages are short, in English, and never include SQL, stack traces or secrets. A second argument (`Boom.badGateway('msg', details)`) becomes `details` in the response; keep it harmless.

## Error middleware

`src/middlewares/errorMiddleware.ts`, registered after every router:

```ts
import { Request, Response, NextFunction } from 'express';
import Boom from '@hapi/boom';

export const errorHandler = (
  err: Error | Boom.Boom,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  // Non-Boom errors (bugs, DB errors) are normalized to a 500
  const boomError: Boom.Boom = Boom.isBoom(err) ? err : Boom.boomify(err);

  const { statusCode, payload } = boomError.output;
  res.status(statusCode).json({
    ...payload,
    details: boomError.detail,
  });
};
```

Response shape: `{ statusCode, error, message, details? }`. The client reads `error.response.data.message` (see `lib/errors.ts`).

For 500s, `Boom.boomify` keeps the generic "An internal server error occurred" message in `payload`; log the original with `console.error` if you need to debug.

## Rethrow rule

When catching around external calls, never swallow a Boom you already created:

```ts
if (Boom.isBoom(error)) throw error;
```
