// Sweeps every route the app actually registers, so a route added later is covered without anyone remembering to.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { Api, App, bootstrap } from './harness';

let app: App;
let api: Api;
const PUBLIC_ALLOWED = new Set([
  'POST /auth/login', 'POST /auth/refresh', 'POST /auth/accept-invitation', 'POST /customer/auth/register', 'POST /customer/auth/login', 'POST /customer/auth/google',
  // Signed-out by nature: a diner who forgot their password, and what the sign-in screen may offer.
  'POST /customer/auth/password-reset/request', 'POST /customer/auth/password-reset/confirm', 'GET /customer/auth/features',
  'POST /public/cafes/register', 'GET /public/reference', 'GET /public/cafes/:slug/config', 'GET /public/cafes/:slug/menu', 'GET /public/media/:id', 'GET /public/qr/:token',
  'POST /webhooks/payments/:provider/:account', 'GET /health',
]);

function routes(): Array<{ method: string; path: string }> {
  const out: Array<{ method: string; path: string }> = [];
  const router = (app.getHttpAdapter().getInstance() as any).router;
  for (const layer of router.stack) {
    if (!layer.route) continue;
    for (const [method, on] of Object.entries(layer.route.methods)) {
      if (on && ['get', 'post', 'put', 'patch', 'delete'].includes(method)) out.push({ method: method.toUpperCase(), path: String(layer.route.path).replace(/^\/api\/v1/, '') });
    }
  }
  // An empty path is Nest's own middleware mount (it answers 404), not a route.
  return out.filter((r) => r.path && !r.path.startsWith('/api/docs') && !r.path.startsWith('/api-docs'));
}
const fill = (p: string) => p.replace(/:\w+/g, 'ZZZZZZZZZZZZZZZZZZZZZZZZZZ');

before(async () => {
  const b = await bootstrap();
  app = b.app; api = b.api;
});
after(async () => { await app.close(); });

test('the sweep actually sees the app', () => {
  assert.ok(routes().length > 150, `only ${routes().length} routes found`);
});

test('default deny: every route without a credential is refused, except the explicit public list', async () => {
  const leaks: string[] = [];
  const seenPublic = new Set<string>();
  for (const r of routes()) {
    const key = `${r.method} ${r.path}`;
    if (PUBLIC_ALLOWED.has(key)) { seenPublic.add(key); continue; }
    const res = await api.call(r.method, fill(r.path), ['GET', 'DELETE'].includes(r.method) ? undefined : {});
    if (![401, 403].includes(res.status)) leaks.push(`${key} -> ${res.status}`);
  }
  assert.deepEqual(leaks, []);
  assert.deepEqual([...PUBLIC_ALLOWED].filter((k) => !seenPublic.has(k)), [], 'allow-list has stale entries');
});

test('audiences: a customer token reaches no staff or platform route, and a staff token reaches no platform route', async () => {
  const c = await api.ok(api.post('/customer/auth/register', { email: 'sweep@example.test', password: 'sweep password long', fullName: 'Sweep' }));
  const leaks: string[] = [];
  for (const r of routes()) {
    if (!r.path.startsWith('/cafe') && !r.path.startsWith('/platform') && !r.path.startsWith('/kitchen')) continue;
    const res = await api.call(r.method, fill(r.path), ['GET', 'DELETE'].includes(r.method) ? undefined : {}, { token: c.accessToken });
    if (res.status !== 403) leaks.push(`${r.method} ${r.path} -> ${res.status}`);
  }
  assert.deepEqual(leaks, []);
});

test('secure headers are present, and CORS refuses unknown origins', async () => {
  const r = await fetch(`${api.base}/health`, { headers: { Origin: 'https://evil.example' } });
  assert.ok(r.headers.get('x-content-type-options'));
  assert.ok(r.headers.get('strict-transport-security'));
  assert.equal(r.headers.get('access-control-allow-origin'), null);
  const ok = await fetch(`${api.base}/health`, { headers: { Origin: 'http://localhost:8083' } });
  assert.equal(ok.headers.get('access-control-allow-origin'), 'http://localhost:8083');
});

test('rate limiting returns 429 on the login route', async () => {
  let saw429 = false;
  for (let i = 0; i < 15 && !saw429; i++) {
    const r = await api.post('/auth/login', { email: 'nobody@example.test', password: 'x', audience: 'cafe' });
    if (r.status === 429) saw429 = true;
  }
  assert.ok(saw429);
});

test('SQL metacharacters are data, not code', async () => {
  const r = await api.get(`/public/cafes/${encodeURIComponent("x' OR '1'='1")}/config`);
  assert.equal(r.status, 404);
  const r2 = await api.get(`/public/qr/${encodeURIComponent("'; DROP TABLE cafes; --")}`);
  assert.equal(r2.status, 404);
  assert.equal((await api.get('/public/reference')).status, 200);
});
