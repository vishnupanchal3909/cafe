// The brief's critical scenario, end to end over real HTTP, with two cafes in different currencies at once.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { io } from 'socket.io-client';
import { adminConnection, Api, App, bootstrap, sendWebhook, testGateway } from './harness';
import { totp } from '../src/modules/identity/crypto';

let app: App;
let api: Api;
let base: string;
const PNG = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg==', 'base64');

interface Cafe { publicId: string; slug: string; branch: string; token: string; email: string; categoryId?: string; productId?: string; variantId?: string; addonId?: string; tableId?: string; qrUrl?: string; session?: string; orderId?: string; }
const A = { currency: 'INR', country: 'IN', lang: 'en' };
let a: Cafe;
let b: Cafe;
let adminToken: string;
// Ordering needs a signed-in customer; browsing does not. One diner places the test orders.
let diner: string;

async function registerCafe(name: string, currency: string, country: string, lang: string, supported: string[]): Promise<Cafe> {
  const email = `${name.toLowerCase().replace(/\W/g, '')}@example.test`;
  const r = await api.ok(api.post('/public/cafes/register', {
    owner: { email, password: 'correct horse battery', fullName: `${name} Owner` },
    cafe: { name, legalName: `${name} Pvt Ltd`, countryCode: country, currencyCode: currency, defaultLanguage: lang, timezone: country === 'IN' ? 'Asia/Kolkata' : 'Asia/Tokyo', supportedLanguages: supported },
    branch: { name: 'Main', addressLine1: '1 High St', city: country === 'IN' ? 'Pune' : 'Tokyo', stateCode: country === 'IN' ? 'MH' : undefined },
  }));
  const login = await api.ok(api.post('/auth/login', { email, password: 'correct horse battery', audience: 'cafe' }));
  return { publicId: r.cafePublicId, slug: r.slug, branch: r.branchPublicId, token: login.accessToken, email };
}
const staff = (c: Cafe) => ({ token: c.token, branch: c.branch });

before(async () => {
  // This suite logs in far more often than a person. security.test.ts checks the real limits.
  process.env.RATE_LIMIT_SCALE = '100';
  const b0 = await bootstrap();
  app = b0.app; api = b0.api; base = b0.base;
  const { PaymentProviderRegistry } = await import('../src/modules/payments/payments.service');
  app.get(PaymentProviderRegistry).register(testGateway as never);
  const conn = await adminConnection();
  await conn.query(`INSERT INTO payment_providers (code, name) VALUES ('testgateway', 'Test gateway (tests only)')`);
  await conn.end();
});
after(async () => { await app.close(); });

test('platform: admin bootstraps with mandatory MFA, and cannot act until enrolled', async () => {
  const { hashPassword } = await import('../src/modules/identity/crypto');
  const conn = await adminConnection();
  const [u]: any = await conn.query(`INSERT INTO users SET public_id = ?, email = 'admin@example.test', password_hash = ?, full_name = 'Admin', status = 'active', is_platform_user = 1`, ['ADMINADMINADMINADMINADMIN1', await hashPassword('super secret admin pw')]);
  await conn.query(`INSERT INTO user_roles (user_id, role_id) SELECT ?, id FROM roles WHERE code = 'super_admin' AND cafe_id IS NULL`, [u.insertId]);
  await conn.end();
  const login = await api.ok(api.post('/auth/login', { email: 'admin@example.test', password: 'super secret admin pw', audience: 'platform' }));
  assert.equal(login.mfaEnrollmentRequired, true);
  assert.equal((await api.get('/platform/cafes', { token: login.accessToken })).body.error.code, 'MFA_ENROLLMENT_REQUIRED');
  const { secret } = await api.ok(api.post('/auth/mfa/enroll', {}, { token: login.accessToken }));
  assert.equal((await api.post('/auth/mfa/confirm', { code: '000000' }, { token: login.accessToken })).status, 401);
  const confirmed = await api.ok(api.post('/auth/mfa/confirm', { code: totp(secret) }, { token: login.accessToken }));
  adminToken = confirmed.accessToken;
  assert.equal((await api.get('/platform/cafes', { token: adminToken })).status, 200);
  assert.equal((await api.post('/auth/login', { email: 'admin@example.test', password: 'super secret admin pw', audience: 'platform' })).body.error.code, 'MFA_REQUIRED');
});

test('1-2. register two cafes with owners, pending approval until the admin acts', async () => {
  a = await registerCafe('Chai House', 'INR', 'IN', 'en', ['hi', 'ar']);
  b = await registerCafe('Tokyo Beans', 'JPY', 'JP', 'ja', ['en']);
  assert.equal((await api.get(`/public/cafes/${a.slug}/config`)).status, 404);
  const pending = await api.ok(api.get('/platform/cafes?status=pending_approval', { token: adminToken }));
  assert.equal(pending.length, 2);
  for (const c of [a, b]) await api.ok(api.post(`/platform/cafes/${c.publicId}/status`, { status: 'active', reason: 'documents checked' }, { token: adminToken }));
  assert.equal((await api.get(`/public/cafes/${a.slug}/config`)).status, 200);
  diner = (await api.ok(api.post('/customer/auth/register', { email: 'table-diner@example.test', password: 'table diner password', fullName: 'Table Diner' }))).accessToken;
});

test('3. branding is per cafe, loaded from config, and survives validation', async () => {
  const upload = new FormData();
  upload.append('file', new Blob([PNG], { type: 'image/png' }), 'logo.png');
  const r = await fetch(`${api.base}/cafe/media?kind=logo`, { method: 'POST', headers: { Authorization: `Bearer ${a.token}` }, body: upload });
  assert.equal(r.status, 201);
  const logo = (await r.json() as any).data;
  await api.ok(api.put('/cafe/theme', { primaryColor: '#112233', menuLayout: 'grid', logoAssetId: logo.publicId }, { token: a.token }));
  assert.equal((await api.put('/cafe/theme', { primaryColor: 'red' }, { token: a.token })).status, 400);
  const cfg = await api.ok(api.get(`/public/cafes/${a.slug}/config`));
  assert.equal(cfg.theme.primaryColor, '#112233');
  assert.equal(cfg.theme.menuLayout, 'grid');
  assert.equal((await api.ok(api.get(`/public/cafes/${b.slug}/config`))).theme.primaryColor === '#112233', false);
  const img = await fetch(`${base}${cfg.cafe.logoUrl}`);
  assert.equal(img.headers.get('content-type'), 'image/png');

  const fake = new FormData();
  fake.append('file', new Blob([Buffer.from('<svg onload=alert(1)>')], { type: 'image/png' }), 'x.png');
  assert.equal((await fetch(`${api.base}/cafe/media?kind=logo`, { method: 'POST', headers: { Authorization: `Bearer ${a.token}` }, body: fake })).status, 400);
});

test('4. language and currency: precision and RTL flow through config', async () => {
  const cfgA = await api.ok(api.get(`/public/cafes/${a.slug}/config`));
  assert.deepEqual(cfgA.currency, { code: 'INR', symbol: '₹', minorUnit: 2 });
  assert.ok(cfgA.languages.some((l: any) => l.code === 'ar' && l.direction === 'rtl'));
  assert.equal((await api.ok(api.get(`/public/cafes/${b.slug}/config`))).currency.minorUnit, 0);
});

test('5-6. menu with translations, variants and add-ons; JPY rejects fractional prices', async () => {
  await api.ok(api.post('/cafe/tax-categories', { code: 'FOOD', name: 'Food' }, { token: a.token }));
  await api.ok(api.post('/cafe/tax-categories/FOOD/rates', { componentCode: 'CGST', displayName: 'CGST', ratePercent: '2.5', appliesTo: 'intra_region', validFrom: '2020-01-01' }, { token: a.token }));
  await api.ok(api.post('/cafe/tax-categories/FOOD/rates', { componentCode: 'SGST', displayName: 'SGST', ratePercent: '2.5', appliesTo: 'intra_region', validFrom: '2020-01-01' }, { token: a.token }));
  await api.ok(api.post('/cafe/tax-categories/FOOD/rates', { componentCode: 'IGST', displayName: 'IGST', ratePercent: '5', appliesTo: 'inter_region', validFrom: '2020-01-01' }, { token: a.token }));

  assert.equal((await api.post('/cafe/categories', { translations: [{ language: 'hi', name: 'पेय' }] }, { token: a.token })).body.error.code, 'DEFAULT_LANGUAGE_TRANSLATION_REQUIRED');
  a.categoryId = (await api.ok(api.post('/cafe/categories', { translations: [{ language: 'en', name: 'Drinks' }, { language: 'hi', name: 'पेय' }, { language: 'ar', name: 'مشروبات' }] }, { token: a.token }))).publicId;
  a.productId = (await api.ok(api.post('/cafe/products', { categoryId: a.categoryId, basePrice: '100.00', taxCategoryId: 'FOOD', dietaryClass: 'veg', translations: [{ language: 'en', name: 'Masala Chai' }, { language: 'hi', name: 'मसाला चाय' }, { language: 'ar', name: 'شاي' }] }, { token: a.token }))).publicId;
  a.variantId = (await api.ok(api.post(`/cafe/products/${a.productId}/variants`, { price: '150.00', isDefault: true, translations: [{ language: 'en', name: 'Large' }] }, { token: a.token }))).publicId;
  const group = await api.ok(api.post('/cafe/addon-groups', { maxSelect: 2, translations: [{ language: 'en', name: 'Extras' }], addons: [{ price: '20.00', translations: [{ language: 'en', name: 'Ginger' }] }] }, { token: a.token }));
  a.addonId = group.addons[0];
  await api.ok(api.put(`/cafe/products/${a.productId}/addon-groups`, { ids: [group.publicId] }, { token: a.token }));

  b.categoryId = (await api.ok(api.post('/cafe/categories', { translations: [{ language: 'ja', name: '飲み物' }] }, { token: b.token }))).publicId;
  assert.equal((await api.post('/cafe/products', { categoryId: b.categoryId, basePrice: '500.50', translations: [{ language: 'ja', name: '抹茶' }] }, { token: b.token })).body.error.code, 'PRICE_PRECISION_INVALID');
  b.productId = (await api.ok(api.post('/cafe/products', { categoryId: b.categoryId, basePrice: '500', translations: [{ language: 'ja', name: '抹茶' }] }, { token: b.token }))).publicId;

  const hi = await api.ok(api.get(`/public/cafes/${a.slug}/menu?lang=hi`));
  const product = hi.products.find((p: any) => p.publicId === a.productId);
  assert.equal(product.name, 'मसाला चाय');
  assert.equal(product.resolvedLanguage, 'hi');
  assert.equal((await api.ok(api.get(`/public/cafes/${a.slug}/menu?lang=fr`))).products[0].name, 'Masala Chai');
  assert.equal(hi.products[0].price.currency, 'INR');
});

