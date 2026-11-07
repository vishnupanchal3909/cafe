// The whole payment system through the real Razorpay adapter, against a simulator shaped after Razorpay's docs.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { adminConnection, Api, App, bootstrap } from './harness';
import { KEY_ID, KEY_SECRET, RazorpayMock, WEBHOOK_SECRET } from './razorpay-mock';

let app: App;
let api: Api;
let base: string;
const mock = new RazorpayMock();
let token: string; let branch: string; let session: string; let diner: string; let account: string; let slug: string;
let productId: string;
const staff = () => ({ token, branch });
const today = () => new Date(Date.now() + 86400_000).toISOString().slice(0, 10);
let keyN = 0;
const key = () => `k-${++keyN}-${Date.now()}`;

const order = async () => api.ok(api.post('/customer/orders', { items: [{ productId, quantity: 1 }] }, { session, token: diner }));
const startPay = async (orderId: string, extra: Record<string, unknown> = {}) => api.ok(api.post(`/customer/orders/${orderId}/payments`, { methodCode: 'upi', ...extra }, { session, key: key() }));
const hook = async (name: string, payload: Record<string, unknown>, eventId?: string) => {
  const e = mock.event(name, payload, eventId);
  const r = await fetch(`${base}/api/v1/webhooks/payments/razorpay/${account}`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-razorpay-signature': e.signature, 'x-razorpay-event-id': e.eventId }, body: e.raw });
  return { status: r.status, body: await r.json() as any, eventId: e.eventId };
};
const getOrder = (id: string) => api.ok(api.get(`/customer/orders/${id}`, { session }));
const balanced = async () => assert.equal((await api.ok(api.get(`/cafe/reports/balance-sheet?asOf=${today()}`, { token }))).balanced, true, 'the books must balance');
const ledger = async () => Object.fromEntries((await api.ok(api.get(`/cafe/reports/trial-balance?from=2020-01-01&to=${today()}`, { token }))).map((x: any) => [x.code, x]));

before(async () => {
  await mock.start();
  process.env.RAZORPAY_API_BASE = mock.base;
  process.env.RATE_LIMIT_SCALE = '100';
  const b = await bootstrap();
  app = b.app; api = b.api; base = b.base;
  const reg = await api.ok(api.post('/public/cafes/register', {
    owner: { email: 'o@pay.test', password: 'owner password long', fullName: 'Owner' },
    cafe: { name: 'Pay Cafe', legalName: 'Pay Cafe Pvt Ltd', countryCode: 'IN', currencyCode: 'INR', defaultLanguage: 'en', timezone: 'Asia/Kolkata' },
    branch: { name: 'Main', addressLine1: '1 Road', city: 'Pune', stateCode: 'MH' },
  }));
  branch = reg.branchPublicId; slug = reg.slug;
  const conn = await adminConnection();
  await conn.query(`UPDATE cafes SET status = 'active' WHERE public_id = ?`, [reg.cafePublicId]);
  await conn.end();
  token = (await api.ok(api.post('/auth/login', { email: 'o@pay.test', password: 'owner password long', audience: 'cafe' }))).accessToken;
  const cat = await api.ok(api.post('/cafe/categories', { translations: [{ language: 'en', name: 'Food' }] }, { token }));
  productId = (await api.ok(api.post('/cafe/products', { categoryId: cat.publicId, basePrice: '100.50', translations: [{ language: 'en', name: 'Thali' }] }, { token }))).publicId;
  const table = await api.ok(api.post('/cafe/tables', { tableNumber: 'T1' }, staff()));
  const qr = await api.ok(api.get(`/cafe/tables/${table.publicId}/qr`, staff()));
  session = (await api.ok(api.get(`/public/qr/${qr.url.split('/t/')[1]}`))).session.token;
  // Ordering needs a signed-in customer.
  diner = (await api.ok(api.post('/customer/auth/register', { email: 'rzp-diner@example.test', password: 'razorpay diner password', fullName: 'Diner' }))).accessToken;
  await api.ok(api.put('/cafe/payment-methods', { methods: ['cash', 'upi', 'card', 'payment_link'] }, { token }));
});
after(async () => { mock.stop(); await app.close(); });

test('keys: wrong ones stay inactive, right ones activate, and secrets are never returned', async () => {
  const bad = await api.ok(api.put('/cafe/gateway-accounts', { providerCode: 'razorpay', environment: 'sandbox', keyId: KEY_ID, keySecret: 'wrong', webhookSecret: WEBHOOK_SECRET }, { token }));
  assert.equal((await api.post(`/cafe/gateway-accounts/${bad.publicId}/test`, {}, { token })).body.error.code, 'GATEWAY_CREDENTIALS_INVALID');
  assert.equal((await api.ok(api.get('/customer/payment-options', { session }))).online, null);
  const good = await api.ok(api.put('/cafe/gateway-accounts', { providerCode: 'razorpay', environment: 'sandbox', keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET }, { token }));
  account = good.publicId;
  assert.match(good.webhookUrl, new RegExp(`/webhooks/payments/razorpay/${account}$`));
  assert.equal((await api.ok(api.post(`/cafe/gateway-accounts/${account}/test`, {}, { token }))).status, 'active');
  assert.equal((await api.ok(api.get('/customer/payment-options', { session }))).online.provider, 'razorpay');
  const all = JSON.stringify(await api.ok(api.get('/cafe/gateway-accounts', { token })));
  assert.ok(!all.includes(KEY_SECRET) && !all.includes(WEBHOOK_SECRET));
});

test('checkout: exact paise, the public key only, and a forged callback is refused', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  assert.equal(pay.checkout.amountMinor, 10050);
  assert.equal(pay.checkout.keyId, KEY_ID);
  assert.ok(!JSON.stringify(pay).includes(KEY_SECRET));
  const mockOrder = mock.orders.get(pay.checkout.orderId)!;
  assert.equal(mockOrder.amount, 10050);
  assert.equal(mockOrder.currency, 'INR');
  const p = mock.pay(mockOrder.id);

  const forged = await api.post(`/customer/payments/${pay.paymentId}/verify`, { providerPaymentRef: p.id, signature: 'deadbeef' }, { session });
  assert.equal(forged.body.error.code, 'PAYMENT_SIGNATURE_INVALID');
  const otherSecret = await api.post(`/customer/payments/${pay.paymentId}/verify`, { providerPaymentRef: p.id, signature: mock.sign(mockOrder.id, p.id, 'attacker') }, { session });
  assert.equal(otherSecret.status, 401);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'unpaid');

  const ok = await api.ok(api.post(`/customer/payments/${pay.paymentId}/verify`, { providerPaymentRef: p.id, signature: mock.sign(mockOrder.id, p.id) }, { session }));
  assert.equal(ok.status, 'succeeded');
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');

  // The webhook still arrives afterwards. Nothing doubles.
  assert.equal((await hook('payment.captured', { payment: p })).status, 200);
  assert.equal((await hook('order.paid', { payment: p, order: mockOrder })).status, 200);
  assert.equal((await getOrder(o.publicId)).paid.amount, '100.5');
  const stored = (await api.ok(api.get(`/cafe/payments?orderId=${o.publicId}`, staff())))[0];
  assert.equal(stored.verification_source, 'gateway_api');
  await balanced();
});

