import { call, fromMinor, hmacHex, PaymentProvider, ProviderPayment, safeEqual, toMinor, VerifiedEvent, WebhookSignatureError } from './provider';

// Written against Razorpay's public docs and exercised against test/razorpay-mock.ts. PENDING CONFIGURATION until a
// real test-mode run passes: `npm run razorpay:check`, then the checklist in docs/PAYMENT_INTEGRATION.md.
const api = () => (process.env.NODE_ENV !== 'production' && process.env.RAZORPAY_API_BASE) || 'https://api.razorpay.com/v1';
const auth = (c: { keyId?: string; keySecret?: string }) => `Basic ${Buffer.from(`${c.keyId}:${c.keySecret}`).toString('base64')}`;
const json = (c: { keyId?: string; keySecret?: string }, extra: Record<string, string> = {}) => ({ Authorization: auth(c), 'Content-Type': 'application/json', ...extra });

type Entity = Record<string, any>;

function toProviderPayment(p: Entity, minorUnit: number): ProviderPayment {
  return { status: 'captured', providerPaymentRef: p.id, amount: fromMinor(p.amount, minorUnit), currency: p.currency, feeAmount: p.fee != null ? fromMinor(p.fee, minorUnit) : undefined, instrumentSummary: p.method };
}

export const razorpay: PaymentProvider = {
  code: 'razorpay',

  async verifyCredentials(c) {
    await call(`${api()}/orders?count=1`, { headers: { Authorization: auth(c) } });
  },

  async createCheckout(i, c) {
    const o = await call(`${api()}/orders`, { method: 'POST', headers: json(c), body: JSON.stringify({ amount: Number(toMinor(i.amount, i.minorUnit)), currency: i.currency, receipt: i.reference.slice(0, 40), notes: { reference: i.reference } }) });
    return { providerOrderRef: o.id, checkout: { provider: 'razorpay', orderId: o.id, keyId: c.keyId, amountMinor: o.amount, currency: o.currency, description: i.description, method: i.methodCode } };
  },

  // A retried request gets the same order back, so a dropped connection cannot start a second charge.
  resumeCheckout(ref, i, c) {
    return { provider: 'razorpay', orderId: ref, keyId: c.keyId, amountMinor: Number(toMinor(i.amount, i.minorUnit)), currency: i.currency, description: i.description, method: i.methodCode };
  },

  // Always compared with the order id we stored, never one sent back by the browser.
  verifyClientCallback(i, c) {
    if (!c.keySecret) return false;
    return safeEqual(hmacHex(c.keySecret, `${i.providerOrderRef}|${i.providerPaymentRef}`), i.signature);
  },

  async createPaymentLink(i, c) {
    const link = await call(`${api()}/payment_links`, {
      method: 'POST', headers: json(c),
      body: JSON.stringify({ amount: Number(toMinor(i.amount, i.minorUnit)), currency: i.currency, description: i.description, reference_id: i.reference.slice(0, 40), callback_url: i.returnUrl, callback_method: 'get', notes: { reference: i.reference } }),
    });
    return { providerOrderRef: link.id, shortUrl: link.short_url };
  },

  async fetchPayment(ref, minorUnit, c) {
    if (ref.startsWith('plink_')) {
      const link = await call(`${api()}/payment_links/${encodeURIComponent(ref)}`, { headers: { Authorization: auth(c) } });
      const paid = ((link.payments ?? []) as Entity[]).find((p) => p.status === 'captured');
      if (link.status === 'paid' && paid) return { status: 'captured', providerPaymentRef: paid.payment_id, amount: fromMinor(paid.amount, minorUnit), currency: link.currency };
      return { status: ['cancelled', 'expired'].includes(link.status) ? 'failed' : 'pending' };
    }
    const r = await call(`${api()}/orders/${encodeURIComponent(ref)}/payments`, { headers: { Authorization: auth(c) } });
    const items = (r.items ?? []) as Entity[];
    const captured = items.find((p) => p.status === 'captured');
    if (captured) return toProviderPayment(captured, minorUnit);
    // Razorpay refunds uncaptured payments on its own after a while, so an authorization is captured here.
    const authorized = items.find((p) => p.status === 'authorized');
    if (authorized) {
      const done = await call(`${api()}/payments/${encodeURIComponent(authorized.id)}/capture`, { method: 'POST', headers: json(c), body: JSON.stringify({ amount: authorized.amount, currency: authorized.currency }) });
      return toProviderPayment(done, minorUnit);
    }
    // A failed attempt is not final: the customer can retry the same order inside Checkout.
    return { status: 'pending' };
  },

  verifyWebhook(raw, headers, c, unit) {
    const sig = headers['x-razorpay-signature'];
    if (!c.webhookSecret || typeof sig !== 'string' || !safeEqual(hmacHex(c.webhookSecret, raw), sig)) throw new WebhookSignatureError('Bad Razorpay signature');
    const body = JSON.parse(raw.toString('utf8'));
    const p: Entity | undefined = body.payload?.payment?.entity;
    const rf: Entity | undefined = body.payload?.refund?.entity;
    const link: Entity | undefined = body.payload?.payment_link?.entity;
    const order: Entity | undefined = body.payload?.order?.entity;
    const eventId = String(headers['x-razorpay-event-id'] ?? `${body.event}:${body.created_at}:${p?.id ?? rf?.id ?? link?.id ?? order?.id}`);
    // Only what reconciliation needs. Contact details and card data in the payload are never stored.
    const base: VerifiedEvent = { eventId, type: body.event, kind: 'ignored', raw: { event: body.event, paymentId: p?.id, orderId: p?.order_id ?? order?.id, refundId: rf?.id, linkId: link?.id, status: p?.status ?? rf?.status ?? link?.status, method: p?.method, errorCode: p?.error_code } };
    const money = (m: Entity) => ({ amount: fromMinor(m.amount, unit(m.currency)), currency: m.currency as string, feeAmount: m.fee != null ? fromMinor(m.fee, unit(m.currency)) : undefined });
    switch (body.event) {
      case 'payment.authorized':
        return p ? { ...base, kind: 'authorized', providerOrderRef: p.order_id, providerPaymentRef: p.id, reference: p.notes?.reference } : base;
      case 'payment.captured':
      case 'order.paid':
        return p ? { ...base, kind: 'captured', providerOrderRef: p.order_id, providerPaymentRef: p.id, reference: p.notes?.reference, instrumentSummary: p.method, ...money(p) } : base;
      case 'payment_link.paid':
        return p && link ? { ...base, kind: 'captured', providerOrderRef: link.id, providerPaymentRef: p.id, reference: link.notes?.reference, instrumentSummary: p.method, ...money(p) } : base;
      case 'payment.failed':
        return p ? { ...base, kind: 'failed', providerOrderRef: p.order_id, providerPaymentRef: p.id, reference: p.notes?.reference } : base;
      case 'refund.processed':
        return rf ? { ...base, kind: 'refund_succeeded', providerRefundRef: rf.id, providerPaymentRef: rf.payment_id } : base;
      case 'refund.failed':
        return rf ? { ...base, kind: 'refund_failed', providerRefundRef: rf.id, providerPaymentRef: rf.payment_id } : base;
      default:
        return base;
    }
  },

  // No `speed`: normal refunds carry no extra charge. `receipt` is Razorpay's idempotency key for refunds.
  async refund(i, c) {
    const r = await call(`${api()}/payments/${encodeURIComponent(i.providerPaymentRef)}/refund`, { method: 'POST', headers: json(c), body: JSON.stringify({ amount: Number(toMinor(i.amount, i.minorUnit)), receipt: i.reference.slice(0, 40), notes: { reference: i.reference } }) });
    return { providerRefundRef: r.id, status: r.status === 'processed' ? 'succeeded' : r.status === 'failed' ? 'failed' : 'processing' };
  },

  async fetchRefund(ref, c) {
    const r = await call(`${api()}/refunds/${encodeURIComponent(ref)}`, { headers: { Authorization: auth(c) } });
    return { providerRefundRef: r.id, status: r.status === 'processed' ? 'succeeded' : r.status === 'failed' ? 'failed' : 'processing' };
  },

  async fetchSettlements(from, to, c, unit) {
    const out = [];
    for (let skip = 0; ; skip += 100) {
      const r = await call(`${api()}/settlements?from=${Math.floor(from.getTime() / 1000)}&to=${Math.floor(to.getTime() / 1000)}&count=100&skip=${skip}`, { headers: { Authorization: auth(c) } });
      const items = (r.items ?? []) as Entity[];
      for (const s of items.filter((x) => x.status === 'processed')) {
        const currency = s.currency ?? 'INR';
        const m = unit(currency);
        out.push({ ref: s.id, currency, net: fromMinor(s.amount, m), fee: fromMinor(s.fees ?? 0, m), tax: fromMinor(s.tax ?? 0, m), settledAt: new Date((s.created_at ?? 0) * 1000) });
      }
      if (items.length < 100) return out;
    }
  },

  async fetchSettlementItems(settlement, c, unit) {
    const d = settlement.settledAt;
    const out = [];
    for (let skip = 0; ; skip += 1000) {
      const r = await call(`${api()}/settlements/recon/combined?year=${d.getUTCFullYear()}&month=${String(d.getUTCMonth() + 1).padStart(2, '0')}&day=${d.getUTCDate()}&count=1000&skip=${skip}`, { headers: { Authorization: auth(c) } });
      const items = (r.items ?? []) as Entity[];
      for (const x of items.filter((i) => i.settlement_id === settlement.ref)) {
        const m = unit(x.currency ?? 'INR');
        out.push({ type: x.type === 'payment' ? 'payment' as const : x.type === 'refund' ? 'refund' as const : 'other' as const, providerRef: x.entity_id, amount: fromMinor(x.amount, m), fee: fromMinor(x.fee ?? 0, m) });
      }
      if (items.length < 1000) return out;
    }
  },
};