test('7-8. tables get unique unguessable QR codes; regeneration kills the old one', async () => {
  for (const c of [a, b]) {
    c.tableId = (await api.ok(api.post('/cafe/tables', { tableNumber: 'T1', capacity: 4 }, staff(c)))).publicId;
    c.qrUrl = (await api.ok(api.get(`/cafe/tables/${c.tableId}/qr`, staff(c)))).url;
  }
  const old = a.qrUrl!;
  const regenerated = await api.ok(api.post(`/cafe/tables/${a.tableId}/qr/regenerate`, {}, staff(a)));
  assert.notEqual(regenerated.url, old);
  assert.ok(regenerated.png.startsWith('data:image/png'));
  assert.equal((await api.get(`/public/qr/${old.split('/t/')[1]}`)).status, 404);
  a.qrUrl = regenerated.url;
  assert.equal(a.qrUrl!.split('/t/')[1]!.length >= 43, true);
});

test('9. scanning a QR identifies cafe and table from the token alone', async () => {
  for (const c of [a, b]) {
    const r = await api.ok(api.get(`/public/qr/${c.qrUrl!.split('/t/')[1]}?lang=en`));
    assert.equal(r.config.cafe.publicId, c.publicId);
    assert.equal(r.table.number, 'T1');
    c.session = r.session.token;
  }
  const again = await api.ok(api.get(`/public/qr/${a.qrUrl!.split('/t/')[1]}`));
  assert.equal(again.session.token, a.session, 'a second diner joins the same session');
  assert.equal((await api.get('/public/qr/not-a-real-token')).status, 404);
});

let socketEvents: any[] = [];
let kitchenSocket: ReturnType<typeof io>;
let kitchenToken: string;
let dispatch: () => Promise<number>;

test('10-11. placing an order: server prices it, and the kitchen is notified live', async () => {
  const { RealtimeService } = await import('../src/modules/realtime/realtime.service');
  const rt = app.get(RealtimeService);
  dispatch = () => rt.dispatchOnce();
  await dispatch();

  const invite = await api.ok(api.post('/cafe/staff', { email: 'kitchen@chai.test', fullName: 'Cook', roleCode: 'kitchen_staff' }, { token: a.token }));
  await api.ok(api.post('/auth/accept-invitation', { token: invite.invitationToken, password: 'cook password long' }));
  kitchenToken = (await api.ok(api.post('/auth/login', { email: 'kitchen@chai.test', password: 'cook password long', audience: 'kitchen' }))).accessToken;

  kitchenSocket = io(base, { auth: { token: kitchenToken }, transports: ['websocket'] });
  kitchenSocket.on('event', (e) => socketEvents.push(e));
  await new Promise<void>((res, rej) => { kitchenSocket.once('ready', () => res()); kitchenSocket.once('connect_error', rej); });

  // A guest at the table may browse but not order: the owner's rule, enforced here and not only in the app.
  const guest = await api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session });
  assert.equal(guest.status, 401);
  assert.equal(guest.body.error.code, 'CUSTOMER_LOGIN_REQUIRED');
  assert.equal((await api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: kitchenToken })).body.error.code, 'CUSTOMER_LOGIN_REQUIRED', 'a staff login is not a customer login');
  assert.equal((await api.get(`/public/cafes/${a.slug}/menu?lang=en`)).status, 200, 'the menu stays open to guests');

  // A client price is refused, not ignored silently: the DTO rejects unknown fields.
  const tampered = await api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1, unitPrice: '1.00' }] }, { session: a.session, token: diner });
  assert.equal(tampered.status, 400);
  assert.equal((await api.post('/customer/orders', { cafeId: 'x', items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner })).status, 400);
  assert.equal((await api.post('/customer/orders', { items: [{ productId: a.productId, quantity: 1 }] }, { session: a.session, token: diner })).body.error.code, 'VARIANT_REQUIRED');

  const key = 'order-key-00000000000000000001';
  const body = { language: 'hi', notes: 'less sugar', items: [{ productId: a.productId, variantId: a.variantId, quantity: 2, addons: [{ addonId: a.addonId }], notes: 'hot' }] };
  const order = await api.ok(api.post('/customer/orders', body, { session: a.session, token: diner, key }));
  a.orderId = order.publicId;
  // (150 + 20) x 2 = 340. Tax 5% = 17. Total 357.
  assert.equal(order.subtotal.amount, '340');
  assert.equal(order.tax.amount, '17');
  assert.equal(order.total.amount, '357');
  assert.equal(order.items[0].name, 'मसाला चाय');
  assert.deepEqual(order.items[0].taxes.map((t: any) => t.code).sort(), ['CGST', 'SGST']);

  const retry = await api.ok(api.post('/customer/orders', body, { session: a.session, token: diner, key }));
  assert.equal(retry.publicId, order.publicId, 'a retried request returns the same order');
  assert.equal((await api.post('/customer/orders', { ...body, notes: 'different' }, { session: a.session, token: diner, key })).body.error.code, 'IDEMPOTENCY_KEY_REUSED');

  await dispatch();
  await new Promise((r) => setTimeout(r, 100));
  assert.ok(socketEvents.some((e) => e.type === 'order.placed' && e.payload.orderId === order.publicId && e.seq > 0));
});

test('12. kitchen works the ticket, order status rolls up, and the guest can track it', async () => {
  const kitchen = { token: kitchenToken, branch: a.branch };
  const tickets = await api.ok(api.get('/kitchen/tickets', kitchen));
  assert.equal(tickets.length, 1);
  assert.equal(tickets[0].table_number, 'T1');
  assert.equal(tickets[0].items[0].quantity, 2);
  assert.equal(tickets[0].items[0].addons[0].name, 'Ginger');
  assert.equal(tickets[0].items[0].notes, 'hot');

  // The kitchen role cannot reach money or menu changes.
  assert.equal((await api.get('/cafe/payments', kitchen)).status, 403, 'wrong audience');
  assert.equal((await api.post('/cafe/products', {}, kitchen)).status, 403);

  const id = tickets[0].public_id;
  assert.equal((await api.post(`/kitchen/tickets/${id}/status`, { status: 'ready' }, kitchen)).body.error.code, 'TICKET_ILLEGAL_TRANSITION');
  await api.ok(api.post(`/kitchen/tickets/${id}/status`, { status: 'accepted' }, kitchen));
  assert.equal((await api.ok(api.get(`/customer/orders/${a.orderId}`, { session: a.session }))).status, 'accepted');
  await api.ok(api.post(`/kitchen/tickets/${id}/status`, { status: 'preparing' }, kitchen));
  await api.ok(api.post(`/kitchen/tickets/${id}/status`, { status: 'ready' }, kitchen));
  assert.equal((await api.ok(api.get(`/customer/orders/${a.orderId}`, { session: a.session }))).status, 'ready');
  assert.equal((await api.post(`/cafe/orders/${a.orderId}/status`, { status: 'completed' }, staff(a))).body.error.code, 'ORDER_NOT_PAID');

  await dispatch();
  await new Promise((r) => setTimeout(r, 100));
  assert.ok(socketEvents.some((e) => e.type === 'order.ready'));
});

