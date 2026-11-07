import { Injectable } from '@nestjs/common';
import { store, tenantId, asTenant, unscoped, currentLang } from '../../common/context';
import { badRequest, notFound } from '../../common/errors';
import { ulid } from '../../common/ids';
import { idOf } from '../../common/lookup';
import { assertPrecision, dbMoney } from '../../common/money';
import { audit, Db, Q } from '../../infra/db/db.service';
import { pickTranslation } from '../tenancy/settings';

export interface Tr { language: string; name: string; description?: string }

@Injectable()
export class CatalogService {
  constructor(private readonly db: Db) {}

  private async cafeInfo(q: Q = this.db.q) {
    return q.selectFrom('cafes as c').innerJoin('currencies as m', 'm.code', 'c.currency_code').select(['c.default_language_code', 'c.currency_code', 'm.minor_unit']).where('c.id', '=', tenantId()).executeTakeFirstOrThrow();
  }

  // The cafe's default-language translation is mandatory, so fallback always has something to show.
  private async requireDefault(translations: Tr[], q: Q) {
    const { default_language_code } = await this.cafeInfo(q);
    if (!translations.some((t) => t.language === default_language_code)) throw badRequest('DEFAULT_LANGUAGE_TRANSLATION_REQUIRED', default_language_code);
  }
  private async checkPrice(price: string, q: Q) {
    const { minor_unit } = await this.cafeInfo(q);
    if (!assertPrecision(price, minor_unit)) throw badRequest('PRICE_PRECISION_INVALID', { maxDecimals: minor_unit });
    return dbMoney(price);
  }

  // Categories
  async listCategories() {
    const rows = await this.db.q.selectFrom('categories as c').innerJoin('category_translations as t', 't.category_id', 'c.id')
      .select(['c.public_id', 'c.sort_order', 'c.is_active', 't.language_code', 't.name', 't.description']).where('c.cafe_id', '=', tenantId()).where('c.deleted_at', 'is', null).orderBy('c.sort_order').execute();
    const out = new Map<string, { publicId: string; sortOrder: number; isActive: boolean; translations: Tr[] }>();
    for (const r of rows) {
      if (!out.has(r.public_id)) out.set(r.public_id, { publicId: r.public_id, sortOrder: r.sort_order, isActive: !!r.is_active, translations: [] });
      out.get(r.public_id)!.translations.push({ language: r.language_code, name: r.name, description: r.description ?? undefined });
    }
    return [...out.values()];
  }

