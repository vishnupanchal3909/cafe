// Boots the real app on a dedicated database as the real least-privilege user. Nothing here is mocked except
// the clearly labelled TestGatewayProvider, because no gateway sandbox credentials exist.
import { execFileSync } from 'node:child_process';
import { createHmac, generateKeyPairSync, randomBytes } from 'node:crypto';
import { join } from 'node:path';
import type { AddressInfo } from 'node:net';
import type { INestApplication } from '@nestjs/common';
import mysql from 'mysql2/promise';

const ROOT = join(__dirname, '..', '..');
export const TEST_DB = process.env.API_TEST_DB ?? 'cafe_test_api';

function db(sqlText: string) {
  execFileSync(process.env.MYSQL_CLI ?? '/opt/homebrew/opt/mysql@8.4/bin/mysql', ['--no-defaults', '-h', process.env.DB_HOST ?? '127.0.0.1', '-P', process.env.DB_PORT ?? '3307', '-u', process.env.DB_ADMIN_USER ?? 'root', ...(process.env.DB_ADMIN_PASSWORD ? [`-p${process.env.DB_ADMIN_PASSWORD}`] : []), '-e', sqlText]);
}

export async function bootstrap() {
  if (!TEST_DB.startsWith('cafe_test_')) throw new Error('Refusing to reset a non-test database');
  const appPassword = randomBytes(12).toString('hex');
  const env = {
    ...process.env, DB_NAME: TEST_DB, DB_APP_USER: 'cafe_test_api_app', DB_MIGRATOR_USER: 'cafe_test_api_mig', DB_REPORTING_USER: 'cafe_test_api_rep',
    DB_APP_PASSWORD: appPassword, DB_MIGRATOR_PASSWORD: randomBytes(12).toString('hex'), DB_REPORTING_PASSWORD: randomBytes(12).toString('hex'),
  };
  db(`DROP DATABASE IF EXISTS ${TEST_DB}`);
  for (const script of ['migrate', 'seed', 'grants']) execFileSync('node', [`database/scripts/${script}.ts`], { cwd: ROOT, env, stdio: 'pipe' });
  const { privateKey, publicKey } = generateKeyPairSync('ed25519', { privateKeyEncoding: { type: 'pkcs8', format: 'pem' }, publicKeyEncoding: { type: 'spki', format: 'pem' } });
  Object.assign(process.env, {
    SKIP_ENV_FILE: '1', NODE_ENV: 'test', DB_NAME: TEST_DB, DB_APP_USER: 'cafe_test_api_app', DB_APP_PASSWORD: appPassword, JWT_PRIVATE_KEY: privateKey, JWT_PUBLIC_KEY: publicKey,
    FIELD_ENCRYPTION_KEY: randomBytes(32).toString('base64'), RUN_WORKERS: 'false', LOCAL_STORAGE_DIR: join(ROOT, '..', '.devdata', 'test-uploads'), CORS_ORIGINS: process.env.LIVE_CORS ?? 'http://localhost:8083', REDIS_URL: process.env.TEST_REDIS_URL ?? '',
  });
  // Each test file starts with clean rate-limit counters, so a 429 can never hide an auth result.
  if (process.env.TEST_REDIS_URL) {
    const Redis = (await import('ioredis')).default;
    const r = new Redis(process.env.TEST_REDIS_URL);
    const keys = await r.keys('rl:*');
    if (keys.length) await r.del(...keys);
    r.disconnect();
  }
  // App code imported too early reads .env and would run tests against the developer's real database. Stop before any request.
  const { config } = await import('../src/common/config');
  if (config.db.name !== TEST_DB) throw new Error(`Refusing to test against ${config.db.name}: app code was imported before bootstrap(). Use a dynamic import.`);
  const { createApp } = await import('../src/bootstrap');
  const app = await createApp({ logger: false });
  await app.listen(Number(process.env.LIVE_PORT ?? 0));
  const port = (app.getHttpServer().address() as AddressInfo).port;
  return { app, base: `http://127.0.0.1:${port}`, api: new Api(`http://127.0.0.1:${port}/api/v1`) };
}

export const adminConnection = () => mysql.createConnection({ host: process.env.DB_HOST ?? '127.0.0.1', port: Number(process.env.DB_PORT ?? 3307), user: process.env.DB_ADMIN_USER ?? 'root', password: process.env.DB_ADMIN_PASSWORD ?? '', database: TEST_DB, timezone: 'Z' });