test('13. payment: a client cannot confirm it; a signed webhook can, exactly once', async () => {
  const noAccount = await api.post(`/customer/orders/${a.orderId}/payments`, { methodCode: 'upi' }, { session: a.session, key: 'pay-noacct-1' });
  assert.equal(noAccount.body.error.code, 'ONLINE_PAYMENT_NOT_CONFIGURED');

  const account = await api.ok(api.put('/cafe/gateway-accounts', { providerCode: 'testgateway', environment: 'sandbox', keyId: 'k', keySecret: 's', webhookSecret: 'hook-secret' }, { token: a.token }));
  assert.equal((await api.post(`/customer/orders/${a.orderId}/payments`, { methodCode: 'upi' }, { session: a.session, key: 'pay-unverified' })).body.error.code, 'ONLINE_PAYMENT_NOT_CONFIGURED', 'saved keys stay inactive until they pass a live check');
  await api.ok(api.post(`/cafe/gateway-accounts/${account.publicId}/test`, {}, { token: a.token }));
  const listed = await api.ok(api.get('/cafe/gateway-accounts', { token: a.token }));
  assert.equal(JSON.stringify(listed).includes('hook-secret'), false, 'secrets are never returned');
  await api.ok(api.put('/cafe/payment-methods', { methods: ['cash', 'upi'] }, { token: a.token }));
  const accountId = account.publicId;

  assert.equal((await api.post(`/customer/orders/${a.orderId}/payments`, { methodCode: 'upi', amount: '9999.00' }, { session: a.session, key: 'pay-over' })).body.error.code, 'AMOUNT_EXCEEDS_BALANCE');
  const pay = await api.ok(api.post(`/customer/orders/${a.orderId}/payments`, { methodCode: 'upi' }, { session: a.session, key: 'pay-001' }));
  assert.equal(pay.status, 'pending');
  assert.equal(pay.amount.amount, '357');
  // Polling after a client "success" does not change anything: the provider still says pending.
  assert.equal((await api.ok(api.get(`/customer/payments/${pay.paymentId}`, { session: a.session }))).status, 'pending');

  const orderRef = `order_${pay.paymentId}`;
  const event = { id: 'ev-1', type: 'capture', kind: 'captured', orderRef, paymentRef: 'pay_abc', amount: '357', currency: 'INR', fee: '7.14' };
  assert.equal((await sendWebhook(base, accountId, event, 'WRONG-SECRET')).status, 401);
  assert.equal((await api.ok(api.get(`/customer/orders/${a.orderId}`, { session: a.session }))).paymentStatus, 'unpaid');

  const conn = await adminConnection();
  // A valid signature for the wrong amount is flagged and never credited.
  const bad = { ...event, id: 'ev-bad', amount: '1' };
  await sendWebhook(base, accountId, bad, 'hook-secret');
  assert.equal((await api.ok(api.get(`/customer/orders/${a.orderId}`, { session: a.session }))).paymentStatus, 'unpaid');
  const [[failed]]: any = await conn.query(`SELECT status FROM payment_webhooks WHERE provider_event_id = 'ev-bad'`);
  assert.equal(failed.status, 'failed');

  assert.equal((await sendWebhook(base, accountId, event, 'hook-secret')).status, 200);
  assert.deepEqual((await sendWebhook(base, accountId, event, 'hook-secret')).body.data, { received: true, duplicate: true });
  const paid = await api.ok(api.get(`/customer/orders/${a.orderId}`, { session: a.session }));
  assert.equal(paid.paymentStatus, 'paid');
  assert.equal(paid.paid.amount, '357');
  const [[{ n }]]: any = await conn.query(`SELECT COUNT(*) n FROM journal_entries WHERE source_type = 'payment'`);
  assert.equal(n, 1, 'a replayed webhook does not double-post');
  await conn.end();
});

test('14. a gapless invoice is issued with the tax breakdown and the seller snapshot', async () => {
  const list = await api.ok(api.get('/cafe/invoices', { token: a.token }));
  assert.equal(list.length, 1);
  const inv = await api.ok(api.get(`/cafe/invoices/${list[0].public_id}`, { token: a.token }));
  assert.match(inv.number, /^INV\/MAIN\/\d{4}\/1$/);
  assert.equal(inv.total.amount, '357');
  assert.deepEqual(inv.taxBreakdown.map((t: any) => [t.code, t.amount.amount]).sort(), [['CGST', '8.5'], ['SGST', '8.5']]);
  assert.equal(inv.seller.legalName, 'Chai House Pvt Ltd');
  const pdf = await fetch(`${api.base}/cafe/invoices/${list[0].public_id}/pdf`, { headers: { Authorization: `Bearer ${a.token}` } });
  assert.equal(pdf.headers.get('content-type'), 'application/pdf');
  assert.equal(Buffer.from(await pdf.arrayBuffer()).subarray(0, 4).toString(), '%PDF');
  await api.ok(api.post(`/cafe/orders/${a.orderId}/status`, { status: 'served' }, staff(a)));
  await api.ok(api.post(`/cafe/orders/${a.orderId}/status`, { status: 'completed' }, staff(a)));
});

const today = () => new Date(Date.now() + 86400_000).toISOString().slice(0, 10);

test('15-16. reports and the ledger agree, and the books balance', async () => {
  const sales = await api.ok(api.get(`/cafe/reports/sales?from=2020-01-01&to=${today()}`, staff(a)));
  const row = sales.rows[0];
  assert.equal(row.gross_sales, '340.0000');
  assert.equal(row.tax_collected, '17.0000');
  assert.equal(row.collected, '357.0000');
  assert.equal(row.net_sales, '340.0000');

  const tb = await api.ok(api.get(`/cafe/reports/trial-balance?from=2020-01-01&to=${today()}`, { token: a.token }));
  const debit = tb.reduce((s: number, r: any) => s + Number(r.debit), 0);
  const credit = tb.reduce((s: number, r: any) => s + Number(r.credit), 0);
  assert.equal(debit.toFixed(4), credit.toFixed(4));
  const byCode = Object.fromEntries(tb.map((r: any) => [r.code, r]));
  assert.equal(byCode['4000'].credit, '340.0000', 'revenue');
  assert.equal(byCode['2100'].credit, '17.0000', 'tax payable');
  assert.equal(byCode['1100'].debit, '357.0000', 'gateway clearing');
  assert.equal(byCode['1300'].debit, byCode['1300'].credit, 'receivable clears');

  const bs = await api.ok(api.get(`/cafe/reports/balance-sheet?asOf=${today()}`, { token: a.token }));
  assert.equal(bs.balanced, true);
  const pnl = await api.ok(api.get(`/cafe/reports/pnl?from=2020-01-01&to=${today()}`, { token: a.token }));
  assert.equal(pnl.totalRevenue, '340');

  const dash = await api.ok(api.get(`/cafe/analytics?from=2020-01-01&to=${today()}`, staff(a)));
  assert.equal(dash.orders, 1);
  assert.equal(dash.topProducts[0].name, 'मसाला चाय');
  // Regression: this was NULL (shown as midnight) on servers without MySQL timezone tables.
  const istHour = Number(new Intl.DateTimeFormat('en-US', { timeZone: 'Asia/Kolkata', hour: '2-digit', hourCycle: 'h23' }).format(new Date()));
  assert.equal(dash.peakHours.length, 1);
  assert.ok(Math.abs(dash.peakHours[0].local_hour - istHour) <= 1, `peak hour ${dash.peakHours[0].local_hour} vs now ${istHour}`);

  const xlsx = await fetch(`${api.base}/cafe/reports/sales/export?format=xlsx&from=2020-01-01&to=${today()}`, { headers: { Authorization: `Bearer ${a.token}` } });
  assert.equal(xlsx.status, 200);
  assert.equal(Buffer.from(await xlsx.arrayBuffer()).subarray(0, 2).toString(), 'PK');
});

test('17. another cafe cannot reach any of it', async () => {
  const other = staff(b);
  assert.equal((await api.get(`/cafe/orders/${a.orderId}`, other)).status, 404);
  assert.equal((await api.post(`/cafe/orders/${a.orderId}/status`, { status: 'cancelled', reason: 'attack' }, other)).status, 404);
  assert.equal((await api.patch(`/cafe/products/${a.productId}`, { basePrice: '1' }, other)).status, 404);
  assert.equal((await api.del(`/cafe/categories/${a.categoryId}`, other)).status, 404);
  assert.equal((await api.get(`/cafe/tables/${a.tableId}/qr`, other)).status, 404);
  assert.equal((await api.post('/cafe/payments/cash', { orderId: a.orderId }, { ...other, key: 'attack-1' })).status, 404);
  assert.equal((await api.get(`/cafe/orders/${a.orderId}`, { token: b.token, branch: a.branch })).status, 404, 'a branch id from another cafe is refused');
  const orders = await api.ok(api.get('/cafe/orders', other));
  assert.equal(orders.length, 0);
  const invoices = await api.ok(api.get('/cafe/invoices', { token: b.token }));
  assert.equal(invoices.length, 0);

  assert.equal((await api.get(`/customer/orders/${a.orderId}`, { session: b.session })).status, 404);
  assert.equal((await api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: b.session, token: diner })).status, 404, "another cafe's product");
  assert.equal((await api.post(`/customer/orders/${a.orderId}/payments`, { methodCode: 'upi' }, { session: b.session, key: 'attack-2' })).status, 404);
});

test('JPY cafe: a parallel order in another currency stays correct and separate', async () => {
  const conn = await adminConnection();
  const order = await api.ok(api.post('/customer/orders', { items: [{ productId: b.productId, quantity: 3 }] }, { session: b.session, token: diner }));
  assert.equal(order.total.amount, '1500');
  assert.equal(order.total.currency, 'JPY');
  const cash = await api.ok(api.post('/cafe/payments/cash', { orderId: order.publicId }, { ...staff(b), key: 'cash-jpy-1' }));
  assert.equal(cash.status, 'succeeded');
  assert.equal((await api.post('/cafe/payments/cash', { orderId: order.publicId, amount: '1' }, { ...staff(b), key: 'cash-jpy-2' })).body.error.code, 'ORDER_ALREADY_PAID');
  const [[row]]: any = await conn.query(`SELECT currency_code, invoice_number FROM invoices WHERE order_id = (SELECT id FROM orders WHERE public_id = ?)`, [order.publicId]);
  assert.equal(row.currency_code, 'JPY');
  assert.match(row.invoice_number, /\/1$/, 'numbering is per cafe');
  await conn.end();
});

