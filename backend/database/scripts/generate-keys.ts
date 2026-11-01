// Appends freshly generated local keys to backend/.env. Never overwrites an existing value.
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { appendFileSync, existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const file = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '.env');
const current = existsSync(file) ? readFileSync(file, 'utf8') : '';
const { privateKey, publicKey } = generateKeyPairSync('ed25519', {
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }, publicKeyEncoding: { type: 'spki', format: 'pem' },
});
const line = (s: string) => s.trim().replace(/\n/g, '\\n');
const values: Record<string, string> = {
  JWT_PRIVATE_KEY: `"${line(privateKey)}"`, JWT_PUBLIC_KEY: `"${line(publicKey)}"`, FIELD_ENCRYPTION_KEY: randomBytes(32).toString('base64'),
  REDIS_URL: 'redis://127.0.0.1:6379', DB_APP_USER: 'cafe_app',
  CORS_ORIGINS: 'http://localhost:8080,http://localhost:8081,http://localhost:8082,http://localhost:8083',
  PUBLIC_CUSTOMER_APP_URL: 'http://localhost:8083', PUBLIC_API_URL: 'http://localhost:3000',
};
for (const [k, v] of Object.entries(values)) {
  if (new RegExp(`^${k}=.+`, 'm').test(current)) continue;
  appendFileSync(file, `\n${k}=${v}`);
  console.log(`added ${k}`);
}
