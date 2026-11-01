import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { Db } from '../infra/db/db.service';
import { unscoped } from './context';

const FALLBACK: Record<string, string> = {
  INTERNAL_ERROR: 'Something went wrong. Please try again.',
  VALIDATION_FAILED: 'Some fields are invalid.',
  UNAUTHORIZED: 'Please sign in.',
  FORBIDDEN: 'You do not have permission to do this.',
  NOT_FOUND: 'Not found.',
  RATE_LIMITED: 'Too many requests. Please wait and try again.',
  INVALID_CREDENTIALS: 'Incorrect email or password.',
  ACCOUNT_LOCKED: 'Too many attempts. Try again later.',
};

@Injectable()
export class MessageCatalog {
  private cache = new Map<string, { value: string | null; at: number }>();
  constructor(private readonly db: Db) {}

  async resolve(code: string, lang: string): Promise<string> {
    const fallback = FALLBACK[code] ?? code;
    const key = `${lang}:${code}`;
    const hit = this.cache.get(key);
    if (hit && Date.now() - hit.at < 300_000) return hit.value ?? fallback;
    try {
      const row = await unscoped('system message lookup', () =>
        this.db.q.selectFrom('translations').select('value')
          .where('namespace', '=', 'errors').where('translation_key', '=', code)
          .where('language_code', 'in', [lang, 'en'])
          .orderBy(sql`language_code = ${lang}`, 'desc').executeTakeFirst());
      this.cache.set(key, { value: row?.value ?? null, at: Date.now() });
      return row?.value ?? fallback;
    } catch {
      return fallback;
    }
  }
}