test('refunds need two steps, can be partial, issue a credit note, and reverse in the ledger', async () => {
  const payments = await api.ok(api.get('/cafe/payments', staff(a)));
  const pid = payments[0].public_id;
  assert.equal((await api.post(`/cafe/payments/${pid}/refunds`, { amount: '500.00', reason: 'too much' }, { ...staff(a), key: 'rf-over' })).body.error.code, 'REFUND_EXCEEDS_PAYMENT');
  const r = await api.ok(api.post(`/cafe/payments/${pid}/refunds`, { amount: '105.00', reason: 'wrong item' }, { ...staff(a), key: 'rf-1' }));
  assert.equal(r.status, 'requested');
  const approved = await api.ok(api.post(`/cafe/refunds/${r.refundId}/approve`, {}, staff(a)));
  assert.equal(approved.status, 'succeeded');
  assert.equal((await api.post(`/cafe/refunds/${r.refundId}/approve`, {}, staff(a))).body.error.code, 'REFUND_NOT_PENDING');
  const order = await api.ok(api.get(`/cafe/orders/${a.orderId}`, staff(a)));
  assert.equal(order.paymentStatus, 'partially_refunded');
  assert.equal(order.refunded.amount, '105');
  const invoices = await api.ok(api.get('/cafe/invoices', { token: a.token }));
  const cn = invoices.find((i: any) => i.document_type === 'credit_note');
  assert.ok(cn, 'credit note issued');
  assert.equal(cn.total_amount, '105.0000');
  const tb = await api.ok(api.get(`/cafe/reports/trial-balance?from=2020-01-01&to=${today()}`, { token: a.token }));
  const byCode = Object.fromEntries(tb.map((x: any) => [x.code, x]));
  assert.equal(byCode['4200'].debit, '100.0000', 'sales returns, net of tax');
  assert.equal(byCode['2100'].debit, '5.0000', 'tax reversed');
  const bs = await api.ok(api.get(`/cafe/reports/balance-sheet?asOf=${today()}`, { token: a.token }));
  assert.equal(bs.balanced, true);
});

test('inventory: recipe consumption at acceptance, average cost, COGS, reversal on cancel, low-stock alert', async () => {
  const ing = await api.ok(api.post('/cafe/ingredients', { name: 'Tea leaves', unitCode: 'g' }, { token: a.token }));
  await api.ok(api.put(`/cafe/products/${a.productId}/recipe`, { variantId: a.variantId, items: [{ ingredientId: ing.publicId, quantity: '10' }] }, { token: a.token }));
  await api.ok(api.post('/cafe/stock/movements', { ingredientId: ing.publicId, type: 'stock_in', quantity: '100', unitCost: '1.000000', expiresOn: '2030-01-01' }, staff(a)));
  await api.ok(api.post('/cafe/stock/movements', { ingredientId: ing.publicId, type: 'stock_in', quantity: '100', unitCost: '3.000000' }, staff(a)));
  const stock = (await api.ok(api.get('/cafe/stock', staff(a)))).find((s: any) => s.public_id === ing.publicId);
  assert.equal(stock.on_hand_quantity, '200.0000');
  assert.equal(stock.average_unit_cost, '2.000000', 'moving weighted average');
  await api.ok(api.patch(`/cafe/stock/${ing.publicId}/reorder-level`, { level: '190' }, staff(a)));

  const onHand = async () => (await api.ok(api.get('/cafe/stock', staff(a)))).find((s: any) => s.public_id === ing.publicId).on_hand_quantity;
  const order = await api.ok(api.post('/cafe/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 2 }] }, staff(a)));
  assert.equal(await onHand(), '200.0000', 'nothing consumed before acceptance');
  await api.ok(api.post(`/cafe/orders/${order.publicId}/status`, { status: 'accepted' }, staff(a)));
  assert.equal(await onHand(), '180.0000');
  const conn = await adminConnection();
  const [[low]]: any = await conn.query(`SELECT COUNT(*) n FROM outbox_events WHERE event_type = 'stock.low'`);
  assert.equal(low.n, 1, 'crossing the reorder level raises one alert');
  await conn.end();
  const tb = await api.ok(api.get(`/cafe/reports/trial-balance?from=2020-01-01&to=${today()}`, { token: a.token }));
  assert.equal(tb.find((r: any) => r.code === '5000').debit, '40.0000', 'COGS at average cost');

  await api.ok(api.post(`/cafe/orders/${order.publicId}/status`, { status: 'cancelled', reason: 'customer left' }, staff(a)));
  assert.equal(await onHand(), '200.0000', 'reversed before preparation');
  assert.equal((await api.post(`/cafe/orders/${order.publicId}/status`, { status: 'accepted' }, staff(a))).body.error.code, 'ORDER_ILLEGAL_TRANSITION');

  assert.equal((await api.post('/cafe/stock/movements', { ingredientId: ing.publicId, type: 'wastage', quantity: '5' }, staff(a))).body.error.code, 'REASON_REQUIRED');
  await api.ok(api.post('/cafe/stock/movements', { ingredientId: ing.publicId, type: 'wastage', quantity: '5', reason: 'spilled' }, staff(a)));
  assert.equal(await onHand(), '195.0000');
  const sup = await api.ok(api.post('/cafe/suppliers', { name: 'Assam Tea Co' }, { token: a.token }));
  const po = await api.ok(api.post('/cafe/purchase-orders', { supplierId: sup.publicId, items: [{ ingredientId: ing.publicId, quantity: '50', unitCost: '4' }] }, staff(a)));
  assert.equal((await api.post(`/cafe/purchase-orders/${po.publicId}/receive`, { lines: [{ ingredientId: ing.publicId, quantity: '60' }] }, staff(a))).body.error.code, 'RECEIVE_QUANTITY_INVALID');
  assert.equal((await api.ok(api.post(`/cafe/purchase-orders/${po.publicId}/receive`, { lines: [{ ingredientId: ing.publicId, quantity: '50' }] }, staff(a)))).status, 'received');
  assert.equal(await onHand(), '245.0000');
  const si = await api.ok(api.post('/cafe/supplier-invoices', { supplierId: sup.publicId, purchaseOrderId: po.publicId, number: 'A-1', subtotal: '200', invoiceDate: '2026-06-01' }, { token: a.token }));
  assert.equal((await api.post(`/cafe/supplier-invoices/${si.publicId}/payments`, { amount: '500', methodCode: 'cash', paidOn: '2026-06-02' }, { token: a.token })).body.error.code, 'PAYMENT_EXCEEDS_INVOICE');
  assert.equal((await api.ok(api.post(`/cafe/supplier-invoices/${si.publicId}/payments`, { amount: '200', methodCode: 'cash', paidOn: '2026-06-02' }, { token: a.token }))).status, 'paid');
  assert.equal((await api.ok(api.get(`/cafe/reports/balance-sheet?asOf=${today()}`, { token: a.token }))).balanced, true);
});

test('every role can open its workspace, and only managers and owners see the full profile', async () => {
  const invite = await api.ok(api.post('/cafe/staff', { email: 'waiter@chai.test', fullName: 'Wasim', roleCode: 'waiter' }, { token: a.token }));
  await api.ok(api.post('/auth/accept-invitation', { token: invite.invitationToken, password: 'waiter password long' }));
  const waiter = (await api.ok(api.post('/auth/login', { email: 'waiter@chai.test', password: 'waiter password long', audience: 'cafe' }))).accessToken;
  const ws = await api.ok(api.get('/cafe/workspace', { token: waiter }));
  assert.equal(ws.name, 'Chai House');
  assert.equal(ws.currencyCode, 'INR');
  assert.ok(ws.branches.length >= 1);
  assert.ok(ws.permissions.includes('orders.read') && !ws.permissions.includes('reports.read'));
  assert.deepEqual(ws.user, { fullName: 'Wasim', email: 'waiter@chai.test', roles: [{ code: 'waiter', name: 'Waiter' }] }, 'the portal can say who is signed in, and as what');
  assert.equal(ws.legalName, undefined, 'no legal, tax or contact details');
  assert.equal(ws.businessRegistrationNumber, undefined);
  assert.equal((await api.get('/cafe/profile', { token: waiter })).status, 403);
  assert.equal((await api.ok(api.get('/cafe/workspace', { token: a.token }))).permissions.includes('reports.read'), true);
});

test('coupons respect limits; loyalty earns on paid orders for signed-in customers and restores on cancel', async () => {
  await api.ok(api.post('/cafe/coupons', { code: 'save10', discountType: 'percent', percentValue: '10', maxRedemptions: 1 }, { token: a.token }));
  const order = await api.ok(api.post('/customer/orders', { couponCode: 'SAVE10', items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner }));
  assert.equal(order.discount.amount, '15');
  // 135 taxable; each 2.5% component rounds 3.375 up to 3.38.
  assert.equal(order.total.amount, '141.76');
  assert.equal((await api.post('/customer/orders', { couponCode: 'SAVE10', items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner })).body.error.code, 'COUPON_EXHAUSTED');
  await api.ok(api.post(`/cafe/orders/${order.publicId}/status`, { status: 'cancelled', reason: 'test' }, staff(a)));
  const again = await api.ok(api.post('/customer/orders', { couponCode: 'SAVE10', items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner }));
  assert.equal(again.discount.amount, '15', 'cancelling releases the redemption');
  await api.ok(api.post(`/cafe/orders/${again.publicId}/status`, { status: 'cancelled', reason: 'test' }, staff(a)));

  await api.ok(api.put('/cafe/loyalty-program', { isActive: true, pointsPerCurrencyUnit: '1', currencyValuePerPoint: '0.50', minRedeemPoints: 10 }, { token: a.token }));
  const c = await api.ok(api.post('/customer/auth/register', { email: 'diner@example.test', password: 'diner password long', fullName: 'Diner', language: 'hi' }));
  const session = { session: a.session, token: c.accessToken };
  const o = await api.ok(api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, session));
  await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId }, { ...staff(a), key: 'cash-loyal-1' }));
  const loyalty = await api.ok(api.get(`/customer/cafes/${a.slug}/loyalty`, { token: c.accessToken }));
  assert.equal(loyalty.balance, 157);
  const redeem = await api.ok(api.post('/customer/orders', { redeemPoints: 100, items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, session));
  assert.equal(redeem.discount.amount, '50');
  assert.equal((await api.ok(api.get(`/customer/cafes/${a.slug}/loyalty`, { token: c.accessToken }))).balance, 57);
  await api.ok(api.post(`/cafe/orders/${redeem.publicId}/status`, { status: 'cancelled', reason: 'test' }, staff(a)));
  assert.equal((await api.ok(api.get(`/customer/cafes/${a.slug}/loyalty`, { token: c.accessToken }))).balance, 157);
  assert.equal((await api.ok(api.get('/customer/history', { token: c.accessToken }))).length, 2);


  // Cafe B never met this customer, so it cannot see them.
  const emails = async (cafe: Cafe) => (await api.ok(api.get('/cafe/customers', { token: cafe.token }))).map((r: { email: string | null }) => r.email);
  assert.ok(!(await emails(b)).includes('diner@example.test'));
  assert.ok((await emails(a)).includes('diner@example.test'));

  // A ready order leaves a localized notification in the customer's inbox.
  const tracked = await api.ok(api.post('/customer/orders', { language: 'hi', items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, session));
  await api.ok(api.post(`/cafe/orders/${tracked.publicId}/status`, { status: 'accepted' }, staff(a)));
  await api.ok(api.post(`/cafe/orders/${tracked.publicId}/status`, { status: 'ready' }, staff(a)));
  const inbox = await api.ok(api.get('/notifications', { token: c.accessToken }));
  assert.equal(inbox[0].title, 'आपका ऑर्डर तैयार है');
  assert.ok(inbox[0].body.includes(String(tracked.orderNumber)));

  await api.ok(api.del('/customer/account', { token: c.accessToken }));
  // A deleted customer's token can no longer attach to a guest order at the table.
  assert.equal((await api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, session)).status, 401);
  const after = await emails(a);
  assert.ok(!after.includes('diner@example.test') && after.includes(null), 'erasure removes identity, orders stay');
  assert.equal((await api.get('/customer/profile', { token: c.accessToken })).status, 401);
});