export interface Res { status: number; body: any; headers: Headers }
export interface Auth { token?: string; branch?: string; session?: string; key?: string; lang?: string; reason?: string; pin?: string }

export class Api {
  constructor(readonly base: string) {}
  async call(method: string, path: string, body?: unknown, auth: Auth = {}): Promise<Res> {
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (auth.token) headers.Authorization = `Bearer ${auth.token}`;
    if (auth.branch) headers['X-Branch-Id'] = auth.branch;
    if (auth.session) headers['X-Table-Session'] = auth.session;
    if (auth.pin) headers['X-Table-Pin'] = auth.pin;
    if (auth.key) headers['Idempotency-Key'] = auth.key;
    if (auth.lang) headers['Accept-Language'] = auth.lang;
    const r = await fetch(`${this.base}${path}`, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
    const text = await r.text();
    let parsed: any = text;
    try { parsed = JSON.parse(text); } catch { /* binary or empty */ }
    return { status: r.status, body: parsed, headers: r.headers };
  }
  get = (p: string, a?: Auth) => this.call('GET', p, undefined, a);
  post = (p: string, b?: unknown, a?: Auth) => this.call('POST', p, b ?? {}, a);
  put = (p: string, b?: unknown, a?: Auth) => this.call('PUT', p, b ?? {}, a);
  patch = (p: string, b?: unknown, a?: Auth) => this.call('PATCH', p, b ?? {}, a);
  del = (p: string, a?: Auth) => this.call('DELETE', p, undefined, a);
  // Fails with the server's answer, so a broken step explains itself.
  async ok(p: Promise<Res>): Promise<any> {
    const r = await p;
    if (r.status >= 300) throw new Error(`HTTP ${r.status}: ${JSON.stringify(r.body)}`);
    return r.body.data ?? r.body;
  }
}

// TEST DOUBLE. Never available in production: PaymentProviderRegistry.register throws there.
export const testGateway = {
  code: 'testgateway',
  refs: new Map<string, { status: 'captured' | 'pending' | 'failed'; amount: string; currency: string }>(),
  async verifyCredentials() {},
  async createCheckout(i: { reference: string; amount: string; currency: string }) {
    this.refs.set(`order_${i.reference}`, { status: 'pending', amount: i.amount, currency: i.currency });
    return { providerOrderRef: `order_${i.reference}`, checkout: { provider: 'testgateway' } };
  },
  async fetchPayment(ref: string) {
    const r = this.refs.get(ref);
    return r?.status === 'captured' ? { status: 'captured' as const, providerPaymentRef: `pay_${ref}`, amount: r.amount, currency: r.currency } : { status: r?.status ?? 'pending' as 'pending' };
  },
  verifyWebhook(raw: Buffer, h: Record<string, unknown>, c: { webhookSecret?: string }) {
    const sig = createHmac('sha256', c.webhookSecret ?? '').update(raw).digest('hex');
    if (h['x-test-signature'] !== sig) { const { WebhookSignatureError } = require('../src/modules/payments/providers/provider'); throw new WebhookSignatureError('bad'); }
    const e = JSON.parse(raw.toString());
    return { eventId: e.id, type: e.type, kind: e.kind, providerOrderRef: e.orderRef, providerPaymentRef: e.paymentRef, providerRefundRef: e.refundRef, amount: e.amount, currency: e.currency, feeAmount: e.fee, raw: {} };
  },
  async refund(i: { idempotencyKey: string }) { return { providerRefundRef: `rf_${i.idempotencyKey}`, status: 'succeeded' as const }; },
  async fetchSettlements() { return [{ ref: `set_${Date.now()}`, currency: 'INR', fee: '2.36', tax: '0.36', net: '97.64', settledAt: new Date() }]; },
};

export function signWebhook(secret: string, event: Record<string, unknown>) {
  const raw = JSON.stringify(event);
  return { raw, signature: createHmac('sha256', secret).update(raw).digest('hex') };
}

export async function sendWebhook(base: string, account: string, event: Record<string, unknown>, secret: string) {
  const { raw, signature } = signWebhook(secret, event);
  const r = await fetch(`${base}/api/v1/webhooks/payments/testgateway/${account}`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-test-signature': signature }, body: raw });
  return { status: r.status, body: await r.json() as any };
}

export type App = INestApplication;
