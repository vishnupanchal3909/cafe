import { Injectable } from '@nestjs/common';
import { sql } from 'kysely';
import { store, tenantId, unscoped } from '../../common/context';
import { D, ZERO } from '../../common/money';
import { audit, Db } from '../../infra/db/db.service';
import { localClock } from '../ordering/pricing';

// Every number is a query over recorded rows. Nothing is projected or estimated, and empty data stays empty.
@Injectable()
export class AnalyticsService {
  constructor(private readonly db: Db) {}

  private branch() {
    const b = store()?.branchId;
    const allowed = store()?.principal?.branchIds;
    if (b) return sql`AND o.branch_id = ${b}`;
    if (allowed?.length) return sql`AND o.branch_id IN (${sql.join(allowed)})`;
    return sql``;
  }

  async cafeDashboard(from: string, to: string) {
    const c = tenantId();
    const b = this.branch();
    const q = this.db.q;
    const [totals, trend, top, low, categories, hours, retention, timing, kitchen, consumption] = await Promise.all([
      sql<Record<string, string>>`SELECT COUNT(*) AS orders, SUM(o.status = 'cancelled') AS cancelled, COALESCE(SUM(IF(o.status <> 'cancelled', o.total_amount, 0)),0) AS revenue, COALESCE(AVG(IF(o.status <> 'cancelled', o.total_amount, NULL)),0) AS average_order_value FROM orders o WHERE o.cafe_id = ${c} AND o.business_date BETWEEN ${from} AND ${to} ${b}`.execute(q),
      sql<Record<string, string>>`SELECT o.business_date AS date, COUNT(*) AS orders, SUM(o.total_amount) AS revenue FROM orders o WHERE o.cafe_id = ${c} AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY o.business_date ORDER BY o.business_date`.execute(q),
      sql<Record<string, string>>`SELECT i.name_snapshot AS name, SUM(i.quantity) AS quantity, SUM(i.line_total_amount) AS revenue FROM order_items i JOIN orders o ON o.id = i.order_id AND o.cafe_id = i.cafe_id WHERE i.cafe_id = ${c} AND i.status = 'active' AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY i.product_id, i.name_snapshot ORDER BY quantity DESC LIMIT 10`.execute(q),
      sql<Record<string, string>>`SELECT i.name_snapshot AS name, SUM(i.quantity) AS quantity, SUM(i.line_total_amount) AS revenue FROM order_items i JOIN orders o ON o.id = i.order_id AND o.cafe_id = i.cafe_id WHERE i.cafe_id = ${c} AND i.status = 'active' AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY i.product_id, i.name_snapshot ORDER BY quantity ASC LIMIT 10`.execute(q),
      sql<Record<string, string>>`SELECT p.category_id, COALESCE(MAX(t.name), '') AS name, SUM(i.quantity) AS quantity, SUM(i.line_total_amount) AS revenue FROM order_items i JOIN orders o ON o.id = i.order_id AND o.cafe_id = i.cafe_id JOIN products p ON p.id = i.product_id AND p.cafe_id = i.cafe_id LEFT JOIN category_translations t ON t.category_id = p.category_id AND t.language_code = o.language_code WHERE i.cafe_id = ${c} AND i.status = 'active' AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY p.category_id ORDER BY revenue DESC`.execute(q),
      // Bucketed here and converted in Node: CONVERT_TZ returns NULL on servers without timezone tables,
      // and a 15-minute bucket keeps half-hour zones such as Asia/Kolkata in the right hour.
      sql<{ tz: string; bucket: number; orders: number }>`SELECT COALESCE(NULLIF(br.timezone,''), caf.timezone) AS tz, FLOOR(UNIX_TIMESTAMP(o.placed_at) / 900) AS bucket, COUNT(*) AS orders FROM orders o JOIN cafe_branches br ON br.id = o.branch_id AND br.cafe_id = o.cafe_id JOIN cafes caf ON caf.id = o.cafe_id WHERE o.cafe_id = ${c} AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY tz, bucket`.execute(q),
      sql<Record<string, string>>`SELECT COUNT(*) AS customers, SUM(n >= 2) AS repeat_customers FROM (SELECT o.customer_id, COUNT(*) AS n FROM orders o WHERE o.cafe_id = ${c} AND o.customer_id IS NOT NULL AND o.status <> 'cancelled' AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY o.customer_id) x`.execute(q),
      sql<Record<string, string>>`SELECT AVG(TIMESTAMPDIFF(SECOND, o.placed_at, o.completed_at)) / 60 AS avg_completion_minutes FROM orders o WHERE o.cafe_id = ${c} AND o.status = 'completed' AND o.business_date BETWEEN ${from} AND ${to} ${b}`.execute(q),
      sql<Record<string, string>>`SELECT s.name AS station, COUNT(*) AS tickets, AVG(TIMESTAMPDIFF(SECOND, k.created_at, k.ready_at)) / 60 AS avg_minutes FROM kitchen_orders k LEFT JOIN kitchen_stations s ON s.id = k.station_id JOIN orders o ON o.id = k.order_id AND o.cafe_id = k.cafe_id WHERE k.cafe_id = ${c} AND k.ready_at IS NOT NULL AND o.business_date BETWEEN ${from} AND ${to} ${b} GROUP BY s.id, s.name`.execute(q),
      sql<Record<string, string>>`SELECT g.name, g.unit_code, ABS(SUM(m.quantity)) AS consumed, ABS(SUM(m.quantity * m.unit_cost)) AS cost FROM stock_movements m JOIN ingredients g ON g.id = m.ingredient_id WHERE m.cafe_id = ${c} AND m.movement_type IN ('sale_consumption','sale_reversal') AND DATE(m.occurred_at) BETWEEN ${from} AND ${to} GROUP BY g.id, g.name, g.unit_code ORDER BY cost DESC LIMIT 20`.execute(q),
    ]);
    const t = totals.rows[0]!;
    const orders = Number(t.orders ?? 0);
    const r = retention.rows[0]!;
    return {
      from, to, currency: (await q.selectFrom('cafes').select('currency_code').where('id', '=', c).executeTakeFirstOrThrow()).currency_code,
      orders, revenue: t.revenue, averageOrderValue: D(t.average_order_value ?? 0).toFixed(4), cancellationRate: orders ? D(t.cancelled ?? 0).div(orders).times(100).toFixed(2) : null,
      revenueTrend: trend.rows.map((x) => ({ ...x, date: new Date(x.date!).toISOString().slice(0, 10) })), topProducts: top.rows, lowProducts: low.rows, categories: categories.rows, peakHours: this.toLocalHours(hours.rows),
      customers: Number(r.customers ?? 0), repeatCustomers: Number(r.repeat_customers ?? 0), avgCompletionMinutes: timing.rows[0]?.avg_completion_minutes ?? null, kitchen: kitchen.rows, consumption: consumption.rows,
    };
  }

