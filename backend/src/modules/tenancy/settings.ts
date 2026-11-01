import { Q } from '../../infra/db/db.service';
import { tenantId } from '../../common/context';

// Every cafe rule that varies by business. Defaults are neutral; none assumes a country.
export interface CafeSettings {
  pricesIncludeTax: boolean;
  paymentPolicy: 'prepay' | 'postpay';
  taxRounding: 'line' | 'invoice';
  requireStaffAcceptance: boolean;
  cashRoundingIncrement: string | null;
  serviceChargePercent: string;
  guestOrderingEnabled: boolean;
  sessionHours: number;
  stockDeductionEnabled: boolean;
  invoiceSeries: string;
}
export const DEFAULT_SETTINGS: CafeSettings = {
  pricesIncludeTax: false, paymentPolicy: 'postpay', taxRounding: 'line', requireStaffAcceptance: true, cashRoundingIncrement: null,
  serviceChargePercent: '0', guestOrderingEnabled: true, sessionHours: 6, stockDeductionEnabled: true, invoiceSeries: 'INV',
};
export async function loadSettings(q: Q): Promise<CafeSettings> {
  const rows = await q.selectFrom('cafe_settings').select(['setting_key', 'value']).where('cafe_id', '=', tenantId()).execute();
  const out: Record<string, unknown> = { ...DEFAULT_SETTINGS };
  for (const r of rows) if (r.setting_key in DEFAULT_SETTINGS) out[r.setting_key] = r.value;
  return out as unknown as CafeSettings;
}

// Finds a usable translation: requested language, then cafe default, then whatever exists.
export function pickTranslation<T extends { language_code: string }>(rows: T[], lang: string, fallback: string): T | undefined {
  return rows.find((r) => r.language_code === lang) ?? rows.find((r) => r.language_code === fallback) ?? rows[0];
}
