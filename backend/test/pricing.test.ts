import assert from 'node:assert/strict';
import { test } from 'node:test';
import { allocate, D } from '../src/common/money';
import { businessDate, priceOrder } from '../src/modules/ordering/pricing';

const gst = [{ code: 'CGST', name: 'CGST', ratePercent: '2.5' }, { code: 'SGST', name: 'SGST', ratePercent: '2.5' }];
const opts = { minorUnit: 2, pricesIncludeTax: false, taxRounding: 'line' as const };
const line = (unitPrice: string, quantity = 1, taxes = gst, addonsPerUnit = '0') => ({ unitPrice, addonsPerUnit, quantity, taxes });

test('exclusive tax adds on top, with a per-component breakdown', () => {
  const p = priceOrder([line('100.00', 2)], opts);
  assert.equal(p.subtotal.toString(), '200');
  assert.equal(p.tax.toString(), '10');
  assert.equal(p.total.toString(), '210');
  assert.deepEqual(p.lines[0]!.taxes.map((t) => t.amount.toString()), ['5', '5']);
});

test('inclusive tax is carved out of the price; total equals the menu price', () => {
  const p = priceOrder([line('105.00')], { ...opts, pricesIncludeTax: true });
  assert.equal(p.total.toString(), '105');
  assert.equal(p.tax.toString(), '5');
  assert.equal(p.lines[0]!.taxable.toString(), '100');
});

test('JPY uses zero decimals throughout', () => {
  const p = priceOrder([line('333', 1, [{ code: 'CT', name: 'CT', ratePercent: '10' }])], { ...opts, minorUnit: 0 });
  assert.equal(p.tax.toString(), '33');
  assert.equal(p.total.toString(), '366');
});

test('no float drift: 0.1 + 0.2 style sums are exact', () => {
  const p = priceOrder([line('0.10', 1, []), line('0.20', 1, [])], opts);
  assert.equal(p.total.toString(), '0.3');
});

test('an order discount is allocated so lines sum exactly to the total', () => {
  const p = priceOrder([line('33.33'), line('33.33'), line('33.34')], { ...opts, orderDiscount: D('10.00') });
  assert.equal(p.discount.toString(), '10');
  const sumLines = p.lines.reduce((a, l) => a.plus(l.total), D(0));
  assert.equal(sumLines.toString(), p.total.toString());
  assert.equal(p.tax.plus(p.subtotal).minus(p.discount).toString(), p.total.toString());
});

test('a discount can never take an order below zero', () => {
  const p = priceOrder([line('10.00')], { ...opts, orderDiscount: D('50') });
  assert.equal(p.discount.toString(), '10');
  assert.equal(p.total.toString(), '0');
});

test('invoice-level rounding: total tax matches rounding once, and lines still sum', () => {
  const lines = Array.from({ length: 3 }, () => line('0.33', 1, [{ code: 'V', name: 'V', ratePercent: '5' }]));
  const perLine = priceOrder(lines, opts);
  const perInvoice = priceOrder(lines, { ...opts, taxRounding: 'invoice' });
  assert.equal(perLine.tax.toString(), '0.06');
  assert.equal(perInvoice.tax.toString(), '0.05');
  assert.equal(perInvoice.lines.reduce((a, l) => a.plus(l.tax), D(0)).toString(), '0.05');
});

test('addons multiply by quantity', () => {
  const p = priceOrder([line('100.00', 3, [], '10.00')], opts);
  assert.equal(p.subtotal.toString(), '330');
});

test('allocate: parts always sum exactly', () => {
  for (const [total, n] of [['100', 3], ['0.01', 7], ['999.99', 13]] as const) {
    const parts = allocate(D(total), Array.from({ length: n }, () => D(1)), 2);
    assert.equal(parts.reduce((a, b) => a.plus(b), D(0)).toString(), D(total).toString());
  }
});

test('business date: after midnight but before cutoff still counts as yesterday', () => {
  // 01:30 in Kolkata on the 2nd is 20:00 UTC on the 1st.
  assert.equal(businessDate(new Date('2026-06-01T20:00:00Z'), 'Asia/Kolkata', '04:00:00'), '2026-06-01');
  // 05:00 in Kolkata on the 2nd.
  assert.equal(businessDate(new Date('2026-06-01T23:30:00Z'), 'Asia/Kolkata', '04:00:00'), '2026-06-02');
  // Same instant, a different cafe, different day: New York is still on the 1st.
  assert.equal(businessDate(new Date('2026-06-01T23:30:00Z'), 'America/New_York', '04:00:00'), '2026-06-01');
});
