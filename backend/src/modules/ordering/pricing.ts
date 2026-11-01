import { allocate, D, Decimal, roundTo, ZERO } from '../../common/money';

export interface TaxRateInput { code: string; name: string; ratePercent: string }
export interface LineInput { unitPrice: string; addonsPerUnit: string; quantity: number; lineDiscount?: string; taxes: TaxRateInput[] }
export interface PricedTax { code: string; name: string; ratePercent: string; taxable: Decimal; amount: Decimal }
export interface PricedLine { gross: Decimal; discount: Decimal; tax: Decimal; total: Decimal; taxable: Decimal; taxes: PricedTax[] }
export interface PricedOrder { lines: PricedLine[]; subtotal: Decimal; discount: Decimal; tax: Decimal; serviceCharge: Decimal; deliveryFee: Decimal; total: Decimal }

export interface PricingOptions {
  minorUnit: number;
  pricesIncludeTax: boolean;
  taxRounding: 'line' | 'invoice';
  orderDiscount?: Decimal;
  serviceChargePercent?: string;
  deliveryFee?: string;
}

// Pure and deterministic: the only place an order total is computed. Client-sent prices never reach it.
export function priceOrder(inputs: LineInput[], o: PricingOptions): PricedOrder {
  const m = o.minorUnit;
  const gross = inputs.map((l) => D(l.unitPrice).plus(l.addonsPerUnit).times(l.quantity));
  const lineDisc = inputs.map((l, i) => Decimal.min(D(l.lineDiscount ?? 0), gross[i]!));
  const afterLine = gross.map((g, i) => g.minus(lineDisc[i]!));
  const sumAfter = afterLine.reduce((a, b) => a.plus(b), ZERO);
  const orderDisc = Decimal.min(roundTo(o.orderDiscount ?? 0, m), sumAfter);
  const allocated = allocate(orderDisc, afterLine, m);
  const net = afterLine.map((n, i) => n.minus(allocated[i]!));

  // Exact, unrounded tax per line and component.
  const exact = inputs.map((l, i) => {
    const totalRate = l.taxes.reduce((a, t) => a.plus(t.ratePercent), ZERO);
    const base = o.pricesIncludeTax ? net[i]!.div(D(1).plus(totalRate.div(100))) : net[i]!;
    return l.taxes.map((t) => base.times(t.ratePercent).div(100));
  });

  let rounded: Decimal[][];
  if (o.taxRounding === 'line') {
    rounded = exact.map((taxes) => taxes.map((t) => roundTo(t, m)));
  } else {
    // Round each component once across the order, then spread it back so lines still sum exactly.
    rounded = exact.map((taxes) => taxes.map(() => ZERO));
    const codes = new Set(inputs.flatMap((l) => l.taxes.map((t) => t.code)));
    for (const code of codes) {
      const cells: Array<[number, number]> = [];
      inputs.forEach((l, i) => l.taxes.forEach((t, j) => { if (t.code === code) cells.push([i, j]); }));
      const weights = cells.map(([i, j]) => exact[i]![j]!);
      const parts = allocate(roundTo(weights.reduce((a, b) => a.plus(b), ZERO), m), weights, m);
      cells.forEach(([i, j], k) => { rounded[i]![j] = parts[k]!; });
    }
  }

  const lines: PricedLine[] = inputs.map((l, i) => {
    const tax = rounded[i]!.reduce((a, b) => a.plus(b), ZERO);
    const lineNet = roundTo(net[i]!, m);
    const taxable = o.pricesIncludeTax ? lineNet.minus(tax) : lineNet;
    return {
      gross: roundTo(gross[i]!, m), discount: lineDisc[i]!.plus(allocated[i]!), tax, taxable, total: o.pricesIncludeTax ? lineNet : lineNet.plus(tax),
      taxes: l.taxes.map((t, j) => ({ code: t.code, name: t.name, ratePercent: t.ratePercent, taxable, amount: rounded[i]![j]! })),
    };
  });

  const sum = (f: (l: PricedLine) => Decimal) => lines.reduce((a, l) => a.plus(f(l)), ZERO);
  const netTotal = sum((l) => l.gross.minus(l.discount));
  const serviceCharge = roundTo(netTotal.times(o.serviceChargePercent ?? 0).div(100), m);
  const deliveryFee = roundTo(o.deliveryFee ?? 0, m);
  return {
    lines, subtotal: sum((l) => l.gross), discount: sum((l) => l.discount), tax: sum((l) => l.tax), serviceCharge, deliveryFee,
    total: sum((l) => l.total).plus(serviceCharge).plus(deliveryFee),
  };
}

// The trading day of a moment in a branch's timezone. Before the cutoff still counts as yesterday.
export function businessDate(now: Date, timezone: string, cutoff: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', { timeZone: timezone, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' }).formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)!.value;
  const local = `${get('hour')}:${get('minute')}:${get('second')}`;
  const date = new Date(Date.UTC(+get('year'), +get('month') - 1, +get('day')));
  if (local < cutoff.padEnd(8, ':00')) date.setUTCDate(date.getUTCDate() - 1);
  return date.toISOString().slice(0, 10);
}

export function localClock(now: Date, timezone: string): { weekday: number; time: string } {
  const parts = new Intl.DateTimeFormat('en-US', { timeZone: timezone, weekday: 'short', hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23' }).formatToParts(now);
  const get = (t: string) => parts.find((p) => p.type === t)!.value;
  return { weekday: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].indexOf(get('weekday')), time: `${get('hour')}:${get('minute')}:${get('second')}` };
}
