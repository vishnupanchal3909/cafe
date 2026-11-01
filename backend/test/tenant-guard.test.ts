import assert from 'node:assert/strict';
import { test } from 'node:test';
import { als, asTenant, unscoped } from '../src/common/context';
import { assertTenantScoped, TenantGuardViolation } from '../src/infra/db/guard-driver';

const ctx = (cafeId?: number) => ({ requestId: 'r', lang: 'en', cafeId });
const SELECT = 'select * from `orders` where `cafe_id` = ? and `id` = ?';

test('a tenant query with no tenant in context is refused', () => {
  assert.throws(() => assertTenantScoped(SELECT, [1, 2]), TenantGuardViolation);
});
test('a query forgetting cafe_id is refused', () => {
  als.run(ctx(7), () => assert.throws(() => assertTenantScoped('select * from `orders` where `id` = ?', [7]), TenantGuardViolation));
});
test("a query bound to a different cafe's id is refused", () => {
  als.run(ctx(7), () => assert.throws(() => assertTenantScoped(SELECT, [8, 2]), TenantGuardViolation));
});
test('a properly scoped query passes', () => {
  als.run(ctx(7), () => assertTenantScoped(SELECT, [7, 2]));
});
test('global tables are not guarded', () => {
  assertTenantScoped('select * from `currencies`', []);
});
test('unscoped requires an explicit reason, and asTenant restores the guard inside it', async () => {
  await unscoped('sweep', async () => {
    assertTenantScoped(SELECT, [1, 2]);
    await asTenant(7, async () => assert.throws(() => assertTenantScoped(SELECT, [1, 2]), TenantGuardViolation));
  });
});
