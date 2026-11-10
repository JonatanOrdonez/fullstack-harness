# Auth (Supabase Auth + Bearer token)

## Types

```ts
// features/auth/auth.types.ts
export interface User {
  id: string;
  email: string;
  token: string;
  data: { name: string };
}
export interface RegisterDTO { email: string; password: string; name: string }
export interface LoginDTO { email: string; password: string }
```

## Service

```ts
import Boom from '@hapi/boom';
import { supabase } from '../../config/supabase';
import { LoginDTO, RegisterDTO, User } from './auth.types';

export const registerService = async ({ email, password, name }: RegisterDTO): Promise<User> => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { name } },
  });

  if (error || !data.user) {
    throw Boom.badRequest(error?.message ?? 'Could not register user');
  }

  return {
    id: data.user.id,
    email: data.user.email ?? email,
    // Empty when email confirmation is enabled: there is no session yet
    token: data.session?.access_token ?? '',
    data: { name: data.user.user_metadata?.name ?? name },
  };
};

export const loginService = async ({ email, password }: LoginDTO): Promise<User> => {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });

  if (error || !data.session) {
    throw Boom.unauthorized(error?.message ?? 'Invalid credentials');
  }

  return {
    id: data.user.id,
    email: data.user.email ?? email,
    token: data.session.access_token,
    data: { name: data.user.user_metadata?.name ?? '' },
  };
};
```

Controllers validate `email`, `password` (minimum length) and `name`; routes: `POST /auth/register`, `POST /auth/login`.

## Middleware

```ts
// middlewares/authMiddleware.ts
import Boom from '@hapi/boom';
import { NextFunction, Request, Response } from 'express';
import { supabase } from '../config/supabase';
import { User } from '../features/auth/auth.types';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: User;
    }
  }
}

export const authMiddleware = async (req: Request, _res: Response, next: NextFunction) => {
  const [scheme, token] = (req.headers.authorization ?? '').split(' ');

  if (scheme !== 'Bearer' || !token) {
    throw Boom.unauthorized('Missing or malformed Authorization header');
  }

  const { data, error } = await supabase.auth.getUser(token);

  if (error || !data.user) {
    throw Boom.unauthorized('Invalid or expired token');
  }

  req.user = {
    id: data.user.id,
    email: data.user.email ?? '',
    token,
    data: { name: data.user.user_metadata?.name ?? '' },
  };

  next();
};

export const getUserFromRequest = (req: Request): User => {
  if (!req.user) {
    throw Boom.unauthorized('User not authenticated');
  }

  return req.user;
};
```

## Using it

```ts
const router = Router();
// Per route: routers are mounted at '/', so a router-level `router.use(authMiddleware)`
// would also guard every public router mounted after this one.
router.get('/conversations', authMiddleware, getConversationsController);
router.post('/conversations', authMiddleware, createConversationController);
```

Controllers: `const user = getUserFromRequest(req);` then `getConversationsService(user.id)`. The server uses the Supabase **secret** key (`SUPABASE_SECRET_KEY`); it never leaves the server.