  private toLocalHours(rows: Array<{ tz: string; bucket: number; orders: number }>) {
    const byHour = new Map<number, number>();
    for (const r of rows) {
      const hour = Number(localClock(new Date(Number(r.bucket) * 900_000), r.tz).time.slice(0, 2));
      byHour.set(hour, (byHour.get(hour) ?? 0) + Number(r.orders));
    }
    return [...byHour].sort(([a], [b]) => a - b).map(([local_hour, orders]) => ({ local_hour, orders }));
  }

  // Cross-tenant by nature. Each read of platform analytics is itself audited.
  async platformDashboard() {
    return unscoped('platform analytics', async () => {
      const q = this.db.q;
      const [cafes, customers, orders, byCurrency, byCountry, subs, growth, active] = await Promise.all([
        sql<Record<string, number>>`SELECT COUNT(*) AS total, SUM(status='active') AS active, SUM(status='pending_approval') AS pending, SUM(status='suspended') AS suspended, SUM(status IN ('closed','rejected')) AS inactive FROM cafes`.execute(q),
        sql<Record<string, number>>`SELECT COUNT(*) AS total FROM customers WHERE deleted_at IS NULL AND is_guest = 0`.execute(q),
        sql<Record<string, number>>`SELECT COUNT(*) AS total, SUM(status='cancelled') AS cancelled FROM orders`.execute(q),
        sql<Record<string, string>>`SELECT currency_code, COUNT(*) AS orders, SUM(total_amount) AS gross FROM orders WHERE status <> 'cancelled' GROUP BY currency_code ORDER BY currency_code`.execute(q),
        sql<Record<string, string>>`SELECT country_code, COUNT(*) AS cafes FROM cafes GROUP BY country_code ORDER BY cafes DESC`.execute(q),
        sql<Record<string, number>>`SELECT SUM(status IN ('active','trialing')) AS active, SUM(status IN ('past_due','grace')) AS at_risk, SUM(status IN ('cancelled','expired')) AS churned FROM cafe_subscriptions`.execute(q),
        sql<Record<string, string>>`SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, COUNT(*) AS cafes FROM cafes GROUP BY month ORDER BY month DESC LIMIT 12`.execute(q),
        sql<Record<string, number>>`SELECT COUNT(DISTINCT user_id) AS staff, COUNT(DISTINCT customer_id) AS customers FROM login_sessions WHERE last_seen_at >= UTC_TIMESTAMP() - INTERVAL 30 DAY AND revoked_at IS NULL`.execute(q),
      ]);
      const revenue = await sql<Record<string, string>>`SELECT currency_code, direction, SUM(amount) AS total FROM platform_transactions GROUP BY currency_code, direction`.execute(q);
      const platformRevenue = new Map<string, ReturnType<typeof D>>();
      for (const r of revenue.rows) platformRevenue.set(r.currency_code!, (platformRevenue.get(r.currency_code!) ?? ZERO).plus(r.direction === 'credit' ? r.total! : D(r.total!).neg()));
      await audit(q, { action: 'platform.analytics_read', cafeId: null });
      return {
        cafes: cafes.rows[0], customers: Number(customers.rows[0]?.total ?? 0), orders: orders.rows[0], grossByCurrency: byCurrency.rows, cafesByCountry: byCountry.rows, subscriptions: subs.rows[0], cafeGrowth: growth.rows.reverse(), activeUsers: active.rows[0],
        // Per currency on purpose: consolidation needs an explicit rate, see consolidated().
        platformRevenue: [...platformRevenue].map(([currency, amount]) => ({ currency, amount: amount.toString() })),
      };
    });
  }

