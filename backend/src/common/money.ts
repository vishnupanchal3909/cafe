import Decimal from 'decimal.js';

Decimal.set({ precision: 40, rounding: Decimal.ROUND_HALF_UP });

export { Decimal };
export const D = (v: Decimal.Value) => new Decimal(v);
export const ZERO = new Decimal(0);

// Round to the currency's real precision: 2 for INR, 0 for JPY.
export const roundTo = (v: Decimal.Value, minorUnit: number) => new Decimal(v).toDecimalPlaces(minorUnit, Decimal.ROUND_HALF_UP);
export const dbMoney = (v: Decimal.Value) => new Decimal(v).toFixed(4);
export const money = (v: Decimal.Value, currency: string) => ({ amount: new Decimal(v).toString(), currency });

export function assertPrecision(v: Decimal.Value, minorUnit: number): boolean {
  return new Decimal(v).decimalPlaces() <= minorUnit;
}

// Largest-remainder split so parts always sum to the total exactly.
export function allocate(total: Decimal, weights: Decimal[], minorUnit: number): Decimal[] {
  const sum = weights.reduce((a, b) => a.plus(b), ZERO);
  if (sum.isZero()) return weights.map(() => ZERO);
  const raw = weights.map((w) => total.times(w).div(sum));
  const parts = raw.map((r) => r.toDecimalPlaces(minorUnit, Decimal.ROUND_DOWN));
  let remainder = total.minus(parts.reduce((a, b) => a.plus(b), ZERO));
  const unit = new Decimal(10).pow(-minorUnit);
  const order = raw.map((r, i) => ({ i, frac: r.minus(parts[i]!) })).sort((a, b) => b.frac.comparedTo(a.frac));
  for (const { i } of order) {
    if (remainder.lt(unit)) break;
    parts[i] = parts[i]!.plus(unit);
    remainder = remainder.minus(unit);
  }
  return parts;
}
