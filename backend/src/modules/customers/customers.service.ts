import { Injectable } from '@nestjs/common';
import { asTenant, currentLang, principal, tenantId, unscoped } from '../../common/context';
import { notFound } from '../../common/errors';
import { paged, requirePage } from '../../common/http';
import { ulid } from '../../common/ids';
import { idOf } from '../../common/lookup';
import { Db } from '../../infra/db/db.service';
import { AuthService } from '../identity/auth.service';
import { TablesService } from '../tables/tables.service';

// Customer accounts are global. Every method here acts on the authenticated customer's own data only.
@Injectable()
export class CustomersService {
  constructor(private readonly db: Db, private readonly auth: AuthService, private readonly tables: TablesService) {}
  private me() { return principal().id!; }

  async profile() {
    const c = await unscoped('own account', () => this.db.q.selectFrom('customers').select(['public_id', 'email', 'phone', 'full_name', 'preferred_language_code', 'created_at']).where('id', '=', this.me()).executeTakeFirstOrThrow());
    return { publicId: c.public_id, email: c.email, phone: c.phone, fullName: c.full_name, language: c.preferred_language_code, createdAt: c.created_at };
  }
  async updateProfile(d: { fullName?: string; phone?: string; language?: string }) {
    await unscoped('own account', () => this.db.q.updateTable('customers').set({ full_name: d.fullName, phone: d.phone, preferred_language_code: d.language }).where('id', '=', this.me()).execute());
    return this.profile();
  }

  // Erasure: personal fields go, order and invoice rows stay as anonymous records for tax retention.
  async deleteAccount() {
    const id = this.me();
    await unscoped('own account erasure', () => this.db.tx(async (tx) => {
      await tx.updateTable('customers').set({ email: null, phone: null, password_hash: null, full_name: null, status: 'disabled', anonymized_at: new Date(), deleted_at: new Date() }).where('id', '=', id).execute();
      await tx.deleteFrom('customer_addresses').where('customer_id', '=', id).execute();
      await tx.deleteFrom('customer_identities').where('customer_id', '=', id).execute();
      await tx.deleteFrom('customer_favorites').where('customer_id', '=', id).execute();
      await tx.deleteFrom('customer_wishlist_items').where('customer_id', '=', id).execute();
      await tx.deleteFrom('device_tokens').where('customer_id', '=', id).execute();
    }));
    await this.auth.revokeAll({ customerId: id }, 'account_deleted');
    return { ok: true };
  }

  addresses() { return unscoped('own account', () => this.db.q.selectFrom('customer_addresses').selectAll().where('customer_id', '=', this.me()).where('deleted_at', 'is', null).execute()); }
  async addAddress(d: { label?: string; addressLine1: string; addressLine2?: string; city: string; stateName?: string; postalCode?: string; countryCode: string; isDefault?: boolean }) {
    const publicId = ulid();
    await unscoped('own account', () => this.db.q.insertInto('customer_addresses').values({ public_id: publicId, customer_id: this.me(), label: d.label ?? null, address_line1: d.addressLine1, address_line2: d.addressLine2 ?? null, city: d.city, state_name: d.stateName ?? null, postal_code: d.postalCode ?? null, country_code: d.countryCode, is_default: d.isDefault ? 1 : 0 }).execute());
    return { publicId };
  }
  async removeAddress(publicId: string) {
    await unscoped('own account', () => this.db.q.updateTable('customer_addresses').set({ deleted_at: new Date() }).where('customer_id', '=', this.me()).where('public_id', '=', publicId).execute());
    return { ok: true };
  }

  favorites() {
    return unscoped('own favourites across cafes', () => this.db.q.selectFrom('customer_favorites as f').innerJoin('cafes as c', 'c.id', 'f.cafe_id').select(['c.public_id', 'c.slug', 'c.display_name']).where('f.customer_id', '=', this.me()).where('c.status', '=', 'active').execute());
  }
  private async cafeBySlug(slug: string) {
    const c = await unscoped('slug precedes tenant resolution', () => this.db.q.selectFrom('cafes').select('id').where('slug', '=', slug).where('status', '=', 'active').executeTakeFirst());
    if (!c) throw notFound('CAFE_NOT_FOUND');
    return c.id;
  }
  async addFavorite(slug: string) {
    const cafeId = await this.cafeBySlug(slug);
    await asTenant(cafeId, () => this.db.q.insertInto('customer_favorites').ignore().values({ customer_id: this.me(), cafe_id: cafeId }).execute());
    return { ok: true };
  }
  async removeFavorite(slug: string) {
    const cafeId = await this.cafeBySlug(slug);
    await asTenant(cafeId, () => this.db.q.deleteFrom('customer_favorites').where('cafe_id', '=', cafeId).where('customer_id', '=', this.me()).execute());
    return { ok: true };
  }