test('prepay: the kitchen sees nothing until the money is really received', async () => {
  assert.equal((await api.patch('/cafe/settings', { paymentPolicy: 'sometimes' }, { token: a.token })).body.error.code, 'SETTING_VALUE_INVALID');
  await api.ok(api.patch('/cafe/settings', { paymentPolicy: 'prepay' }, { token: a.token }));
  const before = (await api.ok(api.get('/kitchen/tickets', staff(a)))).length;
  const o = await api.ok(api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner }));
  assert.equal(o.status, 'pending_payment');
  assert.equal((await api.ok(api.get('/kitchen/tickets', staff(a)))).length, before, 'unpaid prepay orders stay out of the kitchen');
  assert.equal((await api.post(`/cafe/orders/${o.publicId}/status`, { status: 'accepted' }, staff(a))).body.error.code, 'ORDER_ILLEGAL_TRANSITION');

  const account = (await api.ok(api.get('/cafe/gateway-accounts', { token: a.token })))[0].public_id;
  const pay = await api.ok(api.post(`/customer/orders/${o.publicId}/payments`, { methodCode: 'upi' }, { session: a.session, key: 'prepay-1' }));
  const event = { id: 'ev-prepay', type: 'capture', kind: 'captured', orderRef: `order_${pay.paymentId}`, paymentRef: 'pay_prepay', amount: '157.5', currency: 'INR' };
  // A first delivery that fails mid-processing (wrong amount here) must not swallow the corrected redelivery.
  await sendWebhook(base, account, { ...event, amount: '1' }, 'hook-secret');
  assert.equal((await api.ok(api.get(`/customer/orders/${o.publicId}`, { session: a.session }))).status, 'pending_payment');
  await sendWebhook(base, account, event, 'hook-secret');
  const after = await api.ok(api.get(`/customer/orders/${o.publicId}`, { session: a.session }));
  assert.equal(after.status, 'placed');
  assert.equal(after.paymentStatus, 'paid');
  assert.equal((await api.ok(api.get('/kitchen/tickets', staff(a)))).length, before + 1, 'paid: now it goes to the kitchen');
  await api.ok(api.patch('/cafe/settings', { paymentPolicy: 'postpay' }, { token: a.token }));
});

test('split bill and split payment: parts sum exactly, partial payments accumulate', async () => {
  const o = await api.ok(api.post('/cafe/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, staff(a)));
  assert.equal(o.total.amount, '157.5');
  const split = await api.ok(api.post('/cafe/bills/split', { orderId: o.publicId, equalParts: 3 }, staff(a)));
  assert.deepEqual(split.bills.map((x: any) => x.amount.amount).sort(), ['52.5', '52.5', '52.5']);
  assert.equal((await api.post('/cafe/bills/split', { orderId: o.publicId, amounts: ['1', '2'] }, staff(a))).body.error.code, 'SPLIT_DOES_NOT_MATCH_BALANCE');
  await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId, amount: '100' }, { ...staff(a), key: 'split-1' }));
  let cur = await api.ok(api.get(`/cafe/orders/${o.publicId}`, staff(a)));
  assert.equal(cur.paymentStatus, 'partially_paid');
  await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId, amount: '57.5' }, { ...staff(a), key: 'split-2' }));
  cur = await api.ok(api.get(`/cafe/orders/${o.publicId}`, staff(a)));
  assert.equal(cur.paymentStatus, 'paid');
});

test('cash drawer: expected versus counted reconciliation', async () => {
  const reg = await api.ok(api.post('/cafe/cash-registers', { name: 'Front' }, staff(a)));
  const { sessionId } = await api.ok(api.post(`/cafe/cash-registers/${reg.publicId}/open`, { floatAmount: '1000' }, staff(a)));
  assert.equal((await api.post(`/cafe/cash-registers/${reg.publicId}/open`, { floatAmount: '1' }, staff(a))).status, 409, 'one open session per drawer');
  const o = await api.ok(api.post('/cafe/orders', { items: [{ productId: a.productId, quantity: 1, variantId: a.variantId }] }, staff(a)));
  await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId, registerSessionId: sessionId }, { ...staff(a), key: 'drawer-1' }));
  await api.ok(api.post(`/cafe/cash-register-sessions/${sessionId}/transactions`, { type: 'pay_out', amount: '57.5', reason: 'milk run' }, staff(a)));
  const closed = await api.ok(api.post(`/cafe/cash-register-sessions/${sessionId}/close`, { counted: '1099' }, staff(a)));
  assert.equal(closed.expected, '1100');
  assert.equal(closed.variance, '-1');
});

test('expenses post to the ledger, voiding reverses them, and closed periods refuse posting', async () => {
  const cat = await api.ok(api.post('/cafe/expense-categories', { name: 'Rent', accountCode: '6100' }, { token: a.token }));
  const e = await api.ok(api.post('/cafe/expenses', { categoryId: cat.id, amount: '5000', date: '2026-05-05', methodCode: 'cash' }, { token: a.token }));
  let tb = await api.ok(api.get(`/cafe/reports/trial-balance?from=2026-05-01&to=2026-05-31`, { token: a.token }));
  assert.equal(tb.find((r: any) => r.code === '6100').debit, '5000.0000');
  await api.ok(api.post(`/cafe/expenses/${e.publicId}/void`, { reason: 'duplicate entry' }, { token: a.token }));
  assert.equal((await api.post(`/cafe/expenses/${e.publicId}/void`, { reason: 'again please' }, { token: a.token })).body.error.code, 'EXPENSE_ALREADY_VOIDED');

  const accounts = await api.ok(api.get('/cafe/accounts', { token: a.token }));
  const acct = (c: string) => accounts.find((x: any) => x.code === c).id;
  assert.equal((await api.post('/cafe/journal-entries', { date: '2026-05-10', memo: 'unbalanced', lines: [{ accountId: acct('1000'), debit: '10' }, { accountId: acct('3000'), credit: '9' }] }, { token: a.token })).body.error.code, 'JOURNAL_UNBALANCED');
  const j = await api.ok(api.post('/cafe/journal-entries', { date: '2026-05-10', memo: 'owner capital', lines: [{ accountId: acct('1000'), debit: '10' }, { accountId: acct('3000'), credit: '10' }] }, { token: a.token }));
  await api.ok(api.post(`/cafe/journal-entries/${j.id}/reverse`, { reason: 'test reversal' }, { token: a.token }));
  assert.equal((await api.post(`/cafe/journal-entries/${j.id}/reverse`, { reason: 'twice over' }, { token: a.token })).body.error.code, 'JOURNAL_ALREADY_REVERSED');

  const periods = await api.ok(api.get('/cafe/financial-periods', { token: a.token }));
  const may = periods.find((p: any) => p.name === '2026-05');
  await api.ok(api.post(`/cafe/financial-periods/${may.id}/close`, {}, { token: a.token }));
  assert.equal((await api.post('/cafe/expenses', { categoryId: cat.id, amount: '1', date: '2026-05-20' }, { token: a.token })).body.error.code, 'PERIOD_CLOSED');
});

