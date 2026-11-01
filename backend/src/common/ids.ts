import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';
import { config } from './config';

const B32 = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

// ULID: sortable by creation time, unguessable random tail.
export function ulid(now = Date.now()): string {
  let time = '';
  let t = now;
  for (let i = 0; i < 10; i++) { time = B32[t % 32] + time; t = Math.floor(t / 32); }
  const rand = randomBytes(16);
  let tail = '';
  for (let i = 0; i < 16; i++) tail += B32[rand[i]! % 32];
  return time + tail;
}

export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');
export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');

// AES-256-GCM: [12 byte IV][16 byte tag][ciphertext]
export function encrypt(plain: string): Buffer {
  const iv = randomBytes(12);
  const c = createCipheriv('aes-256-gcm', config.encryptionKey, iv);
  const body = Buffer.concat([c.update(plain, 'utf8'), c.final()]);
  return Buffer.concat([iv, c.getAuthTag(), body]);
}
export function decrypt(data: Buffer): string {
  const d = createDecipheriv('aes-256-gcm', config.encryptionKey, data.subarray(0, 12));
  d.setAuthTag(data.subarray(12, 28));
  return Buffer.concat([d.update(data.subarray(28)), d.final()]).toString('utf8');
}