test('a valid signature alone is not enough: the money must be confirmed with the gateway', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  const fake = 'pay_never_happened';
  const r = await api.ok(api.post(`/customer/payments/${pay.paymentId}/verify`, { providerPaymentRef: fake, signature: mock.sign(pay.checkout.orderId, fake) }, { session }));
  assert.equal(r.status, 'pending');
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'unpaid');
  await api.ok(api.post(`/customer/payments/${pay.paymentId}/abandon`, {}, { session }));
});

test('webhook only: the customer closed the browser straight after paying', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  const p = mock.pay(pay.checkout.orderId, { fee: 300, method: 'card' });
  const first = await hook('payment.captured', { payment: p });
  assert.equal(first.status, 200);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');
  assert.deepEqual((await hook('payment.captured', { payment: p }, first.eventId)).body.data, { received: true, duplicate: true });
  const stored = (await api.ok(api.get(`/cafe/payments?orderId=${o.publicId}`, staff())))[0];
  assert.equal(stored.verification_source, 'gateway_webhook');
  assert.equal(stored.gateway_fee_amount, '3.0000');
});

test('manual-capture accounts: an authorized payment is captured, whichever way we learn of it, and events may come out of order', async () => {
  mock.autoCapture = false;
  const a = await order();
  const payA = await startPay(a.publicId);
  const pA = mock.pay(payA.checkout.orderId);
  assert.equal((await hook('payment.authorized', { payment: pA })).status, 200);
  assert.equal(mock.payments.get(pA.id)!.status, 'captured');
  assert.equal((await getOrder(a.publicId)).paymentStatus, 'paid');
  assert.equal((await hook('payment.authorized', { payment: { ...pA, status: 'authorized' } })).status, 200, 'a late authorized after capture is harmless');

  const b = await order();
  const payB = await startPay(b.publicId);
  const pB = mock.pay(payB.checkout.orderId);
  const ok = await api.ok(api.post(`/customer/payments/${payB.paymentId}/verify`, { providerPaymentRef: pB.id, signature: mock.sign(pB.order_id, pB.id) }, { session }));
  assert.equal(ok.status, 'succeeded');
  mock.autoCapture = true;
});

