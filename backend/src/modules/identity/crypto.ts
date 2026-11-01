import { createHmac, randomBytes, timingSafeEqual, argon2 as argon2Cb } from 'node:crypto';

const PARAMS = { memory: 65536, passes: 3, parallelism: 1, tagLength: 32 };

function derive(password: string, nonce: Buffer, p = PARAMS): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    argon2Cb('argon2id', { message: password, nonce, ...p }, (err, key) => (err ? reject(err) : resolve(key)));
  });
}

export async function hashPassword(password: string): Promise<string> {
  const nonce = randomBytes(16);
  const key = await derive(password, nonce);
  return `$argon2id$v=19$m=${PARAMS.memory},t=${PARAMS.passes},p=${PARAMS.parallelism}$${nonce.toString('base64url')}$${key.toString('base64url')}`;
}

export async function verifyPassword(encoded: string, password: string): Promise<boolean> {
  const m = /^\$argon2id\$v=19\$m=(\d+),t=(\d+),p=(\d+)\$([^$]+)\$([^$]+)$/.exec(encoded);
  if (!m) return false;
  const expected = Buffer.from(m[5]!, 'base64url');
  const key = await derive(password, Buffer.from(m[4]!, 'base64url'), {
    memory: Number(m[1]), passes: Number(m[2]), parallelism: Number(m[3]), tagLength: expected.length,
  });
  return timingSafeEqual(key, expected);
}

// A fixed hash to verify against for unknown accounts, so response timing does not reveal which emails exist.
export const DUMMY_HASH_PROMISE = hashPassword(randomBytes(16).toString('hex'));

const B32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
export function newTotpSecret(): string {
  const bytes = randomBytes(20);
  let bits = '';
  for (const b of bytes) bits += b.toString(2).padStart(8, '0');
  let out = '';
  for (let i = 0; i + 5 <= bits.length; i += 5) out += B32[parseInt(bits.slice(i, i + 5), 2)];
  return out;
}
function b32decode(s: string): Buffer {
  let bits = '';
  for (const c of s) bits += B32.indexOf(c).toString(2).padStart(5, '0');
  const out: number[] = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) out.push(parseInt(bits.slice(i, i + 8), 2));
  return Buffer.from(out);
}
export function totp(secret: string, at = Date.now()): string {
  const counter = Buffer.alloc(8);
  counter.writeBigUInt64BE(BigInt(Math.floor(at / 30000)));
  const h = createHmac('sha1', b32decode(secret)).update(counter).digest();
  const o = h[h.length - 1]! & 0xf;
  return String((h.readUInt32BE(o) & 0x7fffffff) % 1_000_000).padStart(6, '0');
}
export function verifyTotp(secret: string, code: string): boolean {
  return [-30000, 0, 30000].some((skew) => totp(secret, Date.now() + skew) === code);
}