  async wishlist(slug: string) {
    const cafeId = await this.cafeBySlug(slug);
    return asTenant(cafeId, async () => {
      const rows = await this.db.q.selectFrom('customer_wishlist_items as w').innerJoin('products as p', 'p.id', 'w.product_id').innerJoin('product_translations as t', 't.product_id', 'p.id').select(['p.public_id', 't.language_code', 't.name']).where('w.cafe_id', '=', cafeId).where('w.customer_id', '=', this.me()).where('p.deleted_at', 'is', null).execute();
      const lang = currentLang();
      const out = new Map<string, { publicId: string; name: string }>();
      for (const r of rows) if (!out.has(r.public_id) || r.language_code === lang) out.set(r.public_id, { publicId: r.public_id, name: r.name });
      return [...out.values()];
    });
  }
  async addWish(slug: string, productPublicId: string) {
    const cafeId = await this.cafeBySlug(slug);
    await asTenant(cafeId, async () => this.db.q.insertInto('customer_wishlist_items').ignore().values({ customer_id: this.me(), cafe_id: cafeId, product_id: await idOf(this.db.q, 'products', productPublicId, 'PRODUCT_NOT_FOUND') }).execute());
    return { ok: true };
  }
  async removeWish(slug: string, productPublicId: string) {
    const cafeId = await this.cafeBySlug(slug);
    await asTenant(cafeId, async () => this.db.q.deleteFrom('customer_wishlist_items').where('cafe_id', '=', cafeId).where('customer_id', '=', this.me()).where('product_id', '=', await idOf(this.db.q, 'products', productPublicId, 'PRODUCT_NOT_FOUND')).execute());
    return { ok: true };
  }

  async loyalty(slug: string) {
    const cafeId = await this.cafeBySlug(slug);
    return asTenant(cafeId, async () => {
      const [acct, ledger, program] = await Promise.all([
        this.db.q.selectFrom('customer_loyalty_points').select(['balance_points', 'lifetime_points']).where('cafe_id', '=', cafeId).where('customer_id', '=', this.me()).executeTakeFirst(),
        this.db.q.selectFrom('loyalty_ledger').select(['entry_type', 'points', 'occurred_at']).where('cafe_id', '=', cafeId).where('customer_id', '=', this.me()).orderBy('id', 'desc').limit(50).execute(),
        this.db.q.selectFrom('loyalty_programs').select(['is_active', 'currency_value_per_point', 'min_redeem_points']).where('cafe_id', '=', cafeId).executeTakeFirst(),
      ]);
      return { balance: acct?.balance_points ?? 0, lifetime: acct?.lifetime_points ?? 0, ledger, program: program ?? null };
    });
  }

  async reserve(slug: string, branchPublicId: string, d: { partySize: number; startsAt: string; endsAt: string; notes?: string }) {
    const cafeId = await this.cafeBySlug(slug);
    return asTenant(cafeId, async () => {
      const branchId = await idOf(this.db.q, 'cafe_branches', branchPublicId, 'BRANCH_NOT_FOUND');
      return this.tables.createReservation(d, branchId, this.me());
    });
  }

  // Cafe side: only customers linked to this cafe are visible, and only with the permission that guards this route.
  async cafeList(query: { page?: string; limit?: string }) {
    const { page, limit, offset } = requirePage(query);
    const base = this.db.q.selectFrom('cafe_customers as l').innerJoin('customers as c', 'c.id', 'l.customer_id').where('l.cafe_id', '=', tenantId());
    const [rows, count] = await Promise.all([
      base.select(['l.public_id', 'c.full_name', 'c.email', 'c.phone', 'l.first_order_at', 'l.last_order_at', 'l.total_orders', 'l.marketing_consent_at']).orderBy('l.last_order_at', 'desc').limit(limit).offset(offset).execute(),
      base.select((eb) => eb.fn.countAll<number>().as('n')).executeTakeFirstOrThrow(),
    ]);
    return paged(rows, page, limit, Number(count.n));
  }

}