test('staff permissions: a cashier cannot approve refunds, a branch-scoped manager cannot see other branches', async () => {
  const inv = await api.ok(api.post('/cafe/staff', { email: 'cash@chai.test', fullName: 'Cashier', roleCode: 'cashier' }, { token: a.token }));
  await api.ok(api.post('/auth/accept-invitation', { token: inv.invitationToken, password: 'cashier password' }));
  assert.equal((await api.post('/auth/accept-invitation', { token: inv.invitationToken, password: 'cashier password' })).body.error.code, 'INVITATION_INVALID', 'invitation is single use');
  const cashier = (await api.ok(api.post('/auth/login', { email: 'cash@chai.test', password: 'cashier password', audience: 'cafe' }))).accessToken;
  assert.equal((await api.post('/cafe/refunds/XXXXXXXXXXXXXXXXXXXXXXXXXX/approve', {}, { token: cashier })).status, 403);
  assert.equal((await api.get('/cafe/reports/pnl?from=2026-01-01&to=2026-12-31', { token: cashier })).status, 403);
  assert.equal((await api.post('/cafe/staff', { email: 'x@y.test', fullName: 'X', roleCode: 'owner' }, { token: a.token })).body.error.code, 'ROLE_NOT_ASSIGNABLE');

  const branch2 = await api.ok(api.post('/cafe/branches', { code: 'B2', name: 'Second', addressLine1: 'x', city: 'Pune' }, { token: a.token }));
  const mgr = await api.ok(api.post('/cafe/staff', { email: 'mgr@chai.test', fullName: 'Mgr', roleCode: 'manager', branchId: branch2.publicId }, { token: a.token }));
  await api.ok(api.post('/auth/accept-invitation', { token: mgr.invitationToken, password: 'manager password' }));
  const manager = (await api.ok(api.post('/auth/login', { email: 'mgr@chai.test', password: 'manager password', audience: 'cafe' }))).accessToken;
  assert.equal((await api.get('/cafe/orders', { token: manager, branch: a.branch })).body.error.code, 'BRANCH_FORBIDDEN');
  assert.equal((await api.get(`/cafe/orders/${a.orderId}`, { token: manager })).body.error.code, 'BRANCH_FORBIDDEN');
  assert.equal((await api.ok(api.get('/cafe/orders', { token: manager }))).length, 0);

  const custom = await api.put('/cafe/roles', { code: 'evil', name: 'Evil', permissions: ['platform.cafes.manage'] }, { token: a.token });
  assert.equal(custom.body.error.code, 'PERMISSION_INVALID');
  await api.ok(api.patch(`/cafe/staff/${inv.publicId}`, { status: 'inactive' }, { token: a.token }));
  assert.equal((await api.get('/cafe/orders', { token: cashier })).status, 401, 'departure ends the session at once');
});

test('auth: rotation, theft detection, lockout, suspended cafes', async () => {
  const login = await api.ok(api.post('/customer/auth/register', { email: 'rot@example.test', password: 'rotation password', fullName: 'Rot' }));
  const r1 = await api.ok(api.post('/auth/refresh', { refreshToken: login.refreshToken }));
  assert.notEqual(r1.refreshToken, login.refreshToken);
  assert.equal((await api.post('/auth/refresh', { refreshToken: login.refreshToken })).body.error.code, 'TOKEN_REUSED');
  assert.equal((await api.post('/auth/refresh', { refreshToken: r1.refreshToken })).status, 401, 'the whole family is revoked');
  assert.equal((await api.get('/customer/profile', { token: r1.accessToken })).status, 401);

  for (let i = 0; i < 5; i++) assert.equal((await api.post('/auth/login', { email: a.email, password: 'wrong wrong wrong', audience: 'cafe' })).status, 401);
  assert.equal((await api.post('/auth/login', { email: a.email, password: 'correct horse battery', audience: 'cafe' })).status, 423);
  const conn = await adminConnection();
  await conn.query(`UPDATE users SET locked_until = NULL WHERE email = ?`, [a.email]);
  await conn.end();

  assert.equal((await api.get('/cafe/orders', { token: 'garbage' })).status, 401);
  assert.equal((await api.get('/cafe/orders', { token: login.accessToken })).body.error.code, 'WRONG_AUDIENCE');
  assert.equal((await api.get('/platform/cafes', { token: a.token })).body.error.code, 'WRONG_AUDIENCE');

  const c3 = await registerCafe('Doomed Cafe', 'USD', 'US', 'en', []);
  await api.ok(api.post(`/platform/cafes/${c3.publicId}/status`, { status: 'active', reason: 'ok go' }, { token: adminToken }));
  const c3login = await api.ok(api.post('/auth/login', { email: c3.email, password: 'correct horse battery', audience: 'cafe' }));
  await api.ok(api.post(`/platform/cafes/${c3.publicId}/status`, { status: 'suspended', reason: 'fraud review' }, { token: adminToken }));
  assert.equal((await api.get('/cafe/profile', { token: c3login.accessToken })).status, 401);
  assert.equal((await api.post('/auth/login', { email: c3.email, password: 'correct horse battery', audience: 'cafe' })).body.error.code, 'NO_CAFE_ACCESS');
  assert.equal((await api.get(`/public/cafes/${c3.slug}/menu`)).status, 404);
});

test('platform: dashboard, audit trail, consolidated reporting needs a stored rate', async () => {
  const dash = await api.ok(api.get('/platform/analytics', { token: adminToken }));
  assert.ok(Number(dash.cafes.total) >= 3);
  assert.ok(dash.grossByCurrency.some((c: any) => c.currency_code === 'JPY'));
  assert.ok(dash.grossByCurrency.some((c: any) => c.currency_code === 'INR'));

  const incomplete = await api.ok(api.get(`/platform/analytics/consolidated?currency=USD&asOf=${today()}`, { token: adminToken }));
  assert.equal(incomplete.isComplete, false);
  assert.ok(incomplete.missingRates.includes('INR'), 'a missing rate is shown as missing, never guessed');
  await api.ok(api.post('/platform/exchange-rates', { base: 'INR', quote: 'USD', rate: '0.012', provider: 'manual', effectiveAt: '2026-01-01T00:00:00Z' }, { token: adminToken }));
  await api.ok(api.post('/platform/exchange-rates', { base: 'JPY', quote: 'USD', rate: '0.0065', provider: 'manual', effectiveAt: '2026-01-01T00:00:00Z' }, { token: adminToken }));
  const full = await api.ok(api.get(`/platform/analytics/consolidated?currency=USD&asOf=${today()}`, { token: adminToken }));
  assert.equal(full.isComplete, true);
  assert.equal(full.lines.find((l: any) => l.currency === 'JPY').rate, '0.0065000000');

  await api.ok(api.get(`/platform/cafes/${a.publicId}`, { token: adminToken, reason: 'support ticket 12' } as never));
  const logs = await api.ok(api.get('/platform/audit-logs?action=platform.cafe', { token: adminToken }));
  assert.ok(logs.some((l: any) => l.action === 'platform.cafe_read'));
  assert.ok(logs.some((l: any) => l.action === 'platform.cafe_active' && l.reason === 'documents checked'));
  const health = await api.ok(api.get('/platform/health', { token: adminToken }));
  assert.equal(health.database, 'ok');
});

test('subscriptions: plans are dynamic, limits are enforced, and the lifecycle runs', async () => {
  assert.equal((await api.ok(api.get('/cafe/subscription/plans', { token: b.token }))).length, 0, 'nothing is sellable until the admin activates it');
  await api.ok(api.put('/platform/plans/starter', { isActive: true, isPublic: true, trialDays: 0, graceDays: 3, prices: [{ currency: 'JPY', interval: 'monthly', amount: '1000' }], entitlements: [{ feature: 'monthly_orders', enabled: true, limit: 2 }, { feature: 'employees', enabled: true, limit: 1 }] }, { token: adminToken }));
  assert.equal((await api.post('/cafe/subscription', { planCode: 'starter', interval: 'yearly' }, { token: b.token })).body.error.code, 'PLAN_PRICE_UNAVAILABLE');
  await api.ok(api.post('/cafe/subscription', { planCode: 'starter', interval: 'monthly' }, { token: b.token }));
  const place = () => api.post('/customer/orders', { items: [{ productId: b.productId, quantity: 1 }] }, { session: b.session, token: diner });
  const results: number[] = [];
  for (let i = 0; i < 3; i++) results.push((await place()).status);
  // One order already placed this month before subscribing, so the limit of 2 leaves room for one.
  assert.ok(results.includes(402), `expected the plan limit to bite: ${results}`);
  assert.equal((await api.post('/cafe/staff', { email: 'over@limit.test', fullName: 'Over', roleCode: 'waiter' }, { token: b.token })).body.error.code, 'PLAN_LIMIT_REACHED');

  const { SubscriptionsService } = await import('../src/modules/subscriptions/subscriptions.service');
  const subs = app.get(SubscriptionsService);
  await subs.runLifecycle(new Date(Date.now() + 40 * 86400_000));
  const current = await api.ok(api.get('/cafe/subscription', { token: b.token }));
  assert.ok(['grace', 'expired', 'past_due'].includes(current.status));
  const invoices = await api.ok(api.get('/cafe/subscription/invoices', { token: b.token }));
  assert.equal(invoices.length, 1);
  await api.ok(api.post(`/platform/subscription-invoices/${invoices[0].public_id}/paid`, { reference: 'bank-ref-1' }, { token: adminToken }));
  const dash = await api.ok(api.get('/platform/finance', { token: adminToken }));
  assert.ok(dash.some((r: any) => r.currency_code === 'JPY' && r.transaction_type === 'subscription'));
});