test('a failed attempt leaves the payment open to retry in Checkout; closing it frees the balance', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  const failedAttempt = { id: 'pay_failed_1', amount: 10050, currency: 'INR', order_id: pay.checkout.orderId, status: 'failed', error_code: 'BAD_REQUEST_ERROR', notes: {} };
  assert.equal((await hook('payment.failed', { payment: failedAttempt })).status, 200);
  assert.equal((await api.ok(api.get(`/customer/payments/${pay.paymentId}`, { session }))).status, 'pending');
  assert.equal((await api.post(`/customer/orders/${o.publicId}/payments`, { methodCode: 'upi' }, { session, key: key() })).body.error.code, 'ORDER_ALREADY_PAID', 'the open attempt reserves the balance');
  const retry = mock.pay(pay.checkout.orderId);
  await hook('payment.captured', { payment: retry });
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');

  const o2 = await order();
  const first = await startPay(o2.publicId);
  await api.ok(api.post(`/customer/payments/${first.paymentId}/abandon`, {}, { session }));
  const second = await startPay(o2.publicId);
  assert.notEqual(second.paymentId, first.paymentId);
  await hook('payment.captured', { payment: mock.pay(second.checkout.orderId) });
  assert.equal((await getOrder(o2.publicId)).paymentStatus, 'paid');
});

test('a capture after the checkout was closed still counts, and an overpayment is flagged rather than lost', async () => {
  const o = await order();
  const first = await startPay(o.publicId);
  await api.ok(api.post(`/customer/payments/${first.paymentId}/abandon`, {}, { session }));
  const second = await startPay(o.publicId);
  await hook('payment.captured', { payment: mock.pay(second.checkout.orderId) });
  assert.equal((await getOrder(o.publicId)).paid.amount, '100.5');
  await hook('payment.captured', { payment: mock.pay(first.checkout.orderId) });
  assert.equal((await getOrder(o.publicId)).paid.amount, '201');
  const logs = await api.ok(api.get('/cafe/audit-logs', { token }));
  assert.ok(logs.some((l: any) => l.action === 'payment.overpaid' && l.entity_id === o.publicId));
  await balanced();
});

test('a retried request gets the same checkout back, so one tap cannot charge twice', async () => {
  const o = await order();
  const k = key();
  const a = await api.ok(api.post(`/customer/orders/${o.publicId}/payments`, { methodCode: 'upi' }, { session, key: k }));
  const b = await api.ok(api.post(`/customer/orders/${o.publicId}/payments`, { methodCode: 'upi' }, { session, key: k }));
  assert.equal(b.paymentId, a.paymentId);
  assert.equal(b.checkout.orderId, a.checkout.orderId);
  assert.equal(b.checkout.amountMinor, 10050);
  await api.ok(api.post(`/customer/payments/${a.paymentId}/abandon`, {}, { session }));
});