  async createCategory(d: { translations: Tr[]; sortOrder?: number; parentId?: string }) {
    return this.db.tx(async (tx) => {
      await this.requireDefault(d.translations, tx);
      const publicId = ulid();
      const parent = d.parentId ? await idOf(tx, 'categories', d.parentId) : null;
      const id = Number((await tx.insertInto('categories').values({ public_id: publicId, cafe_id: tenantId(), parent_id: parent, sort_order: d.sortOrder ?? 0 }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('category_translations').values(d.translations.map((t) => ({ cafe_id: tenantId(), category_id: id, language_code: t.language, name: t.name, description: t.description ?? null }))).execute();
      await audit(tx, { action: 'category.created', entityType: 'category', entityId: publicId });
      return { publicId };
    });
  }

  async updateCategory(publicId: string, d: { translations?: Tr[]; sortOrder?: number; isActive?: boolean }) {
    await this.db.tx(async (tx) => {
      const id = await idOf(tx, 'categories', publicId);
      if (d.sortOrder !== undefined || d.isActive !== undefined) {
        await tx.updateTable('categories').set({ sort_order: d.sortOrder, is_active: d.isActive === undefined ? undefined : d.isActive ? 1 : 0 }).where('cafe_id', '=', tenantId()).where('id', '=', id).execute();
      }
      for (const t of d.translations ?? []) {
        await tx.insertInto('category_translations').values({ cafe_id: tenantId(), category_id: id, language_code: t.language, name: t.name, description: t.description ?? null })
          .onDuplicateKeyUpdate({ name: t.name, description: t.description ?? null }).execute();
      }
      await audit(tx, { action: 'category.updated', entityType: 'category', entityId: publicId });
    });
    return { ok: true };
  }

  async deleteCategory(publicId: string) {
    await this.db.tx(async (tx) => {
      const id = await idOf(tx, 'categories', publicId);
      const used = await tx.selectFrom('products').select('id').where('cafe_id', '=', tenantId()).where('category_id', '=', id).where('deleted_at', 'is', null).limit(1).executeTakeFirst();
      if (used) throw badRequest('CATEGORY_HAS_PRODUCTS');
      await tx.updateTable('categories').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('id', '=', id).execute();
      await audit(tx, { action: 'category.deleted', entityType: 'category', entityId: publicId });
    });
    return { ok: true };
  }

  // Products
  async createProduct(d: { categoryId: string; basePrice: string; translations: Tr[]; dietaryClass?: 'veg' | 'non_veg' | 'egg' | 'vegan' | 'not_applicable'; taxCategoryId?: string; sku?: string; prepMinutes?: number; productType?: 'simple' | 'combo'; sortOrder?: number }) {
    return this.db.tx(async (tx) => {
      await this.requireDefault(d.translations, tx);
      const publicId = ulid();
      const id = Number((await tx.insertInto('products').values({
        public_id: publicId, cafe_id: tenantId(), category_id: await idOf(tx, 'categories', d.categoryId, 'CATEGORY_NOT_FOUND'), base_price: await this.checkPrice(d.basePrice, tx),
        dietary_class: d.dietaryClass, tax_category_id: d.taxCategoryId ? (await this.taxCategoryId(tx, d.taxCategoryId)) : null, sku: d.sku ?? null, prep_minutes: d.prepMinutes ?? null, product_type: d.productType, sort_order: d.sortOrder ?? 0,
      }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('product_translations').values(d.translations.map((t) => ({ cafe_id: tenantId(), product_id: id, language_code: t.language, name: t.name, description: t.description ?? null }))).execute();
      await audit(tx, { action: 'product.created', entityType: 'product', entityId: publicId });
      return { publicId };
    });
  }

  private async taxCategoryId(q: Q, code: string) {
    const row = await q.selectFrom('tax_categories').select('id').where('cafe_id', '=', tenantId()).where('code', '=', code).executeTakeFirst();
    if (!row) throw notFound('TAX_CATEGORY_NOT_FOUND');
    return row.id;
  }

  async updateProduct(publicId: string, d: { categoryId?: string; basePrice?: string; translations?: Tr[]; dietaryClass?: 'veg' | 'non_veg' | 'egg' | 'vegan' | 'not_applicable'; taxCategoryId?: string; isActive?: boolean; isOutOfStock?: boolean; prepMinutes?: number; sortOrder?: number }) {
    await this.db.tx(async (tx) => {
      const id = await idOf(tx, 'products', publicId);
      await tx.updateTable('products').set({
        category_id: d.categoryId ? await idOf(tx, 'categories', d.categoryId, 'CATEGORY_NOT_FOUND') : undefined, base_price: d.basePrice ? await this.checkPrice(d.basePrice, tx) : undefined,
        dietary_class: d.dietaryClass, tax_category_id: d.taxCategoryId ? await this.taxCategoryId(tx, d.taxCategoryId) : undefined,
        is_active: d.isActive === undefined ? undefined : d.isActive ? 1 : 0, is_out_of_stock: d.isOutOfStock === undefined ? undefined : d.isOutOfStock ? 1 : 0, prep_minutes: d.prepMinutes, sort_order: d.sortOrder,
      }).where('cafe_id', '=', tenantId()).where('id', '=', id).execute();
      for (const t of d.translations ?? []) {
        await tx.insertInto('product_translations').values({ cafe_id: tenantId(), product_id: id, language_code: t.language, name: t.name, description: t.description ?? null })
          .onDuplicateKeyUpdate({ name: t.name, description: t.description ?? null }).execute();
      }
      await audit(tx, { action: 'product.updated', entityType: 'product', entityId: publicId, after: { basePrice: d.basePrice, isActive: d.isActive, isOutOfStock: d.isOutOfStock } });
    });
    return { ok: true };
  }

  async deleteProduct(publicId: string) {
    await this.db.tx(async (tx) => {
      const id = await idOf(tx, 'products', publicId);
      await tx.updateTable('products').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('id', '=', id).execute();
      await audit(tx, { action: 'product.deleted', entityType: 'product', entityId: publicId });
    });
    return { ok: true };
  }

  async addVariant(productPublicId: string, d: { price: string; translations: Tr[]; isDefault?: boolean; sku?: string }) {
    return this.db.tx(async (tx) => {
      await this.requireDefault(d.translations, tx);
      const publicId = ulid();
      const id = Number((await tx.insertInto('product_variants').values({ public_id: publicId, cafe_id: tenantId(), product_id: await idOf(tx, 'products', productPublicId), price: await this.checkPrice(d.price, tx), is_default: d.isDefault ? 1 : 0, sku: d.sku ?? null }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('product_variant_translations').values(d.translations.map((t) => ({ cafe_id: tenantId(), variant_id: id, language_code: t.language, name: t.name }))).execute();
      return { publicId };
    });
  }

  async deleteVariant(publicId: string) {
    const r = await this.db.q.updateTable('product_variants').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  async createAddonGroup(d: { translations: Tr[]; minSelect?: number; maxSelect?: number; addons: Array<{ price: string; translations: Tr[] }> }) {
    return this.db.tx(async (tx) => {
      await this.requireDefault(d.translations, tx);
      const publicId = ulid();
      const gid = Number((await tx.insertInto('addon_groups').values({ public_id: publicId, cafe_id: tenantId(), min_select: d.minSelect ?? 0, max_select: d.maxSelect ?? null }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('addon_group_translations').values(d.translations.map((t) => ({ cafe_id: tenantId(), addon_group_id: gid, language_code: t.language, name: t.name }))).execute();
      const addons: string[] = [];
      for (const a of d.addons) {
        await this.requireDefault(a.translations, tx);
        const aPublic = ulid();
        const aid = Number((await tx.insertInto('product_addons').values({ public_id: aPublic, cafe_id: tenantId(), addon_group_id: gid, price: await this.checkPrice(a.price, tx) }).executeTakeFirstOrThrow()).insertId);
        await tx.insertInto('product_addon_translations').values(a.translations.map((t) => ({ cafe_id: tenantId(), addon_id: aid, language_code: t.language, name: t.name }))).execute();
        addons.push(aPublic);
      }
      return { publicId, addons };
    });
  }

  async setProductAddonGroups(productPublicId: string, groupIds: string[]) {
    await this.db.tx(async (tx) => {
      const pid = await idOf(tx, 'products', productPublicId);
      await tx.deleteFrom('product_addon_groups').where('cafe_id', '=', tenantId()).where('product_id', '=', pid).execute();
      for (const [i, g] of groupIds.entries()) await tx.insertInto('product_addon_groups').values({ cafe_id: tenantId(), product_id: pid, addon_group_id: await idOf(tx, 'addon_groups', g), sort_order: i }).execute();
    });
    return { ok: true };
  }

  async setComboItems(productPublicId: string, items: Array<{ productId: string; variantId?: string; quantity: number }>) {
    await this.db.tx(async (tx) => {
      const combo = await idOf(tx, 'products', productPublicId);
      await tx.updateTable('products').set({ product_type: 'combo' }).where('cafe_id', '=', tenantId()).where('id', '=', combo).execute();
      await tx.deleteFrom('combo_items').where('cafe_id', '=', tenantId()).where('combo_product_id', '=', combo).execute();
      for (const i of items) {
        await tx.insertInto('combo_items').values({ cafe_id: tenantId(), combo_product_id: combo, item_product_id: await idOf(tx, 'products', i.productId), item_variant_id: i.variantId ? await idOf(tx, 'product_variants', i.variantId) : null, quantity: i.quantity }).execute();
      }
    });
    return { ok: true };
  }

  async setSchedules(productPublicId: string, windows: Array<{ weekday?: number; startsAt: string; endsAt: string }>) {
    await this.db.tx(async (tx) => {
      const pid = await idOf(tx, 'products', productPublicId);
      await tx.deleteFrom('product_availability_schedules').where('cafe_id', '=', tenantId()).where('product_id', '=', pid).execute();
      if (windows.length) await tx.insertInto('product_availability_schedules').values(windows.map((w) => ({ cafe_id: tenantId(), product_id: pid, weekday: w.weekday ?? null, starts_at: w.startsAt, ends_at: w.endsAt }))).execute();
    });
    return { ok: true };
  }

  async setBranchOverride(branchPublicId: string, productPublicId: string, d: { price?: string | null; isAvailable?: boolean | null }) {
    await this.db.tx(async (tx) => {
      const branch = await idOf(tx, 'cafe_branches', branchPublicId, 'BRANCH_NOT_FOUND');
      const product = await idOf(tx, 'products', productPublicId);
      const price = d.price ? await this.checkPrice(d.price, tx) : null;
      const available = d.isAvailable === undefined || d.isAvailable === null ? null : d.isAvailable ? 1 : 0;
      await tx.insertInto('branch_product_overrides').values({ cafe_id: tenantId(), branch_id: branch, product_id: product, price_override: price, is_available: available })
        .onDuplicateKeyUpdate({ price_override: price, is_available: available }).execute();
      await audit(tx, { action: 'product.branch_override', entityType: 'product', entityId: productPublicId, after: d, branchId: branch });
    });
    return { ok: true };
  }

  // Tax
  async listTaxCategories() {
    const [cats, rates] = await Promise.all([
      this.db.q.selectFrom('tax_categories').selectAll().where('cafe_id', '=', tenantId()).execute(),
      this.db.q.selectFrom('tax_rates').selectAll().where('cafe_id', '=', tenantId()).orderBy('valid_from', 'desc').execute(),
    ]);
    return cats.map((c) => ({ code: c.code, name: c.name, taxCode: c.tax_code, isActive: !!c.is_active, rates: rates.filter((r) => r.tax_category_id === c.id).map((r) => ({ componentCode: r.component_code, displayName: r.display_name, ratePercent: r.rate_percent, appliesTo: r.applies_to, validFrom: r.valid_from, validTo: r.valid_to })) }));
  }
  async createTaxCategory(d: { code: string; name: string; taxCode?: string }) {
    await this.db.tx(async (tx) => {
      await tx.insertInto('tax_categories').values({ cafe_id: tenantId(), code: d.code, name: d.name, tax_code: d.taxCode ?? null }).execute();
      await audit(tx, { action: 'tax.category_created', entityType: 'tax_category', entityId: d.code });
    });
    return { code: d.code };
  }
  // Rates are versioned by date. A new rate closes the previous one, leaving past invoices untouched.
  async addTaxRate(code: string, d: { componentCode: string; displayName: string; ratePercent: string; appliesTo?: 'always' | 'intra_region' | 'inter_region'; validFrom: string }) {
    await this.db.tx(async (tx) => {
      const cat = await this.taxCategoryId(tx, code);
      await tx.updateTable('tax_rates').set({ valid_to: d.validFrom } as never).where('cafe_id', '=', tenantId()).where('tax_category_id', '=', cat).where('component_code', '=', d.componentCode).where('valid_to', 'is', null).where('valid_from', '<', new Date(d.validFrom)).execute();
      await tx.insertInto('tax_rates').values({ cafe_id: tenantId(), tax_category_id: cat, component_code: d.componentCode, display_name: d.displayName, rate_percent: d.ratePercent, applies_to: d.appliesTo, valid_from: new Date(d.validFrom) }).execute();
      await audit(tx, { action: 'tax.rate_added', entityType: 'tax_category', entityId: code, after: d });
    });
    return { ok: true };
  }
  async addTaxRegistration(d: { branchId?: string; taxSystem: string; registrationNumber: string; legalName: string; regionCode?: string; validFrom: string }) {
    await this.db.tx(async (tx) => {
      await tx.insertInto('tax_registrations').values({ cafe_id: tenantId(), branch_id: d.branchId ? await idOf(tx, 'cafe_branches', d.branchId, 'BRANCH_NOT_FOUND') : null, tax_system: d.taxSystem, registration_number: d.registrationNumber, legal_name: d.legalName, region_code: d.regionCode ?? null, valid_from: new Date(d.validFrom) }).execute();
      await audit(tx, { action: 'tax.registration_added', entityType: 'tax_registration', entityId: d.registrationNumber });
    });
    return { ok: true };
  }

  // Menu read models.
  async staffProducts() { return this.menu(currentLang(), store()?.branchId, true); }

  async publicMenu(slug: string, lang: string, branchPublicId?: string) {
    const cafe = await unscoped('slug precedes tenant resolution', () => this.db.q.selectFrom('cafes').select('id').where('slug', '=', slug).where('status', '=', 'active').executeTakeFirst());
    if (!cafe) throw notFound('CAFE_NOT_FOUND');
    return asTenant(cafe.id, async () => {
      let branchId: number | undefined;
      if (branchPublicId) branchId = await idOf(this.db.q, 'cafe_branches', branchPublicId, 'BRANCH_NOT_FOUND');
      return this.menu(lang, branchId, false);
    });
  }

  async menu(lang: string, branchId: number | undefined, includeHidden: boolean) {
    const cafeId = tenantId();
    const q = this.db.q;
    const { default_language_code: fallback, currency_code: currency } = await this.cafeInfo();
    const [cats, catTr, prods, prodTr, variants, varTr, links, groups, groupTr, addons, addonTr, images, overrides, schedules] = await Promise.all([
      q.selectFrom('categories').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).orderBy('sort_order').execute(),
      q.selectFrom('category_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
      q.selectFrom('products').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).orderBy('sort_order').execute(),
      q.selectFrom('product_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
      q.selectFrom('product_variants').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).orderBy('sort_order').execute(),
      q.selectFrom('product_variant_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
      q.selectFrom('product_addon_groups').selectAll().where('cafe_id', '=', cafeId).orderBy('sort_order').execute(),
      q.selectFrom('addon_groups').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).execute(),
      q.selectFrom('addon_group_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
      q.selectFrom('product_addons').selectAll().where('cafe_id', '=', cafeId).where('deleted_at', 'is', null).orderBy('sort_order').execute(),
      q.selectFrom('product_addon_translations').selectAll().where('cafe_id', '=', cafeId).execute(),
      q.selectFrom('product_images as i').innerJoin('media_assets as m', 'm.id', 'i.asset_id').select(['i.product_id', 'm.public_id', 'i.sort_order']).where('i.cafe_id', '=', cafeId).orderBy('i.sort_order').execute(),
      branchId ? q.selectFrom('branch_product_overrides').selectAll().where('cafe_id', '=', cafeId).where('branch_id', '=', branchId).execute() : Promise.resolve([]),
      q.selectFrom('product_availability_schedules').selectAll().where('cafe_id', '=', cafeId).execute(),
    ]);
    const tr = <T extends { language_code: string }>(rows: T[]) => pickTranslation(rows, lang, fallback);
    const products = prods.filter((p) => includeHidden || p.is_active).map((p) => {
      const t = tr(prodTr.filter((x) => x.product_id === p.id));
      const ov = overrides.find((o) => o.product_id === p.id && o.variant_id === null);
      const available = !p.is_out_of_stock && p.is_active === 1 && ov?.is_available !== 0;
      return {
        publicId: p.public_id, categoryId: cats.find((c) => c.id === p.category_id)?.public_id, name: t?.name ?? '', description: t?.description ?? null, resolvedLanguage: t?.language_code,
        price: { amount: ov?.price_override ?? p.base_price, currency }, dietaryClass: p.dietary_class, productType: p.product_type, prepMinutes: p.prep_minutes, isAvailable: available, isActive: !!p.is_active, isOutOfStock: !!p.is_out_of_stock,
        hasSchedule: schedules.some((s) => s.product_id === p.id),
        translations: includeHidden ? prodTr.filter((x) => x.product_id === p.id).map((x) => ({ language: x.language_code, name: x.name, description: x.description })) : undefined,
        imageUrls: images.filter((i) => i.product_id === p.id).map((i) => `/api/v1/public/media/${i.public_id}`),
        variants: variants.filter((v) => v.product_id === p.id && (includeHidden || v.is_active)).map((v) => ({ publicId: v.public_id, name: tr(varTr.filter((x) => x.variant_id === v.id))?.name ?? '', price: { amount: v.price, currency }, isDefault: !!v.is_default })),
        addonGroups: links.filter((l) => l.product_id === p.id).flatMap((l) => {
          const g = groups.find((x) => x.id === l.addon_group_id);
          if (!g) return [];
          return [{
            publicId: g.public_id, name: tr(groupTr.filter((x) => x.addon_group_id === g.id))?.name ?? '', minSelect: g.min_select, maxSelect: g.max_select,
            addons: addons.filter((a) => a.addon_group_id === g.id && (includeHidden || a.is_active)).map((a) => ({ publicId: a.public_id, name: tr(addonTr.filter((x) => x.addon_id === a.id))?.name ?? '', price: { amount: a.price, currency } })),
          }];
        }),
      };
    });
    const categories = cats.filter((c) => includeHidden || c.is_active).map((c) => {
      const t = tr(catTr.filter((x) => x.category_id === c.id));
      return { publicId: c.public_id, name: t?.name ?? '', description: t?.description ?? null, sortOrder: c.sort_order, isActive: !!c.is_active };
    });
    return { language: lang, currency, categories, products };
  }

  // The main photo: what the guest sees first. Replacing drops the link only, so the file stays with the cafe's media.
  async setProductImage(productPublicId: string, assetId: string) {
    await this.db.tx(async (tx) => {
      const asset = await tx.selectFrom('media_assets').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', assetId).where('status', '=', 'ready').executeTakeFirst();
      if (!asset) throw notFound('ASSET_NOT_FOUND');
      const productId = await idOf(tx, 'products', productPublicId);
      await tx.deleteFrom('product_images').where('cafe_id', '=', tenantId()).where('product_id', '=', productId).execute();
      await tx.insertInto('product_images').values({ cafe_id: tenantId(), product_id: productId, asset_id: asset.id }).execute();
    });
    return { ok: true };
  }

  async removeProductImage(productPublicId: string) {
    await this.db.tx(async (tx) => {
      const productId = await idOf(tx, 'products', productPublicId);
      await tx.deleteFrom('product_images').where('cafe_id', '=', tenantId()).where('product_id', '=', productId).execute();
    });
    return { ok: true };
  }

  async addProductImage(productPublicId: string, assetId: string) {
    await this.db.tx(async (tx) => {
      const asset = await tx.selectFrom('media_assets').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', assetId).where('status', '=', 'ready').executeTakeFirst();
      if (!asset) throw notFound('ASSET_NOT_FOUND');
      await tx.insertInto('product_images').values({ cafe_id: tenantId(), product_id: await idOf(tx, 'products', productPublicId), asset_id: asset.id }).execute();
    });
    return { ok: true };
  }
}
