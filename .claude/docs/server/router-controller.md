# Router and controller

## Router

```ts
import { Router } from 'express';
import {
  createRoomController,
  deleteRoomController,
  getRoomByIdController,
  getRoomsController,
} from './rooms.controller';

const router = Router();

router.post('/rooms', createRoomController);
router.get('/rooms', getRoomsController);
router.get('/rooms/:id', getRoomByIdController);
router.delete('/rooms/:id', deleteRoomController);

export default router;
```

Protected route: pass `authMiddleware` per route, `router.get('/rooms', authMiddleware, getRoomsController)` (see `auth-middleware.md`). Never `router.use(authMiddleware)` in a router mounted at `/`: it would intercept every `/api/*` request that reaches it and make later public routers answer `401`. Nested resources: `/rooms/:roomId/messages`.

## Controller

```ts
import Boom from '@hapi/boom';
import { Request, Response } from 'express';
import { createRoomService, deleteRoomService, getRoomsService } from './rooms.service';

export const createRoomController = async (req: Request, res: Response) => {
  const { name } = req.body;

  if (typeof name !== 'string' || !name.trim()) {
    throw Boom.badRequest('Name is required');
  }

  const room = await createRoomService({ name: name.trim() });

  res.status(201).json(room);
};

export const getRoomsController = async (_req: Request, res: Response) => {
  res.status(200).json(await getRoomsService());
};

export const deleteRoomController = async (req: Request, res: Response) => {
  await deleteRoomService(String(req.params.id));

  res.status(204).send();
};
```

## Conventions

- Express 5 handles rejected promises: `throw` directly, no try/catch, no `next(err)`.
- `req.params.x` is typed `string | string[]`: wrap with `String(...)`.
- Validate type **and** shape: strings trimmed and non-empty, numbers with ranges, enums against an allow-list, regex for formats (`/^#[0-9a-fA-F]{6}$/`), arrays with a minimum length.
- Pass the service a clean DTO, never `req.body` itself.
- Status codes: `201` create, `200` read/update, `204` delete (no body).
- Authenticated handlers: `const user = getUserFromRequest(req);` and pass `user.id` to the service.
- Long validation blocks that repeat across controllers go in `<feature>.validation.ts` as small functions that throw `Boom.badRequest`.
