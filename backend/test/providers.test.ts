// Signature checks and unit conversions, offline. This does NOT prove the live gateway APIs work: see PAYMENT_INTEGRATION.md.
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';
import { fromMinor, toMinor, WebhookSignatureError } from '../src/modules/payments/providers/provider';
import { cashfree } from '../src/modules/payments/providers/cashfree';
import { razorpay } from '../src/modules/payments/providers/razorpay';
import { stripe } from '../src/modules/payments/providers/stripe';

const unit = (c: string) => (c === 'JPY' ? 0 : 2);

test('minor units respect the currency exponent', () => {
  assert.equal(toMinor('105.50', 2), '10550');
  assert.equal(toMinor('1250', 0), '1250');
  assert.equal(toMinor('1.234', 3), '1234');
  assert.equal(fromMinor(10550, 2), '105.5');
  assert.equal(fromMinor(1250, 0), '1250');
});

test('razorpay: accepts a good signature, parses capture, rejects tampering', () => {
  const body = Buffer.from(JSON.stringify({ event: 'payment.captured', created_at: 1, payload: { payment: { entity: { id: 'pay_1', order_id: 'order_1', amount: 10550, currency: 'INR', status: 'captured', fee: 200, method: 'upi' } } } }));
  const sig = createHmac('sha256', 'whsec').update(body).digest('hex');
  const e = razorpay.verifyWebhook(body, { 'x-razorpay-signature': sig, 'x-razorpay-event-id': 'ev1' }, { webhookSecret: 'whsec' }, unit);
  assert.equal(e.kind, 'captured');
  assert.equal(e.amount, '105.5');
  assert.equal(e.feeAmount, '2');
  assert.throws(() => razorpay.verifyWebhook(Buffer.from(body.toString().replace('10550', '1')), { 'x-razorpay-signature': sig }, { webhookSecret: 'whsec' }, unit), WebhookSignatureError);
  assert.throws(() => razorpay.verifyWebhook(body, {}, { webhookSecret: 'whsec' }, unit), WebhookSignatureError);
  assert.throws(() => razorpay.verifyWebhook(body, { 'x-razorpay-signature': sig }, {}, unit), WebhookSignatureError);
});

test('stripe: verifies the timestamped signature and refuses replays', () => {
  const body = Buffer.from(JSON.stringify({ id: 'evt_1', type: 'checkout.session.completed', data: { object: { id: 'cs_1', payment_status: 'paid', payment_intent: 'pi_1', amount_total: 1250, currency: 'jpy' } } }));
  const t = Math.floor(Date.now() / 1000);
  const sign = (ts: number) => `t=${ts},v1=${createHmac('sha256', 'whsec').update(`${ts}.${body}`).digest('hex')}`;
  const e = stripe.verifyWebhook(body, { 'stripe-signature': sign(t) }, { webhookSecret: 'whsec' }, unit);
  assert.equal(e.amount, '1250');
  assert.equal(e.currency, 'JPY');
  assert.throws(() => stripe.verifyWebhook(body, { 'stripe-signature': sign(t - 3600) }, { webhookSecret: 'whsec' }, unit), WebhookSignatureError);
  assert.throws(() => stripe.verifyWebhook(body, { 'stripe-signature': `t=${t},v1=deadbeef` }, { webhookSecret: 'whsec' }, unit), WebhookSignatureError);
});

test('cashfree: verifies timestamp plus body', () => {
  const body = Buffer.from(JSON.stringify({ type: 'PAYMENT_SUCCESS_WEBHOOK', data: { order: { order_id: 'o1' }, payment: { cf_payment_id: 9, payment_amount: 105.5, payment_currency: 'INR' } } }));
  const ts = '1700000000';
  const sig = createHmac('sha256', 'secret').update(ts + body.toString()).digest('base64');
  const e = cashfree.verifyWebhook(body, { 'x-webhook-signature': sig, 'x-webhook-timestamp': ts }, { keySecret: 'secret' }, unit);
  assert.equal(e.kind, 'captured');
  assert.throws(() => cashfree.verifyWebhook(body, { 'x-webhook-signature': 'nope', 'x-webhook-timestamp': ts }, { keySecret: 'secret' }, unit), WebhookSignatureError);
});
