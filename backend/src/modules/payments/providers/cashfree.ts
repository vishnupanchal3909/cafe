import { call, hmacBase64, PaymentProvider, safeEqual, VerifiedEvent, WebhookSignatureError } from './provider';

// PENDING CONFIGURATION: written against Cashfree's public PG docs. Not yet exercised against a sandbox.
const API = process.env.CASHFREE_ENV === 'live' ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg';
const headers = (c: { keyId?: string; keySecret?: string }, extra: Record<string, string> = {}) => ({ 'x-client-id': c.keyId ?? '', 'x-client-secret': c.keySecret ?? '', 'x-api-version': '2023-08-01', 'Content-Type': 'application/json', ...extra });

export const cashfree: PaymentProvider = {
  code: 'cashfree',
  async createCheckout(i, c) {
    const o = await call(`${API}/orders`, { method: 'POST', headers: headers(c, { 'x-idempotency-key': i.reference }), body: JSON.stringify({ order_id: i.reference, order_amount: Number(i.amount), order_currency: i.currency, customer_details: { customer_id: i.reference.slice(0, 40), customer_phone: '0000000000' }, order_meta: { return_url: i.returnUrl } }) });
    return { providerOrderRef: o.order_id, checkout: { provider: 'cashfree', paymentSessionId: o.payment_session_id } };
  },
  async fetchPayment(ref, _m, c) {
    const o = await call(`${API}/orders/${encodeURIComponent(ref)}`, { headers: headers(c) });
    if (o.order_status === 'PAID') return { status: 'captured', providerPaymentRef: String(o.cf_order_id), amount: String(o.order_amount), currency: o.order_currency };
    return { status: ['EXPIRED', 'TERMINATED'].includes(o.order_status) ? 'failed' : 'pending' };
  },
  verifyWebhook(raw, h, c) {
    const sig = h['x-webhook-signature'];
    const ts = h['x-webhook-timestamp'];
    if (!c.keySecret || typeof sig !== 'string' || typeof ts !== 'string' || !safeEqual(hmacBase64(c.keySecret, ts + raw.toString('utf8')), sig)) throw new WebhookSignatureError('Bad Cashfree signature');
    const e = JSON.parse(raw.toString('utf8'));
    const pay = e.data?.payment ?? {};
    const order = e.data?.order ?? {};
    const base: VerifiedEvent = { eventId: String(h['x-idempotency-key'] ?? `${e.type}:${pay.cf_payment_id ?? e.data?.refund?.cf_refund_id}`), type: e.type, kind: 'ignored', raw: { type: e.type, orderId: order.order_id, paymentId: pay.cf_payment_id, status: pay.payment_status } };
    if (e.type === 'PAYMENT_SUCCESS_WEBHOOK') return { ...base, kind: 'captured', providerOrderRef: order.order_id, providerPaymentRef: String(pay.cf_payment_id), amount: String(pay.payment_amount), currency: pay.payment_currency, instrumentSummary: pay.payment_group };
    if (e.type === 'PAYMENT_FAILED_WEBHOOK') return { ...base, kind: 'failed', providerOrderRef: order.order_id, providerPaymentRef: String(pay.cf_payment_id) };
    if (e.type === 'REFUND_STATUS_WEBHOOK') {
      const rf = e.data?.refund ?? {};
      return { ...base, kind: rf.refund_status === 'SUCCESS' ? 'refund_succeeded' : 'refund_failed', providerRefundRef: rf.refund_id };
    }
    return base;
  },
  async refund(i, c) {
    const r = await call(`${API}/orders/${encodeURIComponent(i.providerPaymentRef)}/refunds`, { method: 'POST', headers: headers(c), body: JSON.stringify({ refund_amount: Number(i.amount), refund_id: i.idempotencyKey }) });
    return { providerRefundRef: r.refund_id ?? i.idempotencyKey, status: r.refund_status === 'SUCCESS' ? 'succeeded' : 'processing' };
  },
  async fetchSettlements() { return []; },
};