test('realtime: events do not cross cafes, rooms cannot be chosen, reconnect replays what was missed', async () => {
  const bSocket = io(base, { auth: { token: b.token }, transports: ['websocket'] });
  const bEvents: any[] = [];
  bSocket.on('event', (e) => bEvents.push(e));
  await new Promise<void>((res) => bSocket.once('ready', () => res()));
  // A client cannot join a room by asking.
  bSocket.emit('join', `cafe:1:branch:1:role:kitchen`);

  const lastSeq = Math.max(0, ...socketEvents.map((e) => e.seq));
  kitchenSocket.disconnect();
  const o = await api.ok(api.post('/cafe/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, staff(a)));
  await dispatch();
  await new Promise((r) => setTimeout(r, 150));
  assert.equal(bEvents.filter((e) => e.payload.orderId === o.publicId).length, 0, "cafe B never receives cafe A's events");
  assert.equal(socketEvents.filter((e) => e.payload.orderId === o.publicId).length, 0, 'disconnected');

  const replayed: any[] = [];
  const reconnected = io(base, { auth: { token: kitchenToken, lastSeq }, transports: ['websocket'] });
  reconnected.on('event', (e) => replayed.push(e));
  await new Promise<void>((res) => reconnected.once('ready', () => res()));
  await new Promise((r) => setTimeout(r, 200));
  assert.ok(replayed.some((e) => e.replay && e.type === 'order.placed' && e.payload.orderId === o.publicId), 'missed event replayed');
  const bReplay: any[] = [];
  const bAgain = io(base, { auth: { token: b.token, lastSeq: 0 }, transports: ['websocket'] });
  bAgain.on('event', (e) => bReplay.push(e));
  await new Promise<void>((res) => bAgain.once('ready', () => res()));
  await new Promise((r) => setTimeout(r, 200));
  assert.equal(bReplay.filter((e) => e.payload.orderId === o.publicId).length, 0, 'replay is authorized too');

  const denied = io(base, { auth: { token: 'garbage' }, transports: ['websocket'], reconnection: false });
  await new Promise<void>((res) => denied.once('connect_error', () => res()));
  const guest = io(base, { auth: { tableSession: a.session }, transports: ['websocket'] });
  const guestEvents: any[] = [];
  guest.on('event', (e) => guestEvents.push(e));
  await new Promise<void>((res) => guest.once('ready', () => res()));
  const order2 = await api.ok(api.post('/customer/orders', { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, { session: a.session, token: diner }));
  await api.ok(api.post(`/cafe/orders/${order2.publicId}/status`, { status: 'accepted' }, staff(a)));
  await dispatch();
  await new Promise((r) => setTimeout(r, 150));
  assert.ok(guestEvents.some((e) => e.type === 'order.accepted'), 'the guest tracks their own order live');
  assert.ok(!guestEvents.some((e) => e.type === 'order.placed' && e.payload.orderId === o.publicId), 'a guest does not see other tables');
  [bSocket, reconnected, bAgain, denied, guest].forEach((s) => s.disconnect());
});

test('service requests, reviews, reservations, table transfer and session close', async () => {
  const r = await api.ok(api.post('/customer/service-requests', { type: 'waiter' }, { session: a.session }));
  assert.equal((await api.ok(api.post('/customer/service-requests', { type: 'waiter' }, { session: a.session }))).deduplicated, true);
  assert.equal((await api.ok(api.get('/cafe/service-requests', staff(a)))).length, 1);
  await api.ok(api.patch(`/cafe/service-requests/${r.publicId}`, { status: 'resolved' }, staff(a)));

  assert.equal((await api.post(`/customer/orders/${a.orderId}/review`, { rating: 9 }, { session: a.session })).status, 400);
  await api.ok(api.post(`/customer/orders/${a.orderId}/review`, { rating: 5, comment: 'शानदार' }, { session: a.session }));
  assert.equal((await api.post(`/customer/orders/${a.orderId}/review`, { rating: 4 }, { session: a.session })).status, 409);
  assert.equal((await api.ok(api.get('/cafe/reviews', { token: a.token })))[0].rating, 5);

  const t2 = await api.ok(api.post('/cafe/tables', { tableNumber: 'T2' }, staff(a)));
  const start = new Date(Date.now() + 86400_000).toISOString();
  const end = new Date(Date.now() + 90000_000).toISOString();
  await api.ok(api.post('/cafe/reservations', { guestName: 'Asha', partySize: 2, startsAt: start, endsAt: end, tableId: t2.publicId }, staff(a)));
  assert.equal((await api.post('/cafe/reservations', { guestName: 'Ben', partySize: 2, startsAt: start, endsAt: end, tableId: t2.publicId }, staff(a))).body.error.code, 'TABLE_ALREADY_RESERVED');

  const o = await api.ok(api.post('/cafe/orders', { tableId: a.tableId, items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] }, staff(a)));
  await api.ok(api.post(`/cafe/orders/${o.publicId}/transfer`, { tableId: t2.publicId, reason: 'moved to window seat' }, staff(a)));
  const moved = await api.ok(api.get(`/cafe/orders/${o.publicId}`, staff(a)));
  assert.equal(moved.tableNumber, 'T2');
  assert.equal(moved.modifications[0].modification_type, 'table_transferred');

  const sessions = await api.ok(api.get('/cafe/table-sessions', staff(a)));
  const t1 = sessions.find((s: any) => s.table_number === 'T1');
  assert.equal((await api.post(`/cafe/table-sessions/${t1.public_id}/close`, {}, staff(a))).body.error.code, 'SESSION_HAS_UNPAID_ORDERS');
});

test('delivery across a state line takes the inter-region tax; within the state it does not', async () => {
  const body = (stateCode: string) => ({ orderType: 'delivery', deliveryAddress: { stateCode, line1: 'x' }, items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] });
  const inter = await api.ok(api.post('/cafe/orders', body('KA'), staff(a)));
  assert.deepEqual(inter.items[0].taxes.map((t: any) => t.code), ['IGST']);
  assert.equal(inter.tax.amount, '7.5');
  const intra = await api.ok(api.post('/cafe/orders', body('MH'), staff(a)));
  assert.deepEqual(intra.items[0].taxes.map((t: any) => t.code).sort(), ['CGST', 'SGST']);
  assert.equal(intra.tax.amount, '7.5');
});

test('precision: a JPY cafe cannot record fractional yen anywhere money enters', async () => {
  const cat = await api.ok(api.post('/cafe/expense-categories', { name: 'Misc' }, { token: b.token }));
  assert.equal((await api.post('/cafe/expenses', { categoryId: cat.id, amount: '100.50', date: '2026-06-01' }, { token: b.token })).body.error.code, 'AMOUNT_PRECISION_INVALID');
  const sup = await api.ok(api.post('/cafe/suppliers', { name: 'Tea' }, { token: b.token }));
  assert.equal((await api.post('/cafe/supplier-invoices', { supplierId: sup.publicId, number: 'X1', subtotal: '10.5', invoiceDate: '2026-06-01' }, { token: b.token })).body.error.code, 'AMOUNT_PRECISION_INVALID');
});

test('every /cafe and /kitchen route with an id refuses a real id from another cafe', async () => {
  const conn = await adminConnection();
  const ids: string[] = [a.orderId!, a.productId!, a.categoryId!, a.variantId!, a.addonId!, a.tableId!, a.branch];
  for (const t of ['payments', 'refunds', 'invoices', 'kitchen_orders', 'coupons', 'suppliers', 'ingredients', 'cafe_staff', 'expenses', 'cash_registers', 'purchase_orders', 'supplier_invoices', 'customer_reviews', 'reservations', 'service_requests', 'support_tickets', 'kitchen_stations', 'table_sessions', 'promotions', 'banners', 'payroll_entries', 'cash_register_sessions']) {
    const [rows]: any = await conn.query(`SELECT r.public_id FROM \`${t}\` r JOIN cafes c ON c.id = r.cafe_id WHERE c.public_id = ? LIMIT 1`, [a.publicId]);
    if (rows[0]) ids.push(rows[0].public_id);
  }
  const fingerprint = async () => {
    const tables = ['orders', 'products', 'categories', 'product_variants', 'cafe_tables', 'coupons', 'suppliers', 'ingredients', 'cafe_staff', 'expenses', 'refunds', 'payments'];
    const out: string[] = [];
    for (const t of tables) { const [[r]]: any = await conn.query(`SELECT COUNT(*) n, MAX(updated_at) u FROM \`${t}\` x WHERE x.cafe_id = (SELECT id FROM cafes WHERE public_id = ?)`, [a.publicId]); out.push(`${t}:${r.n}:${r.u}`); }
    return out.join('|');
  };
  const before = await fingerprint();
  try {
  const router = (app.getHttpAdapter().getInstance() as any).router;
  const leaks: string[] = [];
  let tried = 0;
  // Routes keyed by a date range, a catalog code or a report type hold no other-cafe id to attack.
  for (const layer of router.stack) {
    if (!layer.route) continue;
    const path = String(layer.route.path).replace(/^\/api\/v1/, '');
    if (!/^\/(cafe|kitchen)\//.test(path) || !path.includes(':') || /tax-categories|reports\/:type|financial-periods|expenses\/:id\/void$|journal-entries|items\/:itemId/.test(path)) continue;
    for (const [method, on] of Object.entries(layer.route.methods)) {
      if (!on || !['get', 'post', 'put', 'patch', 'delete'].includes(method)) continue;
      for (const id of ids) {
        tried += 1;
        const url = path.replace(/:\w+/g, id);
        const res = await api.call(method.toUpperCase(), url, ['get', 'delete'].includes(method) ? undefined : {}, staff(b));
        if (res.status < 300) leaks.push(`${method} ${path} with ${id} -> ${res.status}`);
      }
    }
  }
  assert.ok(tried > 500, `only ${tried} attempts`);
  assert.deepEqual(leaks, []);
  assert.equal(await fingerprint(), before, "cafe A's data did not change");
  } finally {
    await conn.end();
  }
});

test('errors are localized by language, with a stable code', async () => {
  const conn = await adminConnection();
  await conn.query(`INSERT INTO translations (namespace, translation_key, language_code, value) VALUES ('errors','NOT_FOUND','hi','नहीं मिला') ON DUPLICATE KEY UPDATE value = VALUES(value)`);
  await conn.end();
  const r = await api.get('/public/cafes/no-such-cafe-x/config', { lang: 'hi' });
  assert.equal(r.status, 404);
  assert.equal(r.body.error.code, 'CAFE_NOT_FOUND');
  const nf = await api.get('/no/such/route', { lang: 'hi' });
  assert.equal(nf.body.error.code, 'NOT_FOUND');
  assert.equal(nf.body.error.message, 'नहीं मिला');
  assert.ok(nf.body.error.requestId);
});

test('a table frees itself once paid, the next party starts fresh, and staff can free it by hand only when settled', async () => {
  const tableId = (await api.ok(api.post('/cafe/tables', { tableNumber: 'T9', capacity: 2 }, staff(a)))).publicId;
  const token = (await api.ok(api.get(`/cafe/tables/${tableId}/qr`, staff(a)))).url.split('/t/')[1];
  const status = async () => (await api.ok(api.get('/cafe/tables', staff(a)))).find((t: { public_id: string }) => t.public_id === tableId).status;
  const item = { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] };

  const first = (await api.ok(api.get(`/public/qr/${token}`))).session.token;
  assert.equal(await status(), 'occupied');
  const order = await api.ok(api.post('/customer/orders', item, { session: first, token: diner }));
  assert.equal((await api.post(`/cafe/tables/${tableId}/release`, {}, staff(a))).body.error.code, 'SESSION_HAS_UNPAID_ORDERS', 'no table is freed while money is owed');
  assert.equal(await status(), 'occupied');

  await api.ok(api.post('/cafe/payments/cash', { orderId: order.publicId }, { ...staff(a), key: 'release-cash-1' }));
  assert.equal(await status(), 'available', 'paying in full frees the table');
  assert.equal((await api.ok(api.get(`/customer/orders/${order.publicId}`, { session: first }))).paymentStatus, 'paid', 'the guests who paid can still see their order');

  // The same guests order dessert: the table is theirs again.
  const dessert = await api.ok(api.post('/customer/orders', item, { session: first, token: diner }));
  assert.equal(await status(), 'occupied');
  await api.ok(api.post('/cafe/payments/cash', { orderId: dessert.publicId }, { ...staff(a), key: 'release-cash-2' }));
  assert.equal(await status(), 'available');

  // The next party gets a new session and none of the last guests' orders.
  const next = (await api.ok(api.get(`/public/qr/${token}`))).session.token;
  assert.notEqual(next, first);
  assert.equal((await api.ok(api.get('/customer/orders', { session: next }))).length, 0);
  assert.equal((await api.get(`/customer/orders/${order.publicId}`, { session: first })).status, 410, "the previous party's session has ended");
  assert.equal(await status(), 'occupied');

  // Nothing owed: staff may free it by hand, and the session closes with it.
  await api.ok(api.post(`/cafe/tables/${tableId}/release`, {}, staff(a)));
  assert.equal(await status(), 'available');
  assert.equal((await api.get('/customer/orders', { session: next })).status, 410);
});

test('loopholes: table PIN, session end after paying, settings bounds and password reset', async () => {
  // Settings are checked: an hour-long session-after-payment is fine, a negative one is not.
  assert.equal((await api.patch('/cafe/settings', { sessionEndAfterPaymentMinutes: -1 }, { token: a.token })).body.error.code, 'SETTING_VALUE_INVALID');
  assert.equal((await api.patch('/cafe/settings', { unpaidAlertMinutes: '60' }, { token: a.token })).body.error.code, 'SETTING_TYPE_INVALID');
  await api.ok(api.patch('/cafe/settings', { tablePinRequired: true, sessionEndAfterPaymentMinutes: 0, unpaidAlertMinutes: 45 }, { token: a.token }));
  assert.deepEqual((await api.ok(api.get('/cafe/workspace', { token: a.token }))).settings, { unpaidAlertMinutes: 45, tablePinRequired: true });

  const tableId = (await api.ok(api.post('/cafe/tables', { tableNumber: 'P1', capacity: 2 }, staff(a)))).publicId;
  const token = (await api.ok(api.get(`/cafe/tables/${tableId}/qr`, staff(a)))).url.split('/t/')[1];
  const scan = await api.ok(api.get(`/public/qr/${token}`));
  assert.equal(scan.session.pinRequired, true);
  const session = scan.session.token;
  const item = { items: [{ productId: a.productId, variantId: a.variantId, quantity: 1 }] };

  // Browsers may send the PIN proof: the cross-origin preflight must allow its header, or the web app could never order.
  const preflight = await fetch(`${api.base}/customer/orders`, { method: 'OPTIONS', headers: { Origin: 'http://localhost:8083', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'x-table-pin,x-table-session' } });
  assert.match(preflight.headers.get('access-control-allow-headers') ?? '', /X-Table-Pin/i);

  // A photo of the QR is not enough: ordering needs the PIN the staff read out.
  assert.equal((await api.post('/customer/orders', item, { session, token: diner })).body.error.code, 'TABLE_PIN_REQUIRED');
  const pin = (await api.ok(api.get('/cafe/tables', staff(a)))).find((t: { public_id: string }) => t.public_id === tableId).pin;
  assert.match(pin, /^\d{4}$/, 'staff can see the PIN of an occupied table');
  const wrong = pin === '0000' ? '1111' : '0000';
  assert.equal((await api.post('/customer/table-pin', { pin: wrong }, { session })).body.error.code, 'TABLE_PIN_WRONG');
  const { proof } = await api.ok(api.post('/customer/table-pin', { pin }, { session }));
  const placed = await api.post('/customer/orders', item, { session, token: diner, pin: proof });
  assert.equal(placed.status, 201, JSON.stringify(placed.body));

  // With the session set to end at payment, the paying guests cannot order again from outside.
  await api.ok(api.post('/cafe/payments/cash', { orderId: placed.body.data.publicId }, { ...staff(a), key: 'pin-cash-1' }));
  assert.equal((await api.get(`/customer/orders/${placed.body.data.publicId}`, { session })).status, 410, 'session ends once paid, as the cafe chose');
  await api.ok(api.patch('/cafe/settings', { tablePinRequired: false, sessionEndAfterPaymentMinutes: 30, unpaidAlertMinutes: 60 }, { token: a.token }));

  // Password reset: no email provider, so asking for a link says so plainly; a valid link still works end to end.
  assert.deepEqual(await api.ok(api.get('/customer/auth/features')), { passwordReset: false });
  assert.equal((await api.post('/customer/auth/password-reset/request', { email: 'table-diner@example.test' })).body.error.code, 'PASSWORD_RESET_UNAVAILABLE');
  const raw = 'reset-link-token-for-the-e2e-test-0001';
  const { createHash } = await import('node:crypto');
  const conn = await adminConnection();
  await conn.query(`INSERT INTO user_tokens (customer_id, purpose, token_hash, expires_at) SELECT id, 'password_reset', ?, NOW(3) + INTERVAL 30 MINUTE FROM customers WHERE email = 'table-diner@example.test'`, [createHash('sha256').update(raw).digest('hex')]);
  await conn.end();
  assert.equal((await api.post('/customer/auth/password-reset/confirm', { token: 'not-a-real-reset-token-at-all', password: 'a brand new password' })).body.error.code, 'RESET_LINK_INVALID');
  await api.ok(api.post('/customer/auth/password-reset/confirm', { token: raw, password: 'a brand new password' }));
  assert.equal((await api.post('/customer/auth/password-reset/confirm', { token: raw, password: 'another new password' })).body.error.code, 'RESET_LINK_INVALID', 'a link works once');
  assert.equal((await api.post('/customer/auth/login', { email: 'table-diner@example.test', password: 'table diner password' })).status, 401);
  diner = (await api.ok(api.post('/customer/auth/login', { email: 'table-diner@example.test', password: 'a brand new password' }))).accessToken;
});
