import { Injectable } from '@nestjs/common';
import { store, tenantId } from '../../common/context';
import { badRequest, conflict, forbidden, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { idOf } from '../../common/lookup';
import { dbMoney } from '../../common/money';
import { actorUserId } from '../../common/context';
import { audit, Db } from '../../infra/db/db.service';

@Injectable()
export class MarketingService {
  constructor(private readonly db: Db) {}

  coupons() { return this.db.q.selectFrom('coupons').select(['public_id', 'code', 'discount_type', 'percent_value', 'fixed_amount', 'max_discount_amount', 'min_order_amount', 'max_redemptions', 'max_per_customer', 'redemption_count', 'starts_at', 'ends_at', 'is_active']).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).orderBy('id', 'desc').execute(); }
  async createCoupon(d: { code: string; discountType: 'percent' | 'fixed'; percentValue?: string; fixedAmount?: string; maxDiscountAmount?: string; minOrderAmount?: string; maxRedemptions?: number; maxPerCustomer?: number; startsAt?: string; endsAt?: string }) {
    if ((d.discountType === 'percent') !== !!d.percentValue || (d.discountType === 'fixed') !== !!d.fixedAmount) throw badRequest('COUPON_VALUE_INVALID');
    const publicId = ulid();
    await this.db.tx(async (tx) => {
      await tx.insertInto('coupons').values({ public_id: publicId, cafe_id: tenantId(), code: d.code.toUpperCase(), discount_type: d.discountType, percent_value: d.percentValue ?? null, fixed_amount: d.fixedAmount ? dbMoney(d.fixedAmount) : null, max_discount_amount: d.maxDiscountAmount ? dbMoney(d.maxDiscountAmount) : null, min_order_amount: dbMoney(d.minOrderAmount ?? 0), max_redemptions: d.maxRedemptions ?? null, max_per_customer: d.maxPerCustomer ?? null, starts_at: d.startsAt ? new Date(d.startsAt) : null, ends_at: d.endsAt ? new Date(d.endsAt) : null }).execute();
      await audit(tx, { action: 'coupon.created', entityType: 'coupon', entityId: publicId });
    });
    return { publicId };
  }
  async updateCoupon(publicId: string, isActive: boolean) {
    const r = await this.db.q.updateTable('coupons').set({ is_active: isActive ? 1 : 0 }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
  async deleteCoupon(publicId: string) {
    const r = await this.db.q.updateTable('coupons').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  async promotions(lang?: string) {
    const rows = await this.db.q.selectFrom('promotions').selectAll().where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).orderBy('priority', 'desc').execute();
    const tr = rows.length ? await this.db.q.selectFrom('promotion_translations').selectAll().where('cafe_id', '=', tenantId()).where('promotion_id', 'in', rows.map((r) => r.id)).execute() : [];
    return rows.map((r) => {
      const mine = tr.filter((t) => t.promotion_id === r.id);
      const t = mine.find((x) => x.language_code === lang) ?? mine[0];
      return { publicId: r.public_id, discountType: r.discount_type, percentValue: r.percent_value, fixedAmount: r.fixed_amount, startsAt: r.starts_at, endsAt: r.ends_at, isActive: !!r.is_active, title: t?.title, description: t?.description };
    });
  }
  async createPromotion(d: { discountType: 'percent' | 'fixed'; percentValue?: string; fixedAmount?: string; startsAt?: string; endsAt?: string; priority?: number; translations: Array<{ language: string; title: string; description?: string }>; productIds?: string[]; categoryIds?: string[] }) {
    return this.db.tx(async (tx) => {
      const publicId = ulid();
      const id = Number((await tx.insertInto('promotions').values({ public_id: publicId, cafe_id: tenantId(), discount_type: d.discountType, percent_value: d.percentValue ?? null, fixed_amount: d.fixedAmount ? dbMoney(d.fixedAmount) : null, starts_at: d.startsAt ? new Date(d.startsAt) : null, ends_at: d.endsAt ? new Date(d.endsAt) : null, priority: d.priority ?? 0 }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('promotion_translations').values(d.translations.map((t) => ({ cafe_id: tenantId(), promotion_id: id, language_code: t.language, title: t.title, description: t.description ?? null }))).execute();
      for (const p of d.productIds ?? []) await tx.insertInto('promotion_targets').values({ cafe_id: tenantId(), promotion_id: id, product_id: await idOf(tx, 'products', p, 'PRODUCT_NOT_FOUND') }).execute();
      for (const c of d.categoryIds ?? []) await tx.insertInto('promotion_targets').values({ cafe_id: tenantId(), promotion_id: id, category_id: await idOf(tx, 'categories', c, 'CATEGORY_NOT_FOUND') }).execute();
      await audit(tx, { action: 'promotion.created', entityType: 'promotion', entityId: publicId });
      return { publicId };
    });
  }
  async deletePromotion(publicId: string) {
    const r = await this.db.q.updateTable('promotions').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  loyaltyProgram() { return this.db.q.selectFrom('loyalty_programs').selectAll().where('cafe_id', '=', tenantId()).executeTakeFirst().then((r) => r ?? null); }
  async saveLoyalty(d: { isActive: boolean; pointsPerCurrencyUnit: string; currencyValuePerPoint: string; minRedeemPoints?: number; pointsExpiryDays?: number }) {
    const values = { is_active: d.isActive ? 1 : 0, points_per_currency_unit: d.pointsPerCurrencyUnit, currency_value_per_point: dbMoney(d.currencyValuePerPoint), min_redeem_points: d.minRedeemPoints ?? 0, points_expiry_days: d.pointsExpiryDays ?? null };
    await this.db.tx(async (tx) => {
      await tx.insertInto('loyalty_programs').values({ cafe_id: tenantId(), ...values }).onDuplicateKeyUpdate(values).execute();
      await audit(tx, { action: 'loyalty.program_saved', after: d });
    });
    return { ok: true };
  }

  // A review needs a real order that belongs to this guest's session, and only one per order.
  async review(orderPublicId: string, d: { rating: number; comment?: string }) {
    const p = store()!.principal!;
    const o = await this.db.q.selectFrom('orders').select(['id', 'customer_id', 'status']).where('cafe_id', '=', tenantId()).where('public_id', '=', orderPublicId).where('session_id', '=', p.tableSessionId!).executeTakeFirst();
    if (!o) throw notFound('ORDER_NOT_FOUND');
    if (!['served', 'completed', 'ready'].includes(o.status)) throw conflict('ORDER_NOT_REVIEWABLE');
    const publicId = ulid();
    await this.db.q.insertInto('customer_reviews').values({ public_id: publicId, cafe_id: tenantId(), order_id: o.id, customer_id: o.customer_id, rating: d.rating, comment: d.comment ?? null }).execute();
    return { publicId };
  }
  reviews() { return this.db.q.selectFrom('customer_reviews as r').innerJoin('orders as o', 'o.id', 'r.order_id').select(['r.public_id', 'r.rating', 'r.comment', 'r.is_published', 'r.reply_text', 'r.created_at', 'o.order_number']).where('r.cafe_id', '=', tenantId()).orderBy('r.id', 'desc').limit(200).execute(); }
  async reply(publicId: string, text: string) {
    if (!actorUserId()) throw forbidden();
    const r = await this.db.q.updateTable('customer_reviews').set({ reply_text: text, replied_by_user_id: actorUserId(), replied_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
}