test('webhook security: a bad signature, a tampered body or another cafe\'s account are all refused', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  const p = mock.pay(pay.checkout.orderId);
  const e = mock.event('payment.captured', { payment: p });
  const send = (body: string, sig: string, acct = account) => fetch(`${base}/api/v1/webhooks/payments/razorpay/${acct}`, { method: 'POST', headers: { 'Content-Type': 'application/json', 'x-razorpay-signature': sig, 'x-razorpay-event-id': e.eventId }, body });
  assert.equal((await send(e.raw, 'nope')).status, 401);
  assert.equal((await send(e.raw.replace('10050', '1'), e.signature)).status, 401);
  assert.equal((await send(e.raw, e.signature, 'XXXXXXXXXXXXXXXXXXXXXXXXXX')).status, 404);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'unpaid');
  // A correctly signed event for the wrong sum is recorded and never credited.
  const wrong = await hook('payment.captured', { payment: { ...p, amount: 100 } });
  assert.equal(wrong.status, 200);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'unpaid');
  // A sale on the same gateway account that is not ours is noted and changes nothing.
  assert.equal((await hook('payment.captured', { payment: { id: 'pay_other', amount: 5000, currency: 'INR', order_id: 'order_other', notes: {} } })).status, 200);
  await api.ok(api.post(`/customer/payments/${pay.paymentId}/abandon`, {}, { session }));
});

test('sensitive payload fields are never stored', async () => {
  const conn = await adminConnection();
  const [rows]: any = await conn.query(`SELECT sanitized_payload FROM payment_webhooks`);
  await conn.end();
  assert.ok(rows.length > 0);
  const all = JSON.stringify(rows);
  assert.ok(!all.includes('guest@example.test') && !all.includes('+919999999999'));
});

test('a temporary fault is not acknowledged, so the gateway resends it and nothing is lost', async () => {
  mock.autoCapture = false;
  const o = await order();
  const pay = await startPay(o.publicId);
  const p = mock.pay(pay.checkout.orderId);
  mock.failNext = 1;
  const first = await hook('payment.authorized', { payment: p });
  assert.equal(first.status, 503);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'unpaid');
  const again = await hook('payment.authorized', { payment: p }, first.eventId);
  assert.equal(again.status, 200);
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');
  mock.autoCapture = true;
});

test('a gateway outage at checkout fails cleanly and the guest can try again', async () => {
  const o = await order();
  mock.failNext = 1;
  assert.equal((await api.post(`/customer/orders/${o.publicId}/payments`, { methodCode: 'upi' }, { session, key: key() })).body.error.code, 'GATEWAY_UNAVAILABLE');
  const pay = await startPay(o.publicId);
  assert.equal(pay.status, 'pending');
  await hook('payment.captured', { payment: mock.pay(pay.checkout.orderId) });
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');
});

test('missed webhook: the sweep finds the capture; an abandoned checkout expires and frees the balance', async () => {
  const { PaymentsService } = await import('../src/modules/payments/payments.service');
  const svc = app.get(PaymentsService);
  const conn = await adminConnection();
  const age = (id: string, minutes: number) => conn.query(`UPDATE payments SET created_at = UTC_TIMESTAMP(3) - INTERVAL ? MINUTE WHERE public_id = ?`, [minutes, id]);

  const paid = await order();
  const payPaid = await startPay(paid.publicId);
  mock.pay(payPaid.checkout.orderId);
  await age(payPaid.paymentId, 6);
  const dead = await order();
  const payDead = await startPay(dead.publicId);
  await age(payDead.paymentId, 31);
  const fresh = await order();
  const payFresh = await startPay(fresh.publicId);

  await svc.reconcileStale();
  assert.equal((await getOrder(paid.publicId)).paymentStatus, 'paid');
  assert.equal((await api.ok(api.get(`/customer/payments/${payDead.paymentId}`, { session }))).status, 'expired');
  assert.equal((await api.ok(api.get(`/customer/payments/${payFresh.paymentId}`, { session }))).status, 'pending');
  await conn.end();
  await api.ok(api.post(`/customer/payments/${payFresh.paymentId}/abandon`, {}, { session }));
  assert.equal((await startPay(dead.publicId)).status, 'pending', 'an expired attempt no longer blocks paying');
});

test('split payment: online part, cash part, and one invoice when the balance reaches zero', async () => {
  const o = await order();
  const partial = await startPay(o.publicId, { amount: '50.25' });
  assert.equal(partial.checkout.amountMinor, 5025);
  await hook('payment.captured', { payment: mock.pay(partial.checkout.orderId) });
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'partially_paid');
  const invoices = async () => (await api.ok(api.get('/cafe/invoices', { token }))).length;
  const before = await invoices();
  await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId }, { ...staff(), key: key() }));
  assert.equal((await getOrder(o.publicId)).paymentStatus, 'paid');
  assert.equal(await invoices(), before + 1);
  await balanced();
});

