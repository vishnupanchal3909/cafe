import { createHmac, timingSafeEqual } from 'node:crypto';
import { D } from '../../../common/money';

export interface GatewayCredentials { keyId?: string; keySecret?: string; webhookSecret?: string }
export interface CheckoutInput { amount: string; currency: string; minorUnit: number; reference: string; description: string; returnUrl: string; methodCode: string }
export interface CheckoutSession { providerOrderRef: string; checkout: Record<string, unknown> }
export interface VerifiedEvent { eventId: string; type: string; kind: 'authorized' | 'captured' | 'failed' | 'refund_succeeded' | 'refund_failed' | 'ignored'; reference?: string; providerOrderRef?: string; providerPaymentRef?: string; providerRefundRef?: string; amount?: string; currency?: string; feeAmount?: string; instrumentSummary?: string; raw: Record<string, unknown> }
export interface ProviderPayment { status: 'captured' | 'failed' | 'pending'; providerPaymentRef?: string; amount?: string; currency?: string; feeAmount?: string; instrumentSummary?: string }
export interface ProviderRefund { providerRefundRef: string; status: 'succeeded' | 'processing' | 'failed' }
export interface ProviderSettlement { ref: string; currency: string; fee: string; tax: string; net: string; settledAt: Date }
export interface ProviderSettlementItem { type: 'payment' | 'refund' | 'other'; providerRef: string; amount: string; fee: string }

export class WebhookSignatureError extends Error {}
export class GatewayError extends Error { constructor(readonly status: number, message: string) { super(message); } }

export interface PaymentProvider {
  readonly code: string;
  createCheckout(input: CheckoutInput, creds: GatewayCredentials): Promise<CheckoutSession>;
  fetchPayment(providerOrderRef: string, minorUnit: number, creds: GatewayCredentials): Promise<ProviderPayment>;
  verifyWebhook(rawBody: Buffer, headers: Record<string, string | string[] | undefined>, creds: GatewayCredentials, minorUnit: (currency: string) => number): VerifiedEvent;
  refund(input: { providerPaymentRef: string; amount: string; currency: string; minorUnit: number; idempotencyKey: string; reference: string }, creds: GatewayCredentials): Promise<ProviderRefund>;
  fetchSettlements(from: Date, to: Date, creds: GatewayCredentials, minorUnit: (currency: string) => number): Promise<ProviderSettlement[]>;
  verifyCredentials?(creds: GatewayCredentials): Promise<void>;
  resumeCheckout?(providerOrderRef: string, input: CheckoutInput, creds: GatewayCredentials): Record<string, unknown>;
  verifyClientCallback?(input: { providerOrderRef: string; providerPaymentRef: string; signature: string }, creds: GatewayCredentials): boolean;
  createPaymentLink?(input: CheckoutInput, creds: GatewayCredentials): Promise<{ providerOrderRef: string; shortUrl: string }>;
  fetchRefund?(providerRefundRef: string, creds: GatewayCredentials): Promise<ProviderRefund>;
  fetchSettlementItems?(settlement: { ref: string; settledAt: Date }, creds: GatewayCredentials, minorUnit: (currency: string) => number): Promise<ProviderSettlementItem[]>;
}

// Gateways speak the smallest unit. JPY has no x100, so this must always use the real exponent.
export const toMinor = (amount: string, minorUnit: number) => D(amount).times(D(10).pow(minorUnit)).toFixed(0);
export const fromMinor = (minor: string | number, minorUnit: number) => D(minor).div(D(10).pow(minorUnit)).toString();

export function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}
export const hmacHex = (secret: string, body: Buffer | string) => createHmac('sha256', secret).update(body).digest('hex');
export const hmacBase64 = (secret: string, body: Buffer | string) => createHmac('sha256', secret).update(body).digest('base64');

export async function call(url: string, init: RequestInit): Promise<Record<string, any>> {
  const res = await fetch(url, { ...init, signal: AbortSignal.timeout(15000) });
  const text = await res.text();
  let body: Record<string, any> = {};
  try { body = text ? JSON.parse(text) : {}; } catch { body = { raw: text.slice(0, 500) }; }
  if (!res.ok) throw new GatewayError(res.status, `Gateway ${new URL(url).host} responded ${res.status}: ${JSON.stringify(body).slice(0, 300)}`);
  return body;
}
