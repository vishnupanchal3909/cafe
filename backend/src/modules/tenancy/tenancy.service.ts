import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { actorUserId, asTenant, principal, tenantId, unscoped } from '../../common/context';
import { badRequest, conflict, notFound } from '../../common/errors';
import { sha256, ulid } from '../../common/ids';
import { assertBranchAllowed } from '../../common/lookup';
import { audit, Db, emit, rooms } from '../../infra/db/db.service';
import { sniffImage, StorageService } from '../../infra/storage/storage.service';
import { hashPassword } from '../identity/crypto';
import { DEFAULT_SETTINGS, loadSettings } from './settings';

const SETTING_CHOICES: Record<string, string[]> = { paymentPolicy: ['prepay', 'postpay'], taxRounding: ['line', 'invoice'] };
const SETTING_RANGES: Record<string, [number, number]> = { sessionHours: [1, 24], sessionEndAfterPaymentMinutes: [0, 240], unpaidAlertMinutes: [5, 1440] };
const slugify = (s: string) => s.toLowerCase().normalize('NFKD').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60) || 'cafe';
const NEUTRAL_THEME = { primary_color: '#6F4E37', secondary_color: '#C8A27A', background_color: '#FFFFFF', text_color: '#1F1A17', font_key: 'noto_sans' };

export interface RegisterCafeInput {
  owner: { email: string; password: string; fullName: string; phone?: string };
  cafe: {
    name: string; legalName: string; description?: string; countryCode: string; currencyCode: string; defaultLanguage: string; timezone: string;
    supportedLanguages?: string[]; contactEmail?: string; contactPhone?: string; businessRegistrationNumber?: string;
  };
  branch: { name: string; addressLine1: string; addressLine2?: string; city: string; stateCode?: string; stateName?: string; postalCode?: string };
}

@Injectable()
export class TenancyService {
  constructor(private readonly db: Db, private readonly storage: StorageService) {}

