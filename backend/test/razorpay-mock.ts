// A stand-in for Razorpay's API, shaped after its public docs, so the real adapter's HTTP code can run with no keys.
// It proves our side of the contract. It does NOT prove that Razorpay behaves like this: run `npm run razorpay:check`.
import { createHmac } from 'node:crypto';
import { createServer, Server } from 'node:http';
import type { AddressInfo } from 'node:net';

export const KEY_ID = 'rzp_test_mock';
export const KEY_SECRET = 'mock_secret';
export const WEBHOOK_SECRET = 'mock_webhook_secret';

type Ent = Record<string, any>;
let seq = 0;
const id = (p: string) => `${p}_${String(++seq).padStart(14, '0')}`;

export class RazorpayMock {
  orders = new Map<string, Ent>();
  payments = new Map<string, Ent>();
  refunds = new Map<string, Ent>();
  links = new Map<string, Ent>();
  settlements: Ent[] = [];
  recon: Ent[] = [];
  autoCapture = true;
  refundStatus = 'processed';
  failNext = 0;
  private server?: Server;
  base = '';

  async start(port = 0) {
    this.server = createServer((req, res) => {
      let body = '';
      req.on('data', (c) => (body += c));
      req.on('end', () => {
        const url = new URL(req.url!, 'http://x');
        res.setHeader('Access-Control-Allow-Origin', '*');
        const send = (status: number, data: unknown) => { res.statusCode = status; res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(data)); };
        // Browser side of the simulator, used by the checkout page below.
        if (url.pathname === '/checkout.js') { res.setHeader('Content-Type', 'text/javascript'); res.end(this.checkoutJs()); return; }
        if (url.pathname === '/__pay') {
          const p = this.pay(url.searchParams.get('order')!);
          send(200, { razorpay_payment_id: p.id, razorpay_order_id: p.order_id, razorpay_signature: this.sign(p.order_id, p.id) });
          return;
        }
        if (this.failNext > 0) { this.failNext -= 1; send(500, { error: { code: 'SERVER_ERROR' } }); return; }
        const expected = `Basic ${Buffer.from(`${KEY_ID}:${KEY_SECRET}`).toString('base64')}`;
        if (req.headers.authorization !== expected) { send(401, { error: { code: 'BAD_REQUEST_ERROR', description: 'Authentication failed' } }); return; }
        const json: Ent = body ? JSON.parse(body) : {};
        const path = url.pathname.replace(/^\/v1/, '');
        let m: RegExpExecArray | null;
        if (path === '/orders' && req.method === 'GET') return send(200, { entity: 'collection', count: 0, items: [] });
        if (path === '/orders' && req.method === 'POST') {
          if (!Number.isInteger(json.amount) || json.amount < 100) return send(400, { error: { code: 'BAD_REQUEST_ERROR', description: 'amount must be an integer of at least 100' } });
          const o = { id: id('order'), entity: 'order', amount: json.amount, currency: json.currency, receipt: json.receipt, notes: json.notes, status: 'created' };
          this.orders.set(o.id, o);
          return send(200, o);
        }
        if ((m = /^\/orders\/([^/]+)\/payments$/.exec(path))) return send(200, { items: [...this.payments.values()].filter((p) => p.order_id === m![1]) });
        if ((m = /^\/payments\/([^/]+)\/capture$/.exec(path))) {
          const p = this.payments.get(m[1]!);
          if (!p || p.status !== 'authorized' || p.amount !== json.amount) return send(400, { error: { code: 'BAD_REQUEST_ERROR' } });
          p.status = 'captured'; p.captured = true;
          return send(200, p);
        }
        if ((m = /^\/payments\/([^/]+)\/refund$/.exec(path))) {
          const p = this.payments.get(m[1]!);
          if (!p) return send(400, { error: { code: 'BAD_REQUEST_ERROR' } });
          const dup = [...this.refunds.values()].find((x) => x.receipt === json.receipt);
          if (dup) return send(400, { error: { code: 'BAD_REQUEST_ERROR', description: 'duplicate receipt' } });
          const r = { id: id('rfnd'), entity: 'refund', amount: json.amount, currency: p.currency, payment_id: p.id, receipt: json.receipt, status: this.refundStatus };
          this.refunds.set(r.id, r);
          return send(200, r);
        }
        if ((m = /^\/refunds\/([^/]+)$/.exec(path))) return this.refunds.has(m[1]!) ? send(200, this.refunds.get(m[1]!)) : send(404, {});
        if (path === '/payment_links' && req.method === 'POST') {
          const l = { id: id('plink'), amount: json.amount, currency: json.currency, reference_id: json.reference_id, notes: json.notes, short_url: `https://rzp.io/i/${seq}`, status: 'created', payments: null as Ent[] | null };
          this.links.set(l.id, l);
          return send(200, l);
        }
        if ((m = /^\/payment_links\/([^/]+)$/.exec(path))) return this.links.has(m[1]!) ? send(200, this.links.get(m[1]!)) : send(404, {});
        if (path === '/settlements') return send(200, { items: this.settlements.slice(Number(url.searchParams.get('skip') ?? 0)) });
        if (path === '/settlements/recon/combined') return send(200, { items: this.recon.slice(Number(url.searchParams.get('skip') ?? 0)) });
        send(404, { error: { code: 'NOT_FOUND', path } });
      });
    });
    await new Promise<void>((r) => this.server!.listen(port, '127.0.0.1', r));
    this.base = `http://127.0.0.1:${(this.server.address() as AddressInfo).port}/v1`;
    return this;
  }
  stop() { this.server?.closeAllConnections(); this.server?.close(); }

  sign(orderId: string, paymentId: string, secret = KEY_SECRET) { return createHmac('sha256', secret).update(`${orderId}|${paymentId}`).digest('hex'); }

  // The customer completes payment in Checkout.
  pay(orderId: string, opts: { fee?: number; method?: string } = {}) {
    const o = this.orders.get(orderId)!;
    const p: Ent = { id: id('pay'), entity: 'payment', amount: o.amount, currency: o.currency, order_id: o.id, method: opts.method ?? 'upi', status: this.autoCapture ? 'captured' : 'authorized', captured: this.autoCapture, fee: this.autoCapture ? opts.fee ?? 236 : null, tax: 36, notes: o.notes, email: 'guest@example.test', contact: '+919999999999' };
    this.payments.set(p.id, p);
    return p;
  }

  payLink(linkId: string) {
    const l = this.links.get(linkId)!;
    const p: Ent = { id: id('pay'), entity: 'payment', amount: l.amount, currency: l.currency, order_id: id('order'), method: 'upi', status: 'captured', captured: true, fee: 236, notes: {} };
    this.payments.set(p.id, p);
    l.status = 'paid'; l.amount_paid = l.amount;
    l.payments = [{ amount: l.amount, method: 'upi', payment_id: p.id, plink_id: l.id, status: 'captured' }];
    return { payment: p, link: l };
  }

  event(name: string, payload: Ent, eventId = id('evt')) {
    const raw = JSON.stringify({ entity: 'event', event: name, contains: Object.keys(payload), payload: Object.fromEntries(Object.entries(payload).map(([k, v]) => [k, { entity: v }])), created_at: Math.floor(Date.now() / 1000) });
    return { raw, eventId, signature: createHmac('sha256', WEBHOOK_SECRET).update(raw).digest('hex') };
  }

  // Stands in for checkout.razorpay.com/v1/checkout.js: same constructor and callbacks as the documented script.
  private checkoutJs() {
    return `window.Razorpay = function (options) {
      this.open = function () {
        window.__razorpayOptions = options;
        fetch('${this.base.replace('/v1', '')}/__pay?order=' + options.order_id).then(function (r) { return r.json(); }).then(function (r) { options.handler(r); });
      };
      this.on = function () {};
    };`;
  }
}
