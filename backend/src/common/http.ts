import { CallHandler, CanActivate, ExecutionContext, Injectable, NestInterceptor, NestMiddleware, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import { map } from 'rxjs';
import Redis from 'ioredis';
import { als, Audience, principal } from './context';
import { AppError, forbidden } from './errors';
import { config } from './config';

export const IS_PUBLIC = 'isPublic';
export const AUDIENCES = 'audiences';
export const PERMISSIONS = 'permissions';
export const RATE = 'rate';
export const RAW_RESPONSE = 'rawResponse';

// Everything else is denied: a route with neither @Public nor @Audiences is unreachable.
export const Public = () => SetMetadata(IS_PUBLIC, true);
export const Audiences = (...a: Audience[]) => SetMetadata(AUDIENCES, a);
export const Requires = (...p: string[]) => SetMetadata(PERMISSIONS, p);
export const RateLimit = (limit: number, windowSeconds = 60) => SetMetadata(RATE, { limit, windowSeconds });
export const RawResponse = () => SetMetadata(RAW_RESPONSE, true);

const SUPPORTED = new Set(['en', 'hi', 'mr', 'es', 'fr', 'de', 'ar', 'pt', 'ja']);

@Injectable()
export class ContextMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = randomUUID();
    res.setHeader('X-Request-Id', requestId);
    const lang = (req.headers['accept-language'] ?? '').split(',')[0]?.split('-')[0]?.trim().toLowerCase() ?? 'en';
    als.run({ requestId, lang: SUPPORTED.has(lang) ? lang : 'en', ip: req.ip }, () => next());
  }
}

@Injectable()
export class EnvelopeInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}
  intercept(ctx: ExecutionContext, next: CallHandler) {
    if (this.reflector.get(RAW_RESPONSE, ctx.getHandler())) return next.handle();
    return next.handle().pipe(map((data) => (data && typeof data === 'object' && 'data' in data && 'meta' in data ? data : { data: data ?? null })));
  }
}

const memoryHits = new Map<string, { n: number; resetAt: number }>();

@Injectable()
export class RateLimitGuard implements CanActivate {
  private redis = config.redisUrl ? new Redis(config.redisUrl, { lazyConnect: false, maxRetriesPerRequest: 1 }) : null;
  constructor(private readonly reflector: Reflector) { this.redis?.on('error', () => undefined); }

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const rule = this.reflector.getAllAndOverride<{ limit: number; windowSeconds: number }>(RATE, [ctx.getHandler(), ctx.getClass()])
      ?? { limit: 300, windowSeconds: 60 };
    const req = ctx.switchToHttp().getRequest<Request>();
    const key = `rl:${ctx.getClass().name}.${ctx.getHandler().name}:${req.ip}`;
    let count: number;
    try {
      if (!this.redis) throw new Error('no redis');
      count = await this.redis.incr(key);
      if (count === 1) await this.redis.expire(key, rule.windowSeconds);
    } catch {
      // Per-process fallback so a Redis outage degrades limiting rather than disabling it.
      const now = Date.now();
      const hit = memoryHits.get(key);
      if (!hit || hit.resetAt < now) { memoryHits.set(key, { n: 1, resetAt: now + rule.windowSeconds * 1000 }); count = 1; }
      else count = ++hit.n;
    }
    // Scaling exists only so the e2e suite can run, and is ignored in production.
    const scale = config.env === 'production' ? 1 : Number(process.env.RATE_LIMIT_SCALE ?? 1);
    if (count > rule.limit * scale) throw new AppError(429, 'RATE_LIMITED');
    return true;
  }
  onModuleDestroy() { this.redis?.disconnect(); }
}

export function assertPermission(code: string): void {
  if (!principal().permissions.has(code)) throw forbidden();
}
export function requirePage(q: { page?: unknown; limit?: unknown }) {
  const page = Math.max(1, Number(q.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(q.limit) || 25));
  return { page, limit, offset: (page - 1) * limit };
}
export const paged = <T>(data: T[], page: number, limit: number, total: number) => ({ data, meta: { page, limit, total } });