  async register(input: RegisterCafeInput) {
    const email = input.owner.email.trim().toLowerCase();
    const passwordHash = await hashPassword(input.owner.password);
    return unscoped('cafe does not exist yet', () => this.db.tx(async (tx) => {
      if (await tx.selectFrom('users').select('id').where('email', '=', email).where('deleted_at', 'is', null).executeTakeFirst()) throw conflict('EMAIL_TAKEN');
      const country = await tx.selectFrom('countries').select(['fiscal_year_start_month']).where('code', '=', input.cafe.countryCode).where('is_active', '=', 1).executeTakeFirst();
      if (!country) throw badRequest('COUNTRY_UNSUPPORTED');
      if (!(await tx.selectFrom('currencies').select('code').where('code', '=', input.cafe.currencyCode).where('is_active', '=', 1).executeTakeFirst())) throw badRequest('CURRENCY_UNSUPPORTED');
      const languages = [...new Set([input.cafe.defaultLanguage, ...(input.cafe.supportedLanguages ?? [])])];
      const known = await tx.selectFrom('languages').select('code').where('code', 'in', languages).where('is_active', '=', 1).execute();
      if (known.length !== languages.length) throw badRequest('LANGUAGE_UNSUPPORTED');
      try { new Intl.DateTimeFormat('en', { timeZone: input.cafe.timezone }); } catch { throw badRequest('TIMEZONE_INVALID'); }

      const userId = Number((await tx.insertInto('users').values({
        public_id: ulid(), email, phone: input.owner.phone ?? null, password_hash: passwordHash, full_name: input.owner.fullName, status: 'active', preferred_language_code: input.cafe.defaultLanguage,
      }).executeTakeFirstOrThrow()).insertId);

      const base = slugify(input.cafe.name);
      const taken = await tx.selectFrom('cafes').select('id').where('slug', '=', base).executeTakeFirst();
      const slug = taken ? `${base}-${ulid().slice(-6).toLowerCase()}` : base;
      const publicId = ulid();
      const cafeId = Number((await tx.insertInto('cafes').values({
        public_id: publicId, slug, owner_user_id: userId, legal_name: input.cafe.legalName, display_name: input.cafe.name, description: input.cafe.description ?? null,
        country_code: input.cafe.countryCode, currency_code: input.cafe.currencyCode, default_language_code: input.cafe.defaultLanguage, timezone: input.cafe.timezone,
        fiscal_year_start_month: country.fiscal_year_start_month, contact_email: input.cafe.contactEmail ?? email, contact_phone: input.cafe.contactPhone ?? null,
        business_registration_number: input.cafe.businessRegistrationNumber ?? null,
      }).executeTakeFirstOrThrow()).insertId);

      const tenant = { cafe_id: cafeId };
      const branchId = Number((await tx.insertInto('cafe_branches').values({
        ...tenant, public_id: ulid(), code: 'MAIN', name: input.branch.name, address_line1: input.branch.addressLine1, address_line2: input.branch.addressLine2 ?? null,
        city: input.branch.city, state_code: input.branch.stateCode ?? null, state_name: input.branch.stateName ?? null, postal_code: input.branch.postalCode ?? null, is_main: 1,
      }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('cafe_staff').values({ ...tenant, public_id: ulid(), user_id: userId, status: 'active', job_title: 'Owner' }).execute();
      const ownerRole = await tx.selectFrom('roles').select('id').where('code', '=', 'owner').where('cafe_id', 'is', null).executeTakeFirstOrThrow();
      await tx.insertInto('user_roles').values({ ...tenant, user_id: userId, role_id: ownerRole.id }).execute();
      await tx.insertInto('cafe_themes').values({ ...tenant, ...NEUTRAL_THEME }).execute();
      await tx.insertInto('cafe_languages').values(languages.map((language_code, i) => ({ ...tenant, language_code, sort_order: i }))).execute();
      await tx.insertInto('cafe_translations').values({ ...tenant, language_code: input.cafe.defaultLanguage, display_name: input.cafe.name, description: input.cafe.description ?? null }).execute();
      await tx.insertInto('cafe_payment_methods').values({ ...tenant, method_code: 'cash' }).execute();
      await sql`INSERT INTO accounting_accounts (cafe_id, code, name, account_type, system_key)
        SELECT ${cafeId}, a.code, a.name, a.account_type, a.system_key FROM coa_template_accounts a JOIN coa_templates t ON t.id = a.template_id WHERE t.code = 'standard'`.execute(tx);
      await audit(tx, { action: 'cafe.registered', entityType: 'cafe', entityId: publicId, cafeId });
      await emit(tx, { type: 'cafe.registered', rooms: [rooms.platform()], payload: { cafeId: publicId, name: input.cafe.name } });
      return { cafePublicId: publicId, slug, status: 'pending_approval', branchPublicId: await tx.selectFrom('cafe_branches').select('public_id').where('id', '=', branchId).where('cafe_id', '=', cafeId).executeTakeFirstOrThrow().then((b) => b.public_id) };
    }));
  }

  async profile() {
    const c = await this.db.q.selectFrom('cafes').selectAll().where('id', '=', tenantId()).executeTakeFirstOrThrow();
    const minor = await this.db.q.selectFrom('currencies').select('minor_unit').where('code', '=', c.currency_code).executeTakeFirstOrThrow();
    const [languages, branches] = await Promise.all([
      this.db.q.selectFrom('cafe_languages as cl').innerJoin('languages as l', 'l.code', 'cl.language_code').select(['l.code', 'l.native_name', 'l.direction', 'cl.is_enabled']).where('cl.cafe_id', '=', tenantId()).orderBy('cl.sort_order').execute(),
      this.branches(),
    ]);
    return {
      publicId: c.public_id, slug: c.slug, name: c.display_name, legalName: c.legal_name, description: c.description, status: c.status, countryCode: c.country_code, currencyCode: c.currency_code, currencyMinorUnit: minor.minor_unit,
      defaultLanguage: c.default_language_code, timezone: c.timezone, fiscalYearStartMonth: c.fiscal_year_start_month, contactEmail: c.contact_email, contactPhone: c.contact_phone,
      website: c.website, businessRegistrationNumber: c.business_registration_number, languages, branches,
    };
  }

  /// What every staff member needs to work, whatever their role: no legal, tax or contact details.
  /// Branches are limited to the ones this person may work in, and their own permissions come with it.
  async workspace() {
    const c = await this.db.q.selectFrom('cafes').select(['public_id', 'slug', 'display_name', 'status', 'country_code', 'currency_code', 'default_language_code', 'timezone']).where('id', '=', tenantId()).executeTakeFirstOrThrow();
    const minor = await this.db.q.selectFrom('currencies').select('minor_unit').where('code', '=', c.currency_code).executeTakeFirstOrThrow();
    const p = principal();
    const settings = await loadSettings(this.db.q);
    let q = this.db.q.selectFrom('cafe_branches').select(['id', 'public_id', 'name', 'is_main']).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null);
    if (p.branchIds) q = q.where('id', 'in', p.branchIds.length ? p.branchIds : [0]);
    const branches = await q.orderBy('is_main', 'desc').execute();
    // Who is signed in and as what, so each portal can say so plainly.
    const me = await this.db.q.selectFrom('users').select(['full_name', 'email']).where('id', '=', p.id!).executeTakeFirstOrThrow();
    const roles = await this.db.q.selectFrom('user_roles as ur').innerJoin('roles as r', 'r.id', 'ur.role_id').select(['r.code', 'r.name'])
      .where('ur.user_id', '=', p.id!).where('ur.cafe_id', '=', tenantId()).where('r.deleted_at', 'is', null).orderBy('r.id').execute();
    return {
      user: { fullName: me.full_name, email: me.email, roles: roles.map((r) => ({ code: r.code, name: r.name })) },
      publicId: c.public_id, slug: c.slug, name: c.display_name, status: c.status, countryCode: c.country_code, currencyCode: c.currency_code, currencyMinorUnit: minor.minor_unit,
      defaultLanguage: c.default_language_code, timezone: c.timezone, branches: branches.map(({ id: _id, ...b }) => b), permissions: [...p.permissions].sort(),
      // The few cafe rules every role's screens need, without the full settings a manager edits.
      settings: { unpaidAlertMinutes: settings.unpaidAlertMinutes, tablePinRequired: settings.tablePinRequired },
    };
  }

  async updateProfile(patch: { name?: string; legalName?: string; description?: string; contactEmail?: string; contactPhone?: string; website?: string; businessRegistrationNumber?: string; timezone?: string; fiscalYearStartMonth?: number }) {
    await this.db.tx(async (tx) => {
      await tx.updateTable('cafes').set({
        display_name: patch.name, legal_name: patch.legalName, description: patch.description, contact_email: patch.contactEmail, contact_phone: patch.contactPhone,
        website: patch.website, business_registration_number: patch.businessRegistrationNumber, timezone: patch.timezone, fiscal_year_start_month: patch.fiscalYearStartMonth,
      }).where('id', '=', tenantId()).execute();
      await audit(tx, { action: 'cafe.profile_updated', entityType: 'cafe', entityId: tenantId(), after: patch });
    });
    return this.profile();
  }

  private branchRow = ['public_id', 'id', 'code', 'name', 'address_line1', 'address_line2', 'city', 'state_code', 'state_name', 'postal_code', 'timezone', 'business_day_cutoff', 'phone', 'is_main', 'status'] as const;

  async branches() {
    const rows = await this.db.q.selectFrom('cafe_branches').select(this.branchRow).where('cafe_id', '=', tenantId()).where('deleted_at', 'is', null).orderBy('is_main', 'desc').execute();
    return rows.map(({ id: _id, ...b }) => b);
  }

  async createBranch(b: { code: string; name: string; addressLine1: string; addressLine2?: string; city: string; stateCode?: string; stateName?: string; postalCode?: string; timezone?: string; phone?: string; businessDayCutoff?: string }) {
    return this.db.tx(async (tx) => {
      const publicId = ulid();
      await tx.insertInto('cafe_branches').values({
        cafe_id: tenantId(), public_id: publicId, code: b.code, name: b.name, address_line1: b.addressLine1, address_line2: b.addressLine2 ?? null, city: b.city,
        state_code: b.stateCode ?? null, state_name: b.stateName ?? null, postal_code: b.postalCode ?? null, timezone: b.timezone ?? null, phone: b.phone ?? null, business_day_cutoff: b.businessDayCutoff,
      }).execute();
      await audit(tx, { action: 'branch.created', entityType: 'branch', entityId: publicId });
      return { publicId };
    });
  }

  async updateBranch(publicId: string, patch: Record<string, unknown>) {
    const res = await this.db.tx(async (tx) => {
      const r = await tx.updateTable('cafe_branches').set(patch as never).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).where('deleted_at', 'is', null).executeTakeFirst();
      await audit(tx, { action: 'branch.updated', entityType: 'branch', entityId: publicId, after: patch });
      return r;
    });
    if (!res.numUpdatedRows) throw notFound();
    return { ok: true };
  }

  async setHours(branchPublicId: string, hours: Array<{ weekday: number; opensAt: string; closesAt: string; closesNextDay?: boolean }>) {
    await this.db.tx(async (tx) => {
      const b = await tx.selectFrom('cafe_branches').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', branchPublicId).executeTakeFirst();
      if (!b) throw notFound();
      assertBranchAllowed(b.id);
      await tx.deleteFrom('cafe_business_hours').where('cafe_id', '=', tenantId()).where('branch_id', '=', b.id).execute();
      if (hours.length) await tx.insertInto('cafe_business_hours').values(hours.map((h) => ({ cafe_id: tenantId(), branch_id: b.id, weekday: h.weekday, opens_at: h.opensAt, closes_at: h.closesAt, closes_next_day: h.closesNextDay ? 1 : 0 }))).execute();
      await audit(tx, { action: 'branch.hours_updated', entityType: 'branch', entityId: branchPublicId });
    });
    return { ok: true };
  }

  async hours(branchPublicId: string) {
    const b = await this.db.q.selectFrom('cafe_branches').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', branchPublicId).executeTakeFirst();
    if (!b) throw notFound('BRANCH_NOT_FOUND');
    return this.db.q.selectFrom('cafe_business_hours as h').innerJoin('cafe_branches as b', 'b.id', 'h.branch_id').select(['h.weekday', 'h.opens_at', 'h.closes_at', 'h.closes_next_day'])
      .where('h.cafe_id', '=', tenantId()).where('b.public_id', '=', branchPublicId).orderBy('h.weekday').orderBy('h.opens_at').execute();
  }

  async setLanguages(codes: string[]) {
    await this.db.tx(async (tx) => {
      const cafe = await tx.selectFrom('cafes').select('default_language_code').where('id', '=', tenantId()).executeTakeFirstOrThrow();
      const wanted = [...new Set([cafe.default_language_code, ...codes])];
      if ((await tx.selectFrom('languages').select('code').where('code', 'in', wanted).where('is_active', '=', 1).execute()).length !== wanted.length) throw badRequest('LANGUAGE_UNSUPPORTED');
      await tx.deleteFrom('cafe_languages').where('cafe_id', '=', tenantId()).execute();
      await tx.insertInto('cafe_languages').values(wanted.map((language_code, i) => ({ cafe_id: tenantId(), language_code, sort_order: i }))).execute();
      await audit(tx, { action: 'cafe.languages_updated', after: wanted });
    });
    return { ok: true };
  }

  settings() { return loadSettings(this.db.q); }

  async updateSettings(patch: Partial<Record<keyof typeof DEFAULT_SETTINGS, unknown>>) {
    await this.db.tx(async (tx) => {
      for (const [key, value] of Object.entries(patch)) {
        if (!(key in DEFAULT_SETTINGS)) throw badRequest('SETTING_UNKNOWN', key);
        if (typeof value !== typeof DEFAULT_SETTINGS[key as keyof typeof DEFAULT_SETTINGS] && value !== null) throw badRequest('SETTING_TYPE_INVALID', key);
        if (SETTING_CHOICES[key] && !SETTING_CHOICES[key]!.includes(value as string)) throw badRequest('SETTING_VALUE_INVALID', key);
        const range = SETTING_RANGES[key];
        if (range && (!Number.isInteger(value) || (value as number) < range[0] || (value as number) > range[1])) throw badRequest('SETTING_VALUE_INVALID', key);
        await tx.insertInto('cafe_settings').values({ cafe_id: tenantId(), setting_key: key, value: JSON.stringify(value), updated_by_user_id: actorUserId() })
          .onDuplicateKeyUpdate({ value: JSON.stringify(value), updated_by_user_id: actorUserId() }).execute();
      }
      await audit(tx, { action: 'cafe.settings_updated', after: patch });
    });
    return this.settings();
  }

  async theme() {
    return this.db.q.selectFrom('cafe_themes').selectAll().where('cafe_id', '=', tenantId()).executeTakeFirstOrThrow();
  }

  async updateTheme(t: { primaryColor?: string; secondaryColor?: string; backgroundColor?: string; textColor?: string; fontKey?: string; buttonStyle?: 'rounded' | 'pill' | 'square'; menuLayout?: 'list' | 'grid' | 'compact'; themeMode?: 'light' | 'dark' | 'system'; logoAssetId?: string; coverAssetId?: string }) {
    await this.db.tx(async (tx) => {
      await tx.updateTable('cafe_themes').set((eb) => ({
        primary_color: t.primaryColor, secondary_color: t.secondaryColor, background_color: t.backgroundColor, text_color: t.textColor, font_key: t.fontKey,
        button_style: t.buttonStyle, menu_layout: t.menuLayout, theme_mode: t.themeMode, version: eb('version', '+', 1),
      })).where('cafe_id', '=', tenantId()).execute();
      for (const [field, value] of [['logo_asset_id', t.logoAssetId], ['cover_asset_id', t.coverAssetId]] as const) {
        if (!value) continue;
        const asset = await tx.selectFrom('media_assets').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', value).where('status', '=', 'ready').executeTakeFirst();
        if (!asset) throw notFound('ASSET_NOT_FOUND');
        await tx.updateTable('cafes').set({ [field]: asset.id }).where('id', '=', tenantId()).execute();
      }
      await audit(tx, { action: 'cafe.theme_updated', after: t });
    });
    return this.theme();
  }

  async upload(file: Express.Multer.File | undefined, kind: 'logo' | 'cover' | 'banner' | 'product_image') {
    if (!file) throw badRequest('FILE_REQUIRED');
    if (file.size > 5 * 1024 * 1024) throw badRequest('FILE_TOO_LARGE');
    const type = sniffImage(file.buffer);
    if (!type) throw badRequest('FILE_TYPE_UNSUPPORTED');
    const publicId = ulid();
    const key = `cafes/${tenantId()}/${kind}/${publicId}.${type.ext}`;
    await this.storage.put(key, file.buffer, type.mime);
    await this.db.q.insertInto('media_assets').values({
      public_id: publicId, cafe_id: tenantId(), kind, storage_key: key, mime_type: type.mime, byte_size: file.size, sha256: sha256(file.buffer.toString('latin1')), status: 'ready', uploaded_by_user_id: actorUserId(),
    }).execute();
    return { publicId, url: `/api/v1/public/media/${publicId}` };
  }

  // Only media kinds designed for public display are served without authentication.
  async publicMedia(publicId: string) {
    const a = await unscoped('public media', () => this.db.q.selectFrom('media_assets').select(['storage_key', 'mime_type']).where('public_id', '=', publicId).where('status', '=', 'ready').where('deleted_at', 'is', null)
      .where('kind', 'in', ['logo', 'cover', 'banner', 'product_image']).executeTakeFirst());
    if (!a) throw notFound();
    return { body: await this.storage.get(a.storage_key), mime: a.mime_type };
  }

  async referenceData() {
    return unscoped('reference data', async () => ({
      languages: await this.db.q.selectFrom('languages').select(['code', 'name', 'native_name', 'direction']).where('is_active', '=', 1).orderBy('sort_order').execute(),
      currencies: await this.db.q.selectFrom('currencies').select(['code', 'name', 'symbol', 'minor_unit']).where('is_active', '=', 1).orderBy('code').execute(),
      countries: await this.db.q.selectFrom('countries').select(['code', 'name', 'default_currency_code', 'default_language_code', 'default_timezone']).where('is_active', '=', 1).orderBy('name').execute(),
    }));
  }

  async publicConfig(slug: string, lang: string) {
    const cafe = await unscoped('slug precedes tenant resolution', () => this.db.q.selectFrom('cafes').select(['id']).where('slug', '=', slug).where('status', '=', 'active').executeTakeFirst());
    if (!cafe) throw notFound('CAFE_NOT_FOUND');
    return asTenant(cafe.id, () => this.configFor(cafe.id, lang));
  }

  async configFor(cafeId: number, lang: string) {
    const c = await this.db.q.selectFrom('cafes as c')
      .leftJoin('media_assets as logo', 'logo.id', 'c.logo_asset_id').leftJoin('media_assets as cover', 'cover.id', 'c.cover_asset_id')
      .select(['c.public_id', 'c.slug', 'c.display_name', 'c.description', 'c.currency_code', 'c.default_language_code', 'c.timezone', 'c.country_code', 'logo.public_id as logo', 'cover.public_id as cover'])
      .where('c.id', '=', cafeId).executeTakeFirstOrThrow();
    const [theme, languages, currency, translation, settings, banners] = await Promise.all([
      this.db.q.selectFrom('cafe_themes').selectAll().where('cafe_id', '=', cafeId).executeTakeFirstOrThrow(),
      this.db.q.selectFrom('cafe_languages as cl').innerJoin('languages as l', 'l.code', 'cl.language_code').select(['l.code', 'l.native_name', 'l.direction']).where('cl.cafe_id', '=', cafeId).where('cl.is_enabled', '=', 1).orderBy('cl.sort_order').execute(),
      this.db.q.selectFrom('currencies').select(['code', 'symbol', 'minor_unit']).where('code', '=', c.currency_code).executeTakeFirstOrThrow(),
      this.db.q.selectFrom('cafe_translations').select(['display_name', 'description']).where('cafe_id', '=', cafeId).where('language_code', '=', lang).executeTakeFirst(),
      loadSettings(this.db.q),
      this.banners(lang, c.default_language_code),
    ]);
    const media = (id: string | null) => (id ? `/api/v1/public/media/${id}` : null);
    return {
      cafe: { publicId: c.public_id, slug: c.slug, name: translation?.display_name ?? c.display_name, description: translation?.description ?? c.description, logoUrl: media(c.logo), coverUrl: media(c.cover), timezone: c.timezone, countryCode: c.country_code },
      theme: { primaryColor: theme.primary_color, secondaryColor: theme.secondary_color, backgroundColor: theme.background_color, textColor: theme.text_color, fontKey: theme.font_key, buttonStyle: theme.button_style, menuLayout: theme.menu_layout, themeMode: theme.theme_mode, version: theme.version },
      languages: languages.map((l) => ({ code: l.code, nativeName: l.native_name, direction: l.direction })), defaultLanguage: c.default_language_code,
      currency: { code: currency.code, symbol: currency.symbol, minorUnit: currency.minor_unit },
      ordering: { paymentPolicy: settings.paymentPolicy, guestOrderingEnabled: settings.guestOrderingEnabled }, banners,
    };
  }

  async banners(lang: string, fallback: string) {
    const now = new Date();
    const rows = await this.db.q.selectFrom('banners as b').innerJoin('media_assets as m', 'm.id', 'b.image_asset_id').innerJoin('banner_translations as t', 't.banner_id', 'b.id')
      .select(['b.public_id', 'b.placement', 'm.public_id as asset', 't.language_code', 't.title', 't.subtitle']).where('b.cafe_id', '=', tenantId()).where('b.is_active', '=', 1).where('b.deleted_at', 'is', null)
      .where((eb) => eb.or([eb('b.starts_at', 'is', null), eb('b.starts_at', '<=', now)])).where((eb) => eb.or([eb('b.ends_at', 'is', null), eb('b.ends_at', '>=', now)])).orderBy('b.sort_order').execute();
    const out = new Map<string, (typeof rows)[number]>();
    for (const r of rows) {
      const cur = out.get(r.public_id);
      if (!cur || r.language_code === lang || (r.language_code === fallback && cur.language_code !== lang)) out.set(r.public_id, r);
    }
    return [...out.values()].map((r) => ({ publicId: r.public_id, placement: r.placement, imageUrl: `/api/v1/public/media/${r.asset}`, title: r.title, subtitle: r.subtitle }));
  }

  async createBanner(b: { assetId: string; placement?: 'cover' | 'promotional'; translations: Array<{ language: string; title: string; subtitle?: string }>; startsAt?: string; endsAt?: string }) {
    return this.db.tx(async (tx) => {
      const asset = await tx.selectFrom('media_assets').select('id').where('cafe_id', '=', tenantId()).where('public_id', '=', b.assetId).executeTakeFirst();
      if (!asset) throw notFound('ASSET_NOT_FOUND');
      const publicId = ulid();
      const id = Number((await tx.insertInto('banners').values({ public_id: publicId, cafe_id: tenantId(), image_asset_id: asset.id, placement: b.placement, starts_at: b.startsAt ? new Date(b.startsAt) : null, ends_at: b.endsAt ? new Date(b.endsAt) : null }).executeTakeFirstOrThrow()).insertId);
      await tx.insertInto('banner_translations').values(b.translations.map((t) => ({ cafe_id: tenantId(), banner_id: id, language_code: t.language, title: t.title, subtitle: t.subtitle ?? null }))).execute();
      return { publicId };
    });
  }

  async deleteBanner(publicId: string) {
    const r = await this.db.q.updateTable('banners').set({ deleted_at: new Date() }).where('cafe_id', '=', tenantId()).where('public_id', '=', publicId).executeTakeFirst();
    if (!r.numUpdatedRows) throw notFound();
    return { ok: true };
  }
}
