import { Injectable, Logger } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, asTenant, requiredUserId, store, tenantId, unscoped } from '../../common/context';
import { config } from '../../common/config';
import { AppError, badRequest, conflict, notFound } from '../../common/errors';
import { decrypt, encrypt, ulid } from '../../common/ids';
import { assertBranchAllowed, idOf } from '../../common/lookup';
import { allocate, assertPrecision, D, dbMoney, money, roundTo, ZERO } from '../../common/money';
import { audit, Db, emit, rooms, staffRooms, Tx } from '../../infra/db/db.service';
import { AccountingService } from '../accounting/accounting.service';
import { InvoicingService } from '../invoicing/invoicing.service';
import { OrderingService } from '../ordering/ordering.service';
import { cashfree } from './providers/cashfree';
import { CheckoutInput, GatewayCredentials, GatewayError, PaymentProvider, VerifiedEvent, WebhookSignatureError } from './providers/provider';
import { razorpay } from './providers/razorpay';
import { releaseTableIfSettled } from '../tables/release';
import { stripe } from './providers/stripe';

// An event that can never succeed, however often it is redelivered. Retryable failures answer 503 instead.
class PermanentEventError extends Error {}

@Injectable()
export class PaymentProviderRegistry {
  private providers = new Map<string, PaymentProvider>([razorpay, stripe, cashfree].map((p) => [p.code, p]));
  get(code: string): PaymentProvider {
    const p = this.providers.get(code);
    if (!p) throw badRequest('PROVIDER_UNSUPPORTED');
    return p;
  }
  // Test doubles are registered only from test code, and never in production.
  register(p: PaymentProvider) {
    if (config.env === 'production') throw new Error('Cannot register a payment provider at runtime in production');
    this.providers.set(p.code, p);
  }
}

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger('Payments');
  constructor(private readonly db: Db, private readonly registry: PaymentProviderRegistry, private readonly ordering: OrderingService, private readonly invoicing: InvoicingService, private readonly accounting: AccountingService) {}

  private async minorUnit(q: Db['q'] | Tx, currency: string) {
    return (await q.selectFrom('currencies').select('minor_unit').where('code', '=', currency).executeTakeFirstOrThrow()).minor_unit;
  }
  private creds(row: { credentials_ciphertext: Buffer | Uint8Array; webhook_secret_ciphertext: Buffer | Uint8Array | null }): GatewayCredentials {
    const base = JSON.parse(decrypt(Buffer.from(row.credentials_ciphertext))) as GatewayCredentials;
    return { ...base, webhookSecret: row.webhook_secret_ciphertext ? decrypt(Buffer.from(row.webhook_secret_ciphertext)) : undefined };
  }

  // Gateway accounts. Secrets go in and are never returned by any endpoint.
  async listAccounts() {
    return this.db.q.selectFrom('payment_gateway_accounts').select(['public_id', 'provider_code', 'environment', 'status', 'updated_at']).where('cafe_id', '=', tenantId()).execute();
  }
  async saveAccount(d: { providerCode: string; environment: 'sandbox' | 'live'; keyId?: string; keySecret: string; webhookSecret?: string }) {
    this.registry.get(d.providerCode);
    return this.db.tx(async (tx) => {
      const credentials = encrypt(JSON.stringify({ keyId: d.keyId, keySecret: d.keySecret }));
      const webhook = d.webhookSecret ? encrypt(d.webhookSecret) : null;
      const publicId = ulid();
      await tx.insertInto('payment_gateway_accounts').values({ public_id: publicId, cafe_id: tenantId(), provider_code: d.providerCode, environment: d.environment, credentials_ciphertext: credentials, webhook_secret_ciphertext: webhook, encryption_key_id: config.encryptionKeyId, status: 'pending_configuration' })
        .onDuplicateKeyUpdate({ credentials_ciphertext: credentials, webhook_secret_ciphertext: webhook, status: 'pending_configuration' }).execute();
      await audit(tx, { action: 'gateway.account_saved', entityType: 'gateway_account', entityId: d.providerCode, after: { environment: d.environment } });
      const row = await tx.selectFrom('payment_gateway_accounts').select('public_id').where('cafe_id', '=', tenantId()).where('provider_code', '=', d.providerCode).where('environment', '=', d.environment).executeTakeFirstOrThrow();
      return { publicId: row.public_id, webhookUrl: `${config.publicApiUrl}/api/v1/webhooks/payments/${d.providerCode}/${row.public_id}` };
    });
  }
  // New keys take no money until the gateway itself has accepted them.
  async testAccount(publicId: string) {
    const account = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!account) throw notFound();
    const provider = this.registry.get(account.provider_code);
    if (!provider.verifyCredentials) throw badRequest('CREDENTIAL_TEST_UNSUPPORTED');
    let status: 'active' | 'pending_configuration' = 'active';
    let failure: AppError | undefined;
    try {
      await provider.verifyCredentials(this.creds(account));
    } catch (e) {
      status = 'pending_configuration';
      failure = e instanceof GatewayError && [401, 403].includes(e.status) ? new AppError(422, 'GATEWAY_CREDENTIALS_INVALID') : new AppError(502, 'GATEWAY_UNAVAILABLE');
    }
    await this.db.tx(async (tx) => {
      await tx.updateTable('payment_gateway_accounts').set({ status }).where('cafe_id', '=', tenantId()).where('id', '=', account.id).execute();
      await audit(tx, { action: 'gateway.account_tested', entityType: 'gateway_account', entityId: publicId, after: { status } });
    });
    if (failure) throw failure;
    return { status };
  }

  private activeAccount(q: Db['q'] | Tx) {
    // If a cafe has both, live wins, so a forgotten sandbox key can never take real orders.
    return q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('status', '=', 'active').orderBy(sql`environment = 'live'`, 'desc').executeTakeFirst();
  }

  async setMethods(codes: string[]) {
    await this.db.tx(async (tx) => {
      await tx.deleteFrom('cafe_payment_methods').where('cafe_id', '=', tenantId()).execute();
      if (codes.length) await tx.insertInto('cafe_payment_methods').values(codes.map((method_code) => ({ cafe_id: tenantId(), method_code }))).execute();
      await audit(tx, { action: 'gateway.methods_updated', after: codes });
    });
    return { ok: true };
  }
  async methods() {
    return this.db.q.selectFrom('cafe_payment_methods as c').innerJoin('payment_methods as m', 'm.code', 'c.method_code').select(['m.code', 'm.name', 'm.is_manual']).where('c.cafe_id', '=', tenantId()).where('c.is_enabled', '=', 1).execute();
  }
  async activeOnlineProvider() {
    const row = await this.activeAccount(this.db.q);
    return row ? { provider: row.provider_code, environment: row.environment } : null;
  }

  // The amount is always bounded by what the server says is still owed. A guest can pay part (split payment).
  async initiate(orderPublicId: string, d: { methodCode: string; amount?: string; billId?: string; flow?: 'checkout' | 'link' }, idempotencyKey: string) {
    if (!idempotencyKey) throw badRequest('IDEMPOTENCY_KEY_REQUIRED');
    const p = store()!.principal!;
    const prepared = await this.db.tx(async (tx) => {
      const cafeId = tenantId();
      const dup = await tx.selectFrom('payments').selectAll().where('cafe_id', '=', cafeId).where('idempotency_key', '=', idempotencyKey).executeTakeFirst();
      if (dup) return { duplicate: dup } as const;
      let oq = tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('public_id', '=', orderPublicId);
      if (p.type === 'table_session') oq = oq.where('session_id', '=', p.tableSessionId!);
      const o = await oq.forUpdate().executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      if (o.status === 'cancelled') throw conflict('ORDER_CANCELLED');
      const pending = await tx.selectFrom('payments').select((eb) => eb.fn.coalesce(eb.fn.sum<string>('amount'), eb.val('0')).as('s')).where('cafe_id', '=', cafeId).where('order_id', '=', o.id).where('status', 'in', ['created', 'pending']).executeTakeFirstOrThrow();
      const owed = D(o.total_amount).minus(o.paid_amount).minus(pending.s);
      if (owed.lte(0)) throw conflict('ORDER_ALREADY_PAID');
      const minor = await this.minorUnit(tx, o.currency_code);
      const amount = d.amount ? D(d.amount) : owed;
      if (amount.lte(0) || amount.gt(owed)) throw badRequest('AMOUNT_EXCEEDS_BALANCE', money(owed, o.currency_code));
      if (!assertPrecision(amount, minor)) throw badRequest('AMOUNT_PRECISION_INVALID');
      const account = await this.activeAccount(tx);
      if (!account) throw new AppError(503, 'ONLINE_PAYMENT_NOT_CONFIGURED');
      const enabled = await tx.selectFrom('cafe_payment_methods').select('method_code').where('cafe_id', '=', cafeId).where('method_code', '=', d.methodCode).where('is_enabled', '=', 1).executeTakeFirst();
      if (!enabled || d.methodCode === 'cash') throw badRequest('PAYMENT_METHOD_UNAVAILABLE');
      const publicId = ulid();
      const billId = d.billId ? await idOf(tx, 'bills', d.billId, 'BILL_NOT_FOUND') : null;
      const id = Number((await tx.insertInto('payments').values({ public_id: publicId, cafe_id: cafeId, branch_id: o.branch_id, order_id: o.id, bill_id: billId, method_code: d.methodCode, provider_code: account.provider_code, gateway_account_id: account.id, currency_code: o.currency_code, amount: dbMoney(amount), idempotency_key: idempotencyKey }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('payment_transactions').values({ cafe_id: cafeId, payment_id: id, transaction_type: 'initiated', currency_code: o.currency_code, amount: dbMoney(amount) }).execute();
      return { paymentId: id, publicId, amount: amount.toString(), currency: o.currency_code, minor, account, orderNumber: o.order_number } as const;
    });
    if ('duplicate' in prepared) {
      const dup = prepared.duplicate!;
      const account = dup.gateway_account_id ? await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', dup.gateway_account_id).executeTakeFirst() : undefined;
      const provider = account ? this.registry.get(account.provider_code) : undefined;
      const checkout = account && dup.provider_order_ref && dup.status === 'pending' ? provider?.resumeCheckout?.(dup.provider_order_ref, { amount: D(dup.amount).toString(), currency: dup.currency_code, minorUnit: await this.minorUnit(this.db.q, dup.currency_code), reference: dup.public_id, description: `Order`, returnUrl: `${config.publicAppUrl}/payment-return`, methodCode: dup.method_code }, this.creds(account)) : undefined;
      return { paymentId: dup.public_id, status: dup.status, amount: money(dup.amount, dup.currency_code), checkout, deduplicated: true };
    }

    // Network call outside any transaction, so a slow gateway never holds row locks.
    const provider = this.registry.get(prepared.account.provider_code);
    const input: CheckoutInput = { amount: prepared.amount, currency: prepared.currency, minorUnit: prepared.minor, reference: prepared.publicId, description: `Order ${prepared.orderNumber}`, returnUrl: `${config.publicAppUrl}/payment-return`, methodCode: d.methodCode };
    let providerOrderRef: string;
    let extra: Record<string, unknown>;
    try {
      if (d.flow === 'link') {
        if (!provider.createPaymentLink) throw new AppError(400, 'PAYMENT_LINK_UNSUPPORTED');
        const link = await provider.createPaymentLink(input, this.creds(prepared.account));
        providerOrderRef = link.providerOrderRef;
        extra = { shortUrl: link.shortUrl };
      } else {
        const session = await provider.createCheckout(input, this.creds(prepared.account));
        providerOrderRef = session.providerOrderRef;
        extra = { checkout: session.checkout };
      }
    } catch (e) {
      this.logger.error(`createCheckout failed: ${(e as Error).message}`);
      await this.db.tx(async (tx) => {
        await tx.updateTable('payments').set({ status: 'failed', failure_code: 'checkout_error' }).where('cafe_id', '=', tenantId()).where('id', '=', prepared.paymentId).execute();
        await tx.insertInto('payment_transactions').values({ cafe_id: tenantId(), payment_id: prepared.paymentId, transaction_type: 'failed', currency_code: prepared.currency, amount: dbMoney(prepared.amount), provider_status: 'checkout_error' }).execute();
      });
      if (e instanceof AppError) throw e;
      throw new AppError(502, 'GATEWAY_UNAVAILABLE');
    }
    await this.db.q.updateTable('payments').set({ status: 'pending', provider_order_ref: providerOrderRef }).where('cafe_id', '=', tenantId()).where('id', '=', prepared.paymentId).execute();
    return { paymentId: prepared.publicId, status: 'pending', amount: money(prepared.amount, prepared.currency), ...extra };
  }

  async createPaymentLink(orderPublicId: string, amount: string | undefined, idempotencyKey: string) {
    return this.initiate(orderPublicId, { methodCode: 'payment_link', amount, flow: 'link' }, idempotencyKey);
  }

  // Guests only ever touch payments of orders on their own table session.
  private async sessionPayment(publicId: string) {
    const pay = await this.db.q.selectFrom('payments').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!pay) throw notFound('PAYMENT_NOT_FOUND');
    const p = store()?.principal;
    if (p?.type === 'table_session') {
      const owns = pay.order_id ? await this.db.q.selectFrom('orders').select('id').where('cafe_id', '=', tenantId()).where('id', '=', pay.order_id).where('session_id', '=', p.tableSessionId!).executeTakeFirst() : undefined;
      if (!owns) throw notFound('PAYMENT_NOT_FOUND');
    }
    return pay;
  }

  // The browser's success callback. Its signature proves nothing was forged, and the money is then
  // confirmed with the gateway server to server. Nothing the browser says changes a payment by itself.
  async verifyClientCallback(publicId: string, d: { providerPaymentRef: string; signature: string }) {
    const pay = await this.sessionPayment(publicId);
    if (!pay.gateway_account_id || !pay.provider_order_ref) throw conflict('PAYMENT_NOT_ONLINE');
    const account = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', pay.gateway_account_id).executeTakeFirstOrThrow();
    const provider = this.registry.get(account.provider_code);
    if (!provider.verifyClientCallback?.({ providerOrderRef: pay.provider_order_ref, providerPaymentRef: d.providerPaymentRef, signature: d.signature }, this.creds(account))) {
      await audit(this.db.q, { action: 'payment.callback_signature_invalid', entityType: 'payment', entityId: publicId });
      throw new AppError(401, 'PAYMENT_SIGNATURE_INVALID');
    }
    if (['pending', 'expired', 'failed'].includes(pay.status)) await this.reconcile(pay.id);
    const fresh = await this.db.q.selectFrom('payments').select(['status', 'amount', 'currency_code']).where('cafe_id', '=', tenantId()).where('id', '=', pay.id).executeTakeFirstOrThrow();
    return { paymentId: publicId, status: fresh.status, amount: money(fresh.amount, fresh.currency_code) };
  }

  // The customer closed the checkout. `expired` rather than `cancelled`, because a capture can still arrive
  // after this, and the state machine must be able to accept real money. It frees the balance to pay again.
  async abandon(publicId: string) {
    const pay = await this.sessionPayment(publicId);
    if (pay.status === 'pending') await this.expire(pay.id, pay.currency_code, pay.amount, 'checkout_dismissed');
    return { ok: true };
  }

  private async expire(paymentId: number, currency: string, amount: string, code: string) {
    await this.db.tx(async (tx) => {
      const r = await tx.updateTable('payments').set({ status: 'expired', failure_code: code }).where('cafe_id', '=', tenantId()).where('id', '=', paymentId).where('status', '=', 'pending').executeTakeFirst();
      if (r.numUpdatedRows) await tx.insertInto('payment_transactions').values({ cafe_id: tenantId(), payment_id: paymentId, transaction_type: 'expired', currency_code: currency, amount, provider_status: code }).execute();
    });
  }

  // Allocates money to the order, and everything that follows from "fully paid" happens in this transaction.
  private async applySuccess(tx: Tx, paymentId: number) {
    const cafeId = tenantId();
    const pay = await tx.selectFrom('payments').selectAll().where('cafe_id', '=', cafeId).where('id', '=', paymentId).executeTakeFirstOrThrow();
    if (!pay.order_id) return;
    const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('id', '=', pay.order_id).forUpdate().executeTakeFirstOrThrow();
    const paid = D(o.paid_amount).plus(pay.amount);
    const fullyPaid = paid.gte(o.total_amount);
    if (paid.gt(o.total_amount)) {
      // A late capture after someone else paid. The money is real, so it is recorded and flagged for a refund.
      await audit(tx, { action: 'payment.overpaid', entityType: 'order', entityId: o.public_id, after: { total: o.total_amount, paid: dbMoney(paid), payment: pay.public_id }, branchId: o.branch_id });
      await emit(tx, { cafeId, branchId: o.branch_id, type: 'payment.overpaid', rooms: staffRooms(cafeId, o.branch_id), payload: { orderId: o.public_id, paymentId: pay.public_id } });
    }
    await tx.updateTable('orders').set({ paid_amount: dbMoney(paid), payment_status: fullyPaid ? 'paid' : 'partially_paid' }).where('cafe_id', '=', cafeId).where('id', '=', o.id).execute();
    if (pay.bill_id) {
      const bill = await tx.selectFrom('bills').select(['paid_amount', 'total_amount']).where('cafe_id', '=', cafeId).where('id', '=', pay.bill_id).forUpdate().executeTakeFirstOrThrow();
      const billPaid = D(bill.paid_amount).plus(pay.amount);
      await tx.updateTable('bills').set({ paid_amount: dbMoney(billPaid), status: billPaid.gte(bill.total_amount) ? 'paid' : 'partially_paid' }).where('cafe_id', '=', cafeId).where('id', '=', pay.bill_id).execute();
    }
    const date = o.business_date.toISOString().slice(0, 10);
    await this.accounting.post(tx, { sourceType: 'payment', sourceId: pay.id, kind: 'receipt', date, branchId: o.branch_id, memo: `Payment ${pay.public_id}`, lines: [{ key: pay.method_code === 'cash' ? 'cash' : 'gateway_clearing', debit: pay.amount }, { key: 'accounts_receivable', credit: pay.amount }] });
    if (fullyPaid) {
      await this.invoicing.issueForOrder(tx, o.id);
      await this.earnLoyalty(tx, o);
      if (o.status === 'pending_payment') {
        await this.ordering.transition(tx, o.id, 'placed');
        await this.ordering.dispatchToKitchen(tx, o.id, o.public_id, o.branch_id, o.order_number);
      }
      // Settled: the table is free for the next party once nothing else on it is owed.
      await releaseTableIfSettled(tx, cafeId, o.branch_id, o.table_id, o.session_id);
    }
    const session = o.session_id ? await tx.selectFrom('table_sessions').select('public_id').where('cafe_id', '=', cafeId).where('id', '=', o.session_id).executeTakeFirst() : undefined;
    await emit(tx, { cafeId, branchId: o.branch_id, type: 'payment.status_changed', rooms: [...staffRooms(cafeId, o.branch_id), ...(session ? [rooms.session(session.public_id)] : []), ...(o.customer_id ? [rooms.customer(o.customer_id)] : [])], payload: { orderId: o.public_id, paymentId: pay.public_id, status: 'succeeded', paymentStatus: fullyPaid ? 'paid' : 'partially_paid' } });
  }

  private async earnLoyalty(tx: Tx, o: { id: number; customer_id: number | null; total_amount: string }) {
    if (!o.customer_id) return;
    const cafeId = tenantId();
    const program = await tx.selectFrom('loyalty_programs').selectAll().where('cafe_id', '=', cafeId).where('is_active', '=', 1).executeTakeFirst();
    if (!program || D(program.points_per_currency_unit).isZero()) return;
    const points = D(o.total_amount).times(program.points_per_currency_unit).floor().toNumber();
    if (points <= 0) return;
    await tx.insertInto('customer_loyalty_points').values({ cafe_id: cafeId, customer_id: o.customer_id, balance_points: points, lifetime_points: points })
      .onDuplicateKeyUpdate((eb) => ({ balance_points: eb('balance_points', '+', points), lifetime_points: eb('lifetime_points', '+', points) })).execute();
    await tx.insertInto('loyalty_ledger').values({ cafe_id: cafeId, customer_id: o.customer_id, entry_type: 'earn', points, order_id: o.id, expires_at: program.points_expiry_days ? new Date(Date.now() + program.points_expiry_days * 86400_000) : null }).execute();
  }

  // Staff-authorized cash. This, and verified gateway events, are the only ways money is recorded as received.
  async confirmCash(d: { orderId: string; amount?: string; registerSessionId?: string; billId?: string }, idempotencyKey: string) {
    if (!idempotencyKey) throw badRequest('IDEMPOTENCY_KEY_REQUIRED');
    return this.db.tx(async (tx) => {
      const cafeId = tenantId();
      const dup = await tx.selectFrom('payments').select(['public_id', 'status']).where('cafe_id', '=', cafeId).where('idempotency_key', '=', idempotencyKey).executeTakeFirst();
      if (dup) return { paymentId: dup.public_id, status: dup.status, deduplicated: true };
      const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('public_id', '=', d.orderId).forUpdate().executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      assertBranchAllowed(o.branch_id);
      if (o.status === 'cancelled') throw conflict('ORDER_CANCELLED');
      const owed = D(o.total_amount).minus(o.paid_amount);
      if (owed.lte(0)) throw conflict('ORDER_ALREADY_PAID');
      const amount = d.amount ? D(d.amount) : owed;
      if (amount.lte(0) || amount.gt(owed)) throw badRequest('AMOUNT_EXCEEDS_BALANCE', money(owed, o.currency_code));
      if (!assertPrecision(amount, await this.minorUnit(tx, o.currency_code))) throw badRequest('AMOUNT_PRECISION_INVALID');
      const publicId = ulid();
      const now = new Date();
      const billId = d.billId ? await idOf(tx, 'bills', d.billId, 'BILL_NOT_FOUND') : null;
      const id = Number((await tx.insertInto('payments').values({ public_id: publicId, cafe_id: cafeId, branch_id: o.branch_id, order_id: o.id, bill_id: billId, method_code: 'cash', currency_code: o.currency_code, amount: dbMoney(amount), status: 'succeeded', verification_source: 'manual_cash', verified_at: now, confirmed_by_user_id: requiredUserId(), idempotency_key: idempotencyKey }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('payment_transactions').values({ cafe_id: cafeId, payment_id: id, transaction_type: 'cash_confirmed', currency_code: o.currency_code, amount: dbMoney(amount), actor_user_id: requiredUserId() }).execute();
      if (d.registerSessionId) {
        const session = await idOf(tx, 'cash_register_sessions', d.registerSessionId, 'REGISTER_SESSION_NOT_FOUND');
        await tx.insertInto('cash_register_transactions').values({ cafe_id: cafeId, session_id: session, transaction_type: 'sale', currency_code: o.currency_code, amount: dbMoney(amount), payment_id: id, recorded_by_user_id: requiredUserId() }).execute();
      }
      await this.applySuccess(tx, id);
      await audit(tx, { action: 'payment.cash_confirmed', entityType: 'payment', entityId: publicId, branchId: o.branch_id, after: { amount: amount.toString() } });
      return { paymentId: publicId, status: 'succeeded', amount: money(amount, o.currency_code) };
    });
  }

  // Unauthenticated by design: the signature against this account's secret is the only authority.
  async webhook(providerCode: string, accountPublicId: string, raw: Buffer, headers: Record<string, string | string[] | undefined>) {
    const provider = this.registry.get(providerCode);
    const account = await unscoped('webhook precedes tenant resolution', () => this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('public_id', '=', accountPublicId).where('provider_code', '=', providerCode).executeTakeFirst());
    if (!account) throw notFound();
    let event: VerifiedEvent;
    const currencies = await unscoped('reference data', () => this.db.q.selectFrom('currencies').select(['code', 'minor_unit']).execute());
    try {
      event = provider.verifyWebhook(raw, headers, this.creds(account), (c) => currencies.find((x) => x.code === c)?.minor_unit ?? 2);
    } catch (e) {
      if (e instanceof WebhookSignatureError) throw new AppError(401, 'WEBHOOK_SIGNATURE_INVALID');
      throw e;
    }
    return asTenant(account.cafe_id, async () => {
      const inserted = await this.db.q.insertInto('payment_webhooks').ignore().values({ cafe_id: account.cafe_id, provider_code: providerCode, provider_event_id: event.eventId, event_type: event.type, signature_verified: 1, sanitized_payload: JSON.stringify(event.raw) }).executeTakeFirst();
      if (!Number(inserted.numInsertedOrUpdatedRows)) {
        const prior = await this.db.q.selectFrom('payment_webhooks').select('status').where('provider_code', '=', providerCode).where('provider_event_id', '=', event.eventId).executeTakeFirstOrThrow();
        // A redelivery of an event that failed mid-processing is a retry, not a duplicate: dropping it could lose real money.
        if (prior.status !== 'failed') return { received: true, duplicate: true };
      }
      const mark = (status: 'processed' | 'ignored' | 'failed', error: string | null) => this.db.q.updateTable('payment_webhooks').set((eb) => ({ status, processed_at: status === 'failed' ? null : new Date(), attempts: eb('attempts', '+', 1), error_message: error?.slice(0, 500) ?? null })).where('provider_code', '=', providerCode).where('provider_event_id', '=', event.eventId).execute();
      try {
        await this.processEvent(event, account.id);
        await mark(event.kind === 'ignored' ? 'ignored' : 'processed', null);
      } catch (e) {
        this.logger.error(`Webhook ${event.eventId} failed: ${(e as Error).message}`);
        await mark('failed', (e as Error).message);
        // A temporary fault must not be acknowledged, or the gateway would never send this event again.
        if (!(e instanceof PermanentEventError)) throw new AppError(503, 'WEBHOOK_RETRY_LATER');
      }
      return { received: true };
    });
  }

  private async findEventPayment(q: Db['q'] | Tx, event: VerifiedEvent, accountId: number, lock: boolean) {
    const cafeId = tenantId();
    const base = () => q.selectFrom('payments').selectAll().where('cafe_id', '=', cafeId).where('gateway_account_id', '=', accountId);
    if (event.providerOrderRef) {
      const byOrder = lock ? await base().where('provider_order_ref', '=', event.providerOrderRef).forUpdate().executeTakeFirst() : await base().where('provider_order_ref', '=', event.providerOrderRef).executeTakeFirst();
      if (byOrder) return byOrder;
    }
    if (!event.reference) return undefined;
    return lock ? base().where('public_id', '=', event.reference).forUpdate().executeTakeFirst() : base().where('public_id', '=', event.reference).executeTakeFirst();
  }

  private async processEvent(event: VerifiedEvent, accountId: number) {
    if (event.kind === 'ignored') return;
    // Events can arrive in any order. An authorization needs a network call, so it runs outside the transaction.
    if (event.kind === 'authorized') {
      const pay = await this.findEventPayment(this.db.q, event, accountId, false);
      if (pay && !['succeeded', 'partially_refunded', 'refunded'].includes(pay.status)) await this.reconcile(pay.id);
      return;
    }
    await this.db.tx(async (tx) => {
      const cafeId = tenantId();
      if (event.kind === 'captured' || event.kind === 'failed') {
        const pay = await this.findEventPayment(tx, event, accountId, true);
        if (!pay) {
          // For example a sale made outside this platform on the same gateway account. Nothing here to credit.
          await audit(tx, { action: 'payment.unmatched_event', entityType: 'webhook', entityId: event.eventId, after: event.raw });
          return;
        }
        if (event.kind === 'failed') {
          // Checkout lets the customer retry the same order, so a failed attempt leaves it open. It is only recorded.
          await tx.insertInto('payment_transactions').values({ cafe_id: cafeId, payment_id: pay.id, transaction_type: 'failed', currency_code: pay.currency_code, amount: pay.amount, provider_ref: event.providerPaymentRef ?? null, provider_status: event.type.slice(0, 64), sanitized_payload: JSON.stringify(event.raw) }).execute();
          return;
        }
        await this.recordCapture(tx, pay, event, 'gateway_webhook');
        return;
      }
      await this.settleRefundFromEvent(tx, event);
    });
  }

  private async recordCapture(tx: Tx, pay: { id: number; status: string; amount: string; currency_code: string; public_id: string; branch_id: number }, event: { providerPaymentRef?: string; amount?: string; currency?: string; feeAmount?: string; instrumentSummary?: string; raw?: Record<string, unknown>; type?: string }, source: 'gateway_webhook' | 'gateway_api') {
    const cafeId = tenantId();
    if (['succeeded', 'partially_refunded', 'refunded'].includes(pay.status)) return;
    // A signed event for the wrong sum is a discrepancy to investigate, not money to credit.
    if (!event.amount || !D(event.amount).eq(pay.amount) || event.currency !== pay.currency_code) {
      await this.db.q.transaction().execute(async (own) => audit(own, { action: 'payment.amount_mismatch', entityType: 'payment', entityId: pay.public_id, after: { expected: pay.amount, got: event.amount, currency: event.currency } }));
      throw new PermanentEventError(`Amount mismatch on payment ${pay.public_id}`);
    }
    await tx.updateTable('payments').set({ status: 'succeeded', verification_source: source, verified_at: new Date(), provider_payment_ref: event.providerPaymentRef, gateway_fee_amount: event.feeAmount ? dbMoney(event.feeAmount) : null, instrument_summary: event.instrumentSummary?.slice(0, 60) ?? null }).where('cafe_id', '=', cafeId).where('id', '=', pay.id).execute();
    await tx.insertInto('payment_transactions').values({ cafe_id: cafeId, payment_id: pay.id, transaction_type: 'captured', currency_code: pay.currency_code, amount: pay.amount, provider_ref: event.providerPaymentRef ?? null, provider_status: event.type?.slice(0, 64) ?? 'captured', sanitized_payload: event.raw ? JSON.stringify(event.raw) : null }).execute();
    await this.applySuccess(tx, pay.id);
  }

  // Client "success" callbacks land here. They trigger this server-side check; they change nothing on their own.
  async refreshFromProvider(paymentPublicId: string) {
    const pay = await this.sessionPayment(paymentPublicId);
    if (pay.status === 'pending' && pay.gateway_account_id && pay.provider_order_ref) await this.reconcile(pay.id);
    const fresh = await this.db.q.selectFrom('payments').select(['public_id', 'status', 'amount', 'currency_code']).where('cafe_id', '=', tenantId()).where('id', '=', pay.id).executeTakeFirstOrThrow();
    return { paymentId: fresh.public_id, status: fresh.status, amount: money(fresh.amount, fresh.currency_code) };
  }

  async reconcile(paymentId: number) {
    const pay = await this.db.q.selectFrom('payments').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', paymentId).executeTakeFirstOrThrow();
    const account = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', pay.gateway_account_id!).executeTakeFirstOrThrow();
    const result = await this.registry.get(account.provider_code).fetchPayment(pay.provider_order_ref!, await this.minorUnit(this.db.q, pay.currency_code), this.creds(account));
    if (result.status === 'pending') return;
    await this.db.tx(async (tx) => {
      const locked = await tx.selectFrom('payments').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', paymentId).forUpdate().executeTakeFirstOrThrow();
      if (result.status === 'captured') await this.recordCapture(tx, locked, { ...result, type: 'reconciled' }, 'gateway_api');
      else if (['created', 'pending'].includes(locked.status)) {
        await tx.updateTable('payments').set({ status: 'failed', failure_code: 'reconciled_failed' }).where('cafe_id', '=', tenantId()).where('id', '=', paymentId).execute();
        await tx.insertInto('payment_transactions').values({ cafe_id: tenantId(), payment_id: paymentId, transaction_type: 'failed', currency_code: locked.currency_code, amount: locked.amount, provider_status: 'reconciled_failed' }).execute();
      }
    });
  }

  async list(query: { status?: string; orderId?: string }) {
    let q = this.db.q.selectFrom('payments as p').leftJoin('orders as o', 'o.id', 'p.order_id').select(['p.public_id', 'p.method_code', 'p.provider_code', 'p.currency_code', 'p.amount', 'p.refunded_amount', 'p.gateway_fee_amount', 'p.status', 'p.verification_source', 'p.verified_at', 'p.created_at', 'o.public_id as order_id', 'o.order_number']).where('p.cafe_id', '=', tenantId());
    const allowed = store()?.principal?.branchIds;
    if (store()?.branchId) q = q.where('p.branch_id', '=', store()!.branchId!);
    else if (allowed) q = q.where('p.branch_id', 'in', allowed);
    if (query.status) q = q.where('p.status', '=', query.status as 'pending');
    if (query.orderId) q = q.where('o.public_id', '=', query.orderId);
    return q.orderBy('p.id', 'desc').limit(200).execute();
  }

  // Refunds: request (cashier) and approve (manager or owner), so one person cannot move money alone.
  async requestRefund(paymentPublicId: string, d: { amount: string; reason: string }, idempotencyKey: string) {
    if (!idempotencyKey) throw badRequest('IDEMPOTENCY_KEY_REQUIRED');
    return this.db.tx(async (tx) => {
      const dup = await tx.selectFrom('refunds').select(['public_id', 'status']).where('cafe_id', '=', tenantId()).where('idempotency_key', '=', idempotencyKey).executeTakeFirst();
      if (dup) return { refundId: dup.public_id, status: dup.status, deduplicated: true };
      const pay = await tx.selectFrom('payments').select(['id', 'currency_code', 'branch_id']).where('cafe_id', '=', tenantId()).where('public_id', '=', paymentPublicId).executeTakeFirst();
      if (!pay) throw notFound('PAYMENT_NOT_FOUND');
      assertBranchAllowed(pay.branch_id);
      if (!assertPrecision(d.amount, await this.minorUnit(tx, pay.currency_code))) throw badRequest('AMOUNT_PRECISION_INVALID');
      const publicId = ulid();
      await tx.insertInto('refunds').values({ public_id: publicId, cafe_id: tenantId(), payment_id: pay.id, currency_code: pay.currency_code, amount: dbMoney(d.amount), reason: d.reason, requested_by_user_id: requiredUserId(), idempotency_key: idempotencyKey }).execute();
      await audit(tx, { action: 'refund.requested', entityType: 'refund', entityId: publicId, reason: d.reason, after: { amount: d.amount } });
      return { refundId: publicId, status: 'requested' };
    });
  }

  async approveRefund(refundPublicId: string) {
    const prepared = await this.db.tx(async (tx) => {
      const r = await tx.selectFrom('refunds').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', refundPublicId).forUpdate().executeTakeFirst();
      if (!r) throw notFound('REFUND_NOT_FOUND');
      if (r.status !== 'requested') throw conflict('REFUND_NOT_PENDING');
      const pay = await tx.selectFrom('payments').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', r.payment_id).executeTakeFirstOrThrow();
      assertBranchAllowed(pay.branch_id);
      await tx.updateTable('refunds').set({ status: 'processing', approved_by_user_id: requiredUserId() }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
      await audit(tx, { action: 'refund.approved', entityType: 'refund', entityId: refundPublicId });
      return { r, pay };
    });
    const { r, pay } = prepared;
    if (pay.method_code === 'cash') {
      await this.db.tx((tx) => this.completeRefund(tx, r.id));
      return { refundId: refundPublicId, status: 'succeeded' };
    }
    const account = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('id', '=', pay.gateway_account_id!).executeTakeFirstOrThrow();
    try {
      const result = await this.registry.get(account.provider_code).refund({ providerPaymentRef: pay.provider_payment_ref!, amount: D(r.amount).toString(), currency: r.currency_code, minorUnit: await this.minorUnit(this.db.q, r.currency_code), idempotencyKey: r.idempotency_key, reference: r.public_id }, this.creds(account));
      await this.db.q.updateTable('refunds').set({ provider_refund_ref: result.providerRefundRef }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
      if (result.status === 'succeeded') await this.db.tx((tx) => this.completeRefund(tx, r.id));
      if (result.status === 'failed') await this.db.q.updateTable('refunds').set({ status: 'failed' }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
      return { refundId: refundPublicId, status: result.status };
    } catch (e) {
      this.logger.error(`Refund ${refundPublicId} failed: ${(e as Error).message}`);
      await this.db.q.updateTable('refunds').set({ status: 'failed' }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
      throw new AppError(502, 'GATEWAY_UNAVAILABLE');
    }
  }

  private async completeRefund(tx: Tx, refundId: number) {
    const cafeId = tenantId();
    const r = await tx.selectFrom('refunds').selectAll().where('cafe_id', '=', cafeId).where('id', '=', refundId).forUpdate().executeTakeFirstOrThrow();
    if (r.status === 'succeeded') return;
    const pay = await tx.selectFrom('payments').selectAll().where('cafe_id', '=', cafeId).where('id', '=', r.payment_id).forUpdate().executeTakeFirstOrThrow();
    const refunded = D(pay.refunded_amount).plus(r.amount);
    const status = refunded.eq(pay.amount) ? 'refunded' : 'partially_refunded';
    await tx.updateTable('refunds').set({ status: 'succeeded', processed_at: new Date() }).where('cafe_id', '=', cafeId).where('id', '=', r.id).execute();
    await tx.updateTable('payments').set({ refunded_amount: dbMoney(refunded), status }).where('cafe_id', '=', cafeId).where('id', '=', pay.id).execute();
    await tx.insertInto('payment_transactions').values({ cafe_id: cafeId, payment_id: pay.id, transaction_type: 'refund', currency_code: pay.currency_code, amount: r.amount, provider_ref: r.provider_refund_ref, actor_user_id: actorUserId() }).execute();
    if (!pay.order_id) return;
    const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', cafeId).where('id', '=', pay.order_id).forUpdate().executeTakeFirstOrThrow();
    const orderRefunded = D(o.refunded_amount).plus(r.amount);
    await tx.updateTable('orders').set({ refunded_amount: dbMoney(orderRefunded), payment_status: orderRefunded.gte(o.paid_amount) ? 'refunded' : 'partially_refunded' }).where('cafe_id', '=', cafeId).where('id', '=', o.id).execute();
    const minor = await this.minorUnit(tx, o.currency_code);
    const { tax, net, today } = await this.invoicing.issueCreditNote(tx, o.id, r.amount, r.id, r.reason, minor);
    await this.accounting.post(tx, {
      sourceType: 'refund', sourceId: r.id, kind: 'refund', date: today, branchId: o.branch_id, memo: `Refund ${r.public_id}`,
      lines: [{ key: 'sales_returns', debit: dbMoney(net) }, { key: 'tax_payable', debit: dbMoney(tax) }, { key: pay.method_code === 'cash' ? 'cash' : 'gateway_clearing', credit: r.amount }],
    });
    await emit(tx, { cafeId, branchId: o.branch_id, type: 'payment.status_changed', rooms: staffRooms(cafeId, o.branch_id), payload: { orderId: o.public_id, paymentId: pay.public_id, status } });
  }

  private async settleRefundFromEvent(tx: Tx, event: VerifiedEvent) {
    const base = () => tx.selectFrom('refunds as r').innerJoin('payments as p', 'p.id', 'r.payment_id').select(['r.id', 'r.status', 'r.provider_refund_ref']).where('r.cafe_id', '=', tenantId());
    // By refund reference. The event can beat our own save of that reference, so it can then match on the
    // payment, but only when exactly one refund on it is in flight: guessing between two could settle the wrong one.
    let r = event.providerRefundRef ? await base().where('r.provider_refund_ref', '=', event.providerRefundRef).executeTakeFirst() : undefined;
    if (!r && event.providerPaymentRef) {
      const open = await base().where('p.provider_payment_ref', '=', event.providerPaymentRef).where('r.status', '=', 'processing').execute();
      if (open.length === 1) r = open[0];
    }
    if (!r || ['succeeded', 'failed'].includes(r.status)) return;
    if (event.providerRefundRef && !r.provider_refund_ref) await tx.updateTable('refunds').set({ provider_refund_ref: event.providerRefundRef }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
    if (event.kind === 'refund_succeeded') await this.completeRefund(tx, r.id);
    else await tx.updateTable('refunds').set({ status: 'failed' }).where('cafe_id', '=', tenantId()).where('id', '=', r.id).execute();
  }

  async listRefunds() {
    return this.db.q.selectFrom('refunds as r').innerJoin('payments as p', 'p.id', 'r.payment_id').select(['r.public_id', 'r.currency_code', 'r.amount', 'r.status', 'r.reason', 'r.created_at', 'r.processed_at', 'p.public_id as payment_id', 'p.method_code']).where('r.cafe_id', '=', tenantId()).orderBy('r.id', 'desc').limit(200).execute();
  }

  // Split a bill: parts always sum to exactly what is still owed.
  async splitBill(d: { orderId: string; equalParts?: number; amounts?: string[] }) {
    return this.db.tx(async (tx) => {
      const o = await tx.selectFrom('orders').selectAll().where('cafe_id', '=', tenantId()).where('public_id', '=', d.orderId).forUpdate().executeTakeFirst();
      if (!o) throw notFound('ORDER_NOT_FOUND');
      assertBranchAllowed(o.branch_id);
      const owed = D(o.total_amount).minus(o.paid_amount);
      if (owed.lte(0)) throw conflict('ORDER_ALREADY_PAID');
      const minor = await this.minorUnit(tx, o.currency_code);
      let parts: ReturnType<typeof D>[];
      if (d.equalParts) parts = allocate(owed, Array.from({ length: d.equalParts }, () => D(1)), minor);
      else if (d.amounts?.length) {
        parts = d.amounts.map((a) => roundTo(a, minor));
        if (!parts.reduce((x, y) => x.plus(y), ZERO).eq(owed)) throw badRequest('SPLIT_DOES_NOT_MATCH_BALANCE', money(owed, o.currency_code));
      } else throw badRequest('SPLIT_REQUIRED');
      await tx.updateTable('bills').set({ status: 'void' }).where('cafe_id', '=', tenantId()).where('status', '=', 'open').where('id', 'in', tx.selectFrom('bill_lines').select('bill_id').where('cafe_id', '=', tenantId()).where('order_id', '=', o.id)).execute();
      const bills = [];
      for (const part of parts) {
        const publicId = ulid();
        const id = Number((await tx.insertInto('bills').values({ public_id: publicId, cafe_id: tenantId(), branch_id: o.branch_id, session_id: o.session_id, currency_code: o.currency_code, total_amount: dbMoney(part), created_by_user_id: actorUserId() }).executeTakeFirstOrThrow()).insertId);
        await tx.insertInto('bill_lines').values({ cafe_id: tenantId(), bill_id: id, order_id: o.id, amount: dbMoney(part) }).execute();
        bills.push({ publicId, amount: money(part, o.currency_code) });
      }
      await audit(tx, { action: 'bill.split', entityType: 'order', entityId: d.orderId, after: { parts: parts.length } });
      return { bills };
    });
  }

  async listSettlements() {
    return this.db.q.selectFrom('settlements').select(['public_id', 'provider_settlement_ref', 'currency_code', 'gross_amount', 'fee_amount', 'tax_amount', 'net_amount', 'status', 'settled_at']).where('cafe_id', '=', tenantId()).orderBy('settled_at', 'desc').limit(200).execute();
  }

  async syncSettlements(fromIso: string, toIso: string) {
    const accounts = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', tenantId()).where('status', '=', 'active').execute();
    const currencies = await this.db.q.selectFrom('currencies').select(['code', 'minor_unit']).execute();
    const unit = (c: string) => currencies.find((x) => x.code === c)?.minor_unit ?? 2;
    let imported = 0;
    let mismatched = 0;
    for (const a of accounts) {
      const provider = this.registry.get(a.provider_code);
      const creds = this.creds(a);
      for (const s of await provider.fetchSettlements(new Date(fromIso), new Date(toIso), creds, unit)) {
        const known = await this.db.q.selectFrom('settlements').select('id').where('cafe_id', '=', tenantId()).where('gateway_account_id', '=', a.id).where('provider_settlement_ref', '=', s.ref).executeTakeFirst();
        if (known) continue;
        const items = await provider.fetchSettlementItems?.({ ref: s.ref, settledAt: s.settledAt }, creds, unit) ?? [];
        const status = await this.db.tx((tx) => this.importSettlement(tx, a.id, s, items));
        imported += 1;
        if (status === 'mismatch') mismatched += 1;
      }
    }
    return { imported, mismatched };
  }

  // Fees are derived as settled sales minus what reached the bank, so the books always match the bank.
  // Any line we cannot tie to our own payments marks the settlement for a person to look at.
  private async importSettlement(tx: Tx, accountId: number, s: { ref: string; currency: string; fee: string; tax: string; net: string; settledAt: Date }, items: Array<{ type: 'payment' | 'refund' | 'other'; providerRef: string; amount: string; fee: string }>) {
    const cafeId = tenantId();
    const gross = items.reduce((sum, i) => (i.type === 'payment' ? sum.plus(i.amount) : i.type === 'refund' ? sum.minus(i.amount) : sum), ZERO);
    const derivedFee = items.length ? gross.minus(s.net) : D(s.fee);
    const fee = derivedFee.lt(0) ? ZERO : derivedFee;
    let matched = items.length > 0 && !derivedFee.lt(0);
    const publicId = ulid();
    const id = Number((await tx.insertInto('settlements').values({ public_id: publicId, cafe_id: cafeId, gateway_account_id: accountId, provider_settlement_ref: s.ref, currency_code: s.currency, gross_amount: dbMoney(D(s.net).plus(fee)), fee_amount: dbMoney(fee), tax_amount: dbMoney(s.tax), net_amount: dbMoney(s.net), settled_at: s.settledAt }).executeTakeFirstOrThrow()).insertId);
    for (const i of items) {
      if (i.type === 'other') { matched = false; continue; }
      if (i.type === 'payment') {
        const p = await tx.selectFrom('payments').select(['id', 'gateway_fee_amount']).where('cafe_id', '=', cafeId).where('gateway_account_id', '=', accountId).where('provider_payment_ref', '=', i.providerRef).executeTakeFirst();
        if (!p) { matched = false; continue; }
        await tx.insertInto('settlement_items').values({ cafe_id: cafeId, settlement_id: id, payment_id: p.id, amount: dbMoney(i.amount), fee_amount: dbMoney(i.fee) }).execute();
        if (p.gateway_fee_amount === null) await tx.updateTable('payments').set({ gateway_fee_amount: dbMoney(i.fee) }).where('cafe_id', '=', cafeId).where('id', '=', p.id).execute();
      } else {
        const r = await tx.selectFrom('refunds').select('id').where('cafe_id', '=', cafeId).where('provider_refund_ref', '=', i.providerRef).executeTakeFirst();
        if (!r) { matched = false; continue; }
        await tx.insertInto('settlement_items').values({ cafe_id: cafeId, settlement_id: id, refund_id: r.id, amount: dbMoney(i.amount), fee_amount: dbMoney(i.fee) }).execute();
      }
    }
    const status = items.length === 0 ? 'reported' as const : matched ? 'reconciled' as const : 'mismatch' as const;
    await tx.updateTable('settlements').set({ status }).where('cafe_id', '=', cafeId).where('id', '=', id).execute();
    await this.accounting.post(tx, { sourceType: 'settlement', sourceId: id, kind: 'payout', date: s.settledAt.toISOString().slice(0, 10), memo: `Settlement ${s.ref}`, lines: [{ key: 'bank', debit: dbMoney(s.net) }, { key: 'gateway_fees', debit: dbMoney(fee) }, { key: 'gateway_clearing', credit: dbMoney(D(s.net).plus(fee)) }] });
    await audit(tx, { action: 'settlement.imported', entityType: 'settlement', entityId: publicId, after: { ref: s.ref, status } });
    return status;
  }

  // Catches what a missed webhook would leave behind. Abandoned checkouts expire, which frees the balance to pay again.
  async reconcileStale(olderThanMinutes = 5, expireAfterMinutes = 30) {
    const stale = await unscoped('worker sweep across cafes', () => this.db.q.selectFrom('payments').select(['id', 'cafe_id', 'created_at', 'currency_code', 'amount']).where('status', '=', 'pending').where('created_at', '<', new Date(Date.now() - olderThanMinutes * 60000)).limit(50).execute());
    for (const p of stale) {
      await asTenant(p.cafe_id, async () => {
        await this.reconcile(p.id);
        if (p.created_at.getTime() < Date.now() - expireAfterMinutes * 60000) await this.expire(p.id, p.currency_code, p.amount, 'checkout_timeout');
      }).catch((e) => this.logger.warn(`Reconcile ${p.id}: ${e.message}`));
    }
    const refunds = await unscoped('worker sweep across cafes', () => this.db.q.selectFrom('refunds as r').innerJoin('payments as p', 'p.id', 'r.payment_id').select(['r.id', 'r.cafe_id', 'r.provider_refund_ref', 'p.gateway_account_id']).where('r.status', '=', 'processing').where('r.provider_refund_ref', 'is not', null).where('r.updated_at', '<', new Date(Date.now() - olderThanMinutes * 60000)).limit(50).execute());
    for (const r of refunds) {
      await asTenant(r.cafe_id, async () => {
        const account = await this.db.q.selectFrom('payment_gateway_accounts').selectAll().where('cafe_id', '=', r.cafe_id).where('id', '=', r.gateway_account_id!).executeTakeFirstOrThrow();
        const result = await this.registry.get(account.provider_code).fetchRefund?.(r.provider_refund_ref!, this.creds(account));
        if (result?.status === 'succeeded') await this.db.tx((tx) => this.completeRefund(tx, r.id));
        if (result?.status === 'failed') await this.db.q.updateTable('refunds').set({ status: 'failed' }).where('cafe_id', '=', r.cafe_id).where('id', '=', r.id).execute();
      }).catch((e) => this.logger.warn(`Refund sweep ${r.id}: ${e.message}`));
    }
  }

  async syncAllSettlements() {
    const cafes = await unscoped('worker sweep across cafes', () => this.db.q.selectFrom('payment_gateway_accounts').select('cafe_id').where('status', '=', 'active').distinct().execute());
    const to = new Date();
    const from = new Date(to.getTime() - 7 * 86400_000);
    for (const c of cafes) await asTenant(c.cafe_id, () => this.syncSettlements(from.toISOString(), to.toISOString())).catch((e) => this.logger.warn(`Settlement sync ${c.cafe_id}: ${e.message}`));
  }
}
