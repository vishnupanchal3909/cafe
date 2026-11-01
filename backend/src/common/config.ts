import { existsSync } from 'node:fs';
import { join } from 'node:path';

const envFile = join(__dirname, '..', '..', '..', '.env');
if (existsSync(envFile) && !process.env.SKIP_ENV_FILE) process.loadEnvFile(envFile);

function required(name: string): string {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required environment variable ${name}. See .env.example.`);
  return v;
}

export const config = {
  env: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 3000),
  db: {
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 3307),
    name: process.env.DB_NAME ?? 'cafe_platform',
    // Local dev may use the admin user. Production must set DB_APP_USER=cafe_app.
    user: process.env.DB_APP_USER ?? 'cafe_app',
    password: process.env.DB_APP_PASSWORD ?? '',
  },
  redisUrl: process.env.REDIS_URL ?? '',
  corsOrigins: (process.env.CORS_ORIGINS ?? '').split(',').map((s) => s.trim()).filter(Boolean),
  publicAppUrl: process.env.PUBLIC_CUSTOMER_APP_URL ?? 'http://localhost:8080',
  publicApiUrl: process.env.PUBLIC_API_URL ?? 'http://localhost:3000',
  runWorkers: (process.env.RUN_WORKERS ?? 'true') === 'true',
  storage: {
    s3Bucket: process.env.S3_BUCKET ?? '',
    s3Region: process.env.S3_REGION ?? '',
    s3Endpoint: process.env.S3_ENDPOINT ?? '',
    localDir: process.env.LOCAL_STORAGE_DIR ?? join(__dirname, '..', '..', '..', '..', '.devdata', 'uploads'),
  },
  jwt: {
    get privateKey() { return required('JWT_PRIVATE_KEY').replace(/\\n/g, '\n'); },
    get publicKey() { return required('JWT_PUBLIC_KEY').replace(/\\n/g, '\n'); },
    keyId: process.env.JWT_KEY_ID ?? 'k1',
    accessTtlSeconds: 900,
    refreshTtlDays: 30,
  },
  // Base64-encoded 32-byte key: field encryption for gateway credentials, QR tokens and MFA secrets.
  get encryptionKey() {
    const key = Buffer.from(required('FIELD_ENCRYPTION_KEY'), 'base64');
    if (key.length !== 32) throw new Error('FIELD_ENCRYPTION_KEY must be 32 bytes, base64 encoded');
    return key;
  },
  encryptionKeyId: process.env.FIELD_ENCRYPTION_KEY_ID ?? 'k1',
  googleClientId: process.env.GOOGLE_CLIENT_ID ?? '',
};
