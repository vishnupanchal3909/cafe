import { call, fromMinor, hmacHex, PaymentProvider, safeEqual, toMinor, VerifiedEvent, WebhookSignatureError } from './provider';

// PENDING CONFIGURATION: written against Stripe's public API docs. Not yet exercised against test mode.
const API = 'https://api.stripe.com/v1';
const headers = (c: { keySecret?: string }, extra: Record<string, string> = {}) => ({ Authorization: `Bearer ${c.keySecret}`, 'Content-Type': 'application/x-www-form-urlencoded', ...extra });
const form = (o: Record<string, string>) => new URLSearchParams(o).toString();
const TOLERANCE_SECONDS = 300;

export const stripe: PaymentProvider = {
  code: 'stripe',
  async verifyCredentials(c) { await call(`${API}/balance`, { headers: headers(c) }); },
  async createCheckout(i, c) {
    const s = await call(`${API}/checkout/sessions`, {
      method: 'POST', headers: headers(c, { 'Idempotency-Key': i.reference }),
      body: form({ mode: 'payment', 'line_items[0][quantity]': '1', 'line_items[0][price_data][currency]': i.currency.toLowerCase(), 'line_items[0][price_data][unit_amount]': toMinor(i.amount, i.minorUnit), 'line_items[0][price_data][product_data][name]': i.description, client_reference_id: i.reference, success_url: i.returnUrl, cancel_url: i.returnUrl }),
    });
    return { providerOrderRef: s.id, checkout: { provider: 'stripe', redirectUrl: s.url } };
  },
  async fetchPayment(ref, minorUnit, c) {
    const s = await call(`${API}/checkout/sessions/${encodeURIComponent(ref)}`, { headers: headers(c) });
    if (s.payment_status === 'paid') return { status: 'captured', providerPaymentRef: s.payment_intent, amount: fromMinor(s.amount_total, minorUnit), currency: String(s.currency).toUpperCase() };
    return { status: s.status === 'expired' ? 'failed' : 'pending' };
  },
  verifyWebhook(raw, h, c, unit) {
    const header = h['stripe-signature'];
    if (!c.webhookSecret || typeof header !== 'string') throw new WebhookSignatureError('Missing Stripe signature');
    const parts = Object.fromEntries(header.split(',').map((p) => p.split('=') as [string, string]));
    const t = Number(parts.t);
    if (!t || Math.abs(Date.now() / 1000 - t) > TOLERANCE_SECONDS) throw new WebhookSignatureError('Stale Stripe timestamp');
    if (!parts.v1 || !safeEqual(hmacHex(c.webhookSecret, `${t}.${raw.toString('utf8')}`), parts.v1)) throw new WebhookSignatureError('Bad Stripe signature');
    const e = JSON.parse(raw.toString('utf8'));
    const o = e.data?.object ?? {};
    const base: VerifiedEvent = { eventId: e.id, type: e.type, kind: 'ignored', raw: { type: e.type, id: o.id, status: o.status } };
    if (e.type === 'checkout.session.completed' && o.payment_status === 'paid') {
      const cur = String(o.currency).toUpperCase();
      return { ...base, kind: 'captured', providerOrderRef: o.id, providerPaymentRef: o.payment_intent, amount: fromMinor(o.amount_total, unit(cur)), currency: cur };
    }
    if (e.type === 'checkout.session.expired') return { ...base, kind: 'failed', providerOrderRef: o.id };
    if (e.type === 'charge.refunded') return { ...base, kind: 'refund_succeeded', providerPaymentRef: o.payment_intent };
    return base;
  },
  async refund(i, c) {
    const r = await call(`${API}/refunds`, { method: 'POST', headers: headers(c, { 'Idempotency-Key': i.idempotencyKey }), body: form({ payment_intent: i.providerPaymentRef, amount: toMinor(i.amount, i.minorUnit) }) });
    return { providerRefundRef: r.id, status: r.status === 'succeeded' ? 'succeeded' : r.status === 'failed' ? 'failed' : 'processing' };
  },
  async fetchSettlements(from, to, c, unit) {
    const r = await call(`${API}/payouts?arrival_date[gte]=${Math.floor(from.getTime() / 1000)}&arrival_date[lte]=${Math.floor(to.getTime() / 1000)}&limit=100`, { headers: headers(c) });
    return ((r.data ?? []) as Array<Record<string, any>>).map((p) => {
      const currency = String(p.currency).toUpperCase();
      const net = fromMinor(p.amount, unit(currency));
      return { ref: p.id, currency, fee: '0', tax: '0', net, settledAt: new Date(p.arrival_date * 1000) };
    });
  },
};
