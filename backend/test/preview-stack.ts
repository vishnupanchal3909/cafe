// A throwaway copy of Tea Hub with photos and sample orders, plus a platform admin, for looking at the design in all four apps.
// Never touches the dev database.
import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { adminConnection, bootstrap } from './harness';
import { hashPassword, totp } from '../src/modules/identity/crypto';

async function main() {
  const { app, api } = await bootstrap();
  const { seedTeaHub, STAFF } = await import('./seed-tea-hub-lib');
  const { applyDemoPhotos } = await import('./seed-demo-photos-lib');
  const owner = { email: 'owner@preview.test', password: 'owner password long' };
  const reg = await api.ok(api.post('/public/cafes/register', { owner: { ...owner, fullName: 'Preview Owner' }, cafe: { name: 'Tea Hub', legalName: 'Tea Hub', countryCode: 'IN', currencyCode: 'INR', defaultLanguage: 'en', timezone: 'Asia/Kolkata' }, branch: { name: 'Tea Hub', addressLine1: '1 Road', city: 'Pune' } }));
  const conn = await adminConnection();
  await conn.query(`UPDATE cafes SET status = 'active' WHERE public_id = ?`, [reg.cafePublicId]);
  const admin = { email: 'admin@preview.test', password: 'admin password long' };
  const [u]: any = await conn.query(`INSERT INTO users SET public_id = 'PREVIEWADMINPREVIEWADMIN1', email = ?, password_hash = ?, full_name = 'Admin', status = 'active', is_platform_user = 1`, [admin.email, await hashPassword(admin.password)]);
  await conn.query(`INSERT INTO user_roles (user_id, role_id) SELECT ?, id FROM roles WHERE code = 'super_admin' AND cafe_id IS NULL`, [u.insertId]);
  await conn.end();
  // Platform sign-in requires a second factor, so the browser check types a code from this secret.
  const first = await api.ok(api.post('/auth/login', { ...admin, audience: 'platform' }));
  const { secret: adminTotpSecret } = await api.ok(api.post('/auth/mfa/enroll', {}, { token: first.accessToken }));
  await api.ok(api.post('/auth/mfa/confirm', { code: totp(adminTotpSecret) }, { token: first.accessToken }));
  await seedTeaHub(app, reg.slug);
  await applyDemoPhotos(app, reg.slug, join(__dirname, '..', '..', '..', '.devdata', 'demo-photos'));
  const token = (await api.ok(api.post('/auth/login', { ...owner, audience: 'cafe' }))).accessToken;
  const auth = { token, branch: reg.branchPublicId };
  for (const t of ['T01', 'T02', 'T03', 'T04', 'T05', 'T06']) await api.ok(api.post('/cafe/tables', { tableNumber: t, capacity: 4 }, auth));
  const menu = await api.ok(api.get(`/public/cafes/${reg.slug}/menu?lang=en`));
  const pid = (n: string) => menu.products.find((p: any) => p.name === n).publicId;
  const tables = await api.ok(api.get('/cafe/tables', auth));
  const plan: Array<[string, number, string[]]> = [['Cappuccino', 2, ['accepted', 'preparing', 'ready', 'served']], ['Vada Pav', 3, ['accepted', 'preparing', 'ready']], ['Chocolate Brownie', 2, ['accepted', 'preparing']], ['Gulab Jamun', 1, []], ['Green Tea', 1, ['accepted']], ['Veg Samosa', 4, ['accepted', 'preparing', 'ready', 'served']]];
  for (const [i, [name, quantity, steps]] of plan.entries()) {
    const o = await api.ok(api.post('/cafe/orders', { tableId: tables[i].public_id, items: [{ productId: pid(name), quantity }] }, auth));
    for (const status of steps) await api.ok(api.post(`/cafe/orders/${o.publicId}/status`, { status }, auth));
    if (i === 0 || i === 5) await api.ok(api.post('/cafe/payments/cash', { orderId: o.publicId }, { ...auth, key: `preview-${i}` }));
    if (i === 5) await api.ok(api.post(`/cafe/orders/${o.publicId}/status`, { status: 'completed' }, auth));
  }
  const qr = await api.ok(api.get(`/cafe/tables/${tables[0].public_id}/qr`, auth));
  writeFileSync(process.env.FIXTURE_FILE!, JSON.stringify({ owner, staff: STAFF, admin, adminTotpSecret, qrToken: qr.url.split('/t/')[1] }));
  console.log('PREVIEW READY');
}
main().catch((e) => { console.error(e); process.exit(1); });