  // Converts with a stored rate and reports the rate used. A missing rate is shown as missing, never guessed.
  async consolidated(reporting: string, asOf: string) {
    return unscoped('platform analytics', async () => {
      const totals = await sql<{ currency_code: string; gross: string }>`SELECT currency_code, SUM(total_amount) AS gross FROM orders WHERE status <> 'cancelled' AND business_date <= ${asOf} GROUP BY currency_code`.execute(this.db.q);
      let total = ZERO;
      const lines = [];
      const missing: string[] = [];
      for (const t of totals.rows) {
        if (t.currency_code === reporting) { lines.push({ currency: t.currency_code, original: t.gross, rate: '1', provider: null, effectiveAt: null, converted: t.gross }); total = total.plus(t.gross); continue; }
        const rate = await this.db.q.selectFrom('exchange_rates').select(['rate', 'provider', 'effective_at']).where('base_currency_code', '=', t.currency_code).where('quote_currency_code', '=', reporting).where('effective_at', '<=', new Date(`${asOf}T23:59:59Z`)).orderBy('effective_at', 'desc').executeTakeFirst();
        if (!rate) { missing.push(t.currency_code); lines.push({ currency: t.currency_code, original: t.gross, rate: null, provider: null, effectiveAt: null, converted: null }); continue; }
        const converted = D(t.gross).times(rate.rate);
        total = total.plus(converted);
        lines.push({ currency: t.currency_code, original: t.gross, rate: rate.rate, provider: rate.provider, effectiveAt: rate.effective_at, converted: converted.toFixed(4) });
      }
      return { reportingCurrency: reporting, asOf, lines, total: total.toFixed(4), isComplete: missing.length === 0, missingRates: missing };
    });
  }
}
