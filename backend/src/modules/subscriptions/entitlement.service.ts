import { Injectable } from '@nestjs/common';
import { tenantId } from '../../common/context';
import { AppError } from '../../common/errors';
import { Q } from '../../infra/db/db.service';

const monthStart = () => { const d = new Date(); return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), 1)); };

// Limits come only from plan_entitlements, configured by the Super Admin. A cafe without a subscription is not limited,
// because pricing and plan activation are still an open business decision (D-3).
@Injectable()
export class EntitlementService {
  async currentPlan(q: Q): Promise<number | null> {
    const s = await q.selectFrom('cafe_subscriptions').select(['plan_id', 'status']).where('cafe_id', '=', tenantId()).where('status', 'in', ['trialing', 'active', 'past_due', 'grace']).orderBy('id', 'desc').executeTakeFirst();
    return s?.plan_id ?? null;
  }

  async featureEnabled(q: Q, feature: string): Promise<boolean> {
    const plan = await this.currentPlan(q);
    if (!plan) return true;
    const e = await q.selectFrom('plan_entitlements').select('is_enabled').where('plan_id', '=', plan).where('feature_key', '=', feature).executeTakeFirst();
    return e ? !!e.is_enabled : true;
  }

  async assertFeature(q: Q, feature: string) {
    if (!(await this.featureEnabled(q, feature))) throw new AppError(402, 'PLAN_FEATURE_UNAVAILABLE', { feature });
  }

  async assertWithinLimit(q: Q, feature: string, adding: number, currentCount?: number) {
    const plan = await this.currentPlan(q);
    if (!plan) return;
    const e = await q.selectFrom('plan_entitlements').selectAll().where('plan_id', '=', plan).where('feature_key', '=', feature).executeTakeFirst();
    if (!e) return;
    if (!e.is_enabled) throw new AppError(402, 'PLAN_FEATURE_UNAVAILABLE', { feature });
    if (e.limit_value === null) return;
    const used = currentCount ?? Number((await q.selectFrom('cafe_usage_counters').select('value').where('cafe_id', '=', tenantId()).where('feature_key', '=', feature).where('period_start', '=', monthStart()).executeTakeFirst())?.value ?? 0);
    if (used + adding > Number(e.limit_value)) throw new AppError(402, 'PLAN_LIMIT_REACHED', { feature, limit: Number(e.limit_value) });
  }

  async incrementUsage(q: Q, feature: string) {
    await q.insertInto('cafe_usage_counters').values({ cafe_id: tenantId(), feature_key: feature, period_start: monthStart(), value: 1 })
      .onDuplicateKeyUpdate((eb) => ({ value: eb('value', '+', 1) })).execute();
  }
}