test('payment links: created by staff, paid by webhook or found by the sweep; the unrelated capture event is harmless', async () => {
  const o = await api.ok(api.post('/cafe/orders', { items: [{ productId, quantity: 1 }] }, staff()));
  const link = await api.ok(api.post(`/cafe/orders/${o.publicId}/payment-link`, {}, { ...staff(), key: key() }));
  assert.match(link.shortUrl, /^https:\/\/rzp\.io\//);
  const plink = [...mock.links.values()].at(-1)!;
  assert.equal(plink.amount, 10050);
  const { payment, link: paidLink } = mock.payLink(plink.id);
  assert.equal((await hook('payment.captured', { payment })).status, 200);
  assert.equal((await hook('payment_link.paid', { payment, payment_link: paidLink, order: { id: payment.order_id } })).status, 200);
  assert.equal((await api.ok(api.get(`/cafe/orders/${o.publicId}`, staff()))).paymentStatus, 'paid');

  const { PaymentsService } = await import('../src/modules/payments/payments.service');
  const o2 = await api.ok(api.post('/cafe/orders', { items: [{ productId, quantity: 1 }] }, staff()));
  const l2 = await api.ok(api.post(`/cafe/orders/${o2.publicId}/payment-link`, {}, { ...staff(), key: key() }));
  mock.payLink([...mock.links.values()].at(-1)!.id);
  const conn = await adminConnection();
  await conn.query(`UPDATE payments SET created_at = UTC_TIMESTAMP(3) - INTERVAL 6 MINUTE WHERE public_id = ?`, [l2.paymentId]);
  await conn.end();
  await app.get(PaymentsService).reconcileStale();
  assert.equal((await api.ok(api.get(`/cafe/orders/${o2.publicId}`, staff()))).paymentStatus, 'paid');
});

test('refunds through the gateway: instant, pending then webhook, failed releases the amount, and the sweep catches a lost event', async () => {
  const { PaymentsService } = await import('../src/modules/payments/payments.service');
  const paidOrder = async () => {
    const o = await order();
    const pay = await startPay(o.publicId);
    const p = mock.pay(pay.checkout.orderId);
    await hook('payment.captured', { payment: p });
    return { o, id: pay.paymentId as string, p };
  };
  const refund = async (id: string, amount: string) => {
    const r = await api.ok(api.post(`/cafe/payments/${id}/refunds`, { amount, reason: 'test refund' }, { ...staff(), key: key() }));
    return { id: r.refundId as string, approved: await api.ok(api.post(`/cafe/refunds/${r.refundId}/approve`, {}, staff())) };
  };
  const a = await paidOrder();
  const r1 = await refund(a.id, '40.50');
  assert.equal(r1.approved.status, 'succeeded');
  const sent = [...mock.refunds.values()].at(-1)!;
  assert.equal(sent.amount, 4050);
  assert.equal(sent.receipt, r1.id, 'the receipt is the idempotency key');
  assert.equal((await getOrder(a.o.publicId)).paymentStatus, 'partially_refunded');

  mock.refundStatus = 'pending';
  const b = await paidOrder();
  const r2 = await refund(b.id, '100.50');
  assert.equal(r2.approved.status, 'processing');
  assert.equal((await getOrder(b.o.publicId)).paymentStatus, 'paid', 'not refunded until the gateway says so');
  const rf = [...mock.refunds.values()].at(-1)!;
  await hook('refund.processed', { refund: { ...rf, status: 'processed' }, payment: b.p });
  assert.equal((await getOrder(b.o.publicId)).paymentStatus, 'refunded');

  const c = await paidOrder();
  await refund(c.id, '100.50');
  const rfC = [...mock.refunds.values()].at(-1)!;
  await hook('refund.failed', { refund: { ...rfC, status: 'failed' }, payment: c.p });
  assert.equal((await getOrder(c.o.publicId)).paymentStatus, 'paid');
  const r4 = await refund(c.id, '100.50');
  assert.equal(r4.approved.status, 'processing', 'a failed refund released its amount');

  const rfLost = [...mock.refunds.values()].at(-1)!;
  rfLost.status = 'processed';
  const conn = await adminConnection();
  await conn.query(`UPDATE refunds SET updated_at = UTC_TIMESTAMP(3) - INTERVAL 10 MINUTE WHERE public_id = ?`, [r4.id]);
  await conn.end();
  await app.get(PaymentsService).reconcileStale();
  assert.equal((await getOrder(c.o.publicId)).paymentStatus, 'refunded');
  mock.refundStatus = 'processed';
  await balanced();
});

test('settlements: matched to our payments, fees booked from what reached the bank, re-sync adds nothing, unknown lines are flagged', async () => {
  const o = await order();
  const pay = await startPay(o.publicId);
  const p = mock.pay(pay.checkout.orderId);
  await hook('payment.captured', { payment: p });
  const before = await ledger();
  const num = (row: any, side: string) => Number(row?.[side] ?? 0);
  const now = Math.floor(Date.now() / 1000);
  mock.settlements = [{ id: 'setl_1', amount: 9814, status: 'processed', fees: 236, tax: 36, utr: 'UTR1', created_at: now, currency: 'INR' }, { id: 'setl_x', amount: 1, status: 'created', fees: 0, tax: 0, created_at: now }];
  mock.recon = [{ entity_id: p.id, type: 'payment', amount: 10050, credit: 9814, debit: 0, fee: 200, tax: 36, currency: 'INR', settlement_id: 'setl_1', settled: true }];
  const range = { from: new Date(now * 1000 - 86400_000).toISOString(), to: new Date(now * 1000 + 60000).toISOString() };
  assert.deepEqual(await api.ok(api.post('/cafe/settlements/sync', range, { token })), { imported: 1, mismatched: 0 });
  const list = await api.ok(api.get('/cafe/settlements', { token }));
  assert.equal(list[0].status, 'reconciled');
  assert.equal(list[0].net_amount, '98.1400');
  assert.equal(list[0].gross_amount, '100.5000');
  assert.equal(list[0].fee_amount, '2.3600', 'gross minus what reached the bank, fee and tax together');
  const after_ = await ledger();
  assert.equal((num(after_['1010'], 'debit') - num(before['1010'], 'debit')).toFixed(2), '98.14', 'bank');
  assert.equal((num(after_['6300'], 'debit') - num(before['6300'], 'debit')).toFixed(2), '2.36', 'gateway fees');
  assert.equal((num(after_['1100'], 'credit') - num(before['1100'], 'credit')).toFixed(2), '100.50', 'clearing');
  await balanced();
  assert.deepEqual(await api.ok(api.post('/cafe/settlements/sync', range, { token })), { imported: 0, mismatched: 0 });

  mock.settlements = [{ id: 'setl_2', amount: 500, status: 'processed', fees: 10, tax: 2, created_at: now, currency: 'INR' }];
  mock.recon = [{ entity_id: 'pay_unknown', type: 'payment', amount: 510, credit: 500, debit: 0, fee: 10, tax: 2, currency: 'INR', settlement_id: 'setl_2' }];
  assert.deepEqual(await api.ok(api.post('/cafe/settlements/sync', range, { token })), { imported: 1, mismatched: 1 });
  assert.equal((await api.ok(api.get('/cafe/settlements', { token }))).find((x: any) => x.provider_settlement_ref === 'setl_2').status, 'mismatch');
  await balanced();
});

test('a live key always wins over a sandbox one', async () => {
  const conn = await adminConnection();
  const [[row]]: any = await conn.query(`SELECT cafe_id, credentials_ciphertext, encryption_key_id FROM payment_gateway_accounts WHERE public_id = ?`, [account]);
  await conn.query(`INSERT INTO payment_gateway_accounts SET ?`, [{ public_id: 'LIVEACCOUNTLIVEACCOUNTLIVE', cafe_id: row.cafe_id, provider_code: 'razorpay', environment: 'live', credentials_ciphertext: row.credentials_ciphertext, encryption_key_id: row.encryption_key_id, status: 'active' }]);
  await conn.end();
  assert.equal((await api.ok(api.get('/customer/payment-options', { session }))).online.environment, 'live');
  void slug;
});
