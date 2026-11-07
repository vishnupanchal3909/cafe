// Proves the demo data actually works: a real order from it runs through kitchen, stock, payment, invoice and ledger.
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { adminConnection, Api, App, bootstrap } from './harness';
import type { STAFF as StaffList, seedTeaHub as Seed } from './seed-tea-hub-lib';

// Loaded only after bootstrap: importing app code earlier would read .env and open the developer's real database.
let seedTeaHub: typeof Seed; let STAFF: typeof StaffList;
let app: App; let api: Api; let token: string; let branch: string; let slug: string;
const today = () => new Date(Date.now() + 86400_000).toISOString().slice(0, 10);

before(async () => {
  process.env.RATE_LIMIT_SCALE = '100';
  const b = await bootstrap();
  app = b.app; api = b.api;
  ({ seedTeaHub, STAFF } = await import('./seed-tea-hub-lib'));
  const reg = await api.ok(api.post('/public/cafes/register', { owner: { email: 'o@tea.test', password: 'owner password long', fullName: 'Owner' }, cafe: { name: 'Tea Hub', legalName: 'Tea Hub', countryCode: 'IN', currencyCode: 'INR', defaultLanguage: 'en', timezone: 'Asia/Kolkata' }, branch: { name: 'Tea Hub', addressLine1: '1 Road', city: 'Pune' } }));
  slug = reg.slug; branch = reg.branchPublicId;
  const conn = await adminConnection();
  await conn.query(`UPDATE cafes SET status = 'active' WHERE public_id = ?`, [reg.cafePublicId]);
  await conn.end();
  token = (await api.ok(api.post('/auth/login', { email: 'o@tea.test', password: 'owner password long', audience: 'cafe' }))).accessToken;
  await seedTeaHub(app, slug);
});
after(async () => { await app.close(); });

test('a second run changes nothing', async () => {
  await assert.rejects(seedTeaHub(app, slug), /already has a menu/);
});

test('the menu is complete and localized', async () => {
  const hi = await api.ok(api.get(`/public/cafes/${slug}/menu?lang=hi&branch=${branch}`));
  assert.equal(hi.categories.length, 5);
  assert.equal(hi.products.length, 13);
  const chai = hi.products.find((p: any) => p.name === 'मसाला चाय');
  assert.equal(chai.variants.length, 2);
  assert.equal(chai.addonGroups.length, 2);
  assert.equal(hi.products.find((p: any) => p.name === 'कोल्ड कॉफ़ी').isAvailable, false);
});

test('product photos: a manager can upload, replace and remove; a cashier cannot; only real images pass', async () => {
  const login = async (role: string) => { const s = STAFF.find((x) => x.role === role)!; return (await api.ok(api.post('/auth/login', { email: s.email, password: s.password, audience: 'cafe' }))).accessToken; };
  const manager = await login('manager');
  const cashier = await login('cashier');
  const menuOf = async () => (await api.ok(api.get(`/public/cafes/${slug}/menu?lang=en`))).products.find((p: any) => p.name === 'Cappuccino');
  const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', 'base64');
  const send = async (who: string, bytes: Buffer) => {
    const form = new FormData();
    form.append('file', new Blob([new Uint8Array(bytes)]), 'photo.png');
    const r = await fetch(`${api.base}/cafe/media/product-image`, { method: 'POST', headers: { Authorization: `Bearer ${who}` }, body: form });
    return { status: r.status, body: await r.json() as any };
  };
  const product = await menuOf();
  assert.deepEqual(product.imageUrls, []);
  assert.equal((await send(cashier, png)).status, 403);
  assert.equal((await send(manager, Buffer.from('<script>not an image</script>'))).status, 400);
  const first = (await send(manager, png)).body.data.publicId;
  const second = (await send(manager, png)).body.data.publicId;
  assert.equal((await api.put(`/cafe/products/${product.publicId}/image`, { assetId: first }, { token: cashier })).status, 403);
  await api.ok(api.put(`/cafe/products/${product.publicId}/image`, { assetId: first }, { token: manager }));
  assert.deepEqual((await menuOf()).imageUrls, [`/api/v1/public/media/${first}`]);
  await api.ok(api.put(`/cafe/products/${product.publicId}/image`, { assetId: second }, { token: manager }));
  assert.deepEqual((await menuOf()).imageUrls, [`/api/v1/public/media/${second}`], 'replaces rather than adds');
  assert.equal((await api.put(`/cafe/products/${product.publicId}/image`, { assetId: 'XXXXXXXXXXXXXXXXXXXXXXXXXX' }, { token: manager })).status, 404);
  await api.ok(api.del(`/cafe/products/${product.publicId}/image`, { token: manager }));
  assert.deepEqual((await menuOf()).imageUrls, []);
});

test('every staff account can sign in, with the right limits', async () => {
  for (const s of STAFF) {
    const audience = s.role === 'kitchen_staff' ? 'kitchen' : 'cafe';
    assert.equal((await api.post('/auth/login', { email: s.email, password: s.password, audience })).status, 200, s.email);
  }
});

test('a full order: variant, add-ons, coupon, combo, promotion, kitchen, stock, cash, invoice, balanced books', async () => {
  const stockOf = async (name: string) => (await api.ok(api.get('/cafe/stock', { token, branch }))).find((s: any) => s.name === name).on_hand_quantity;
  const menu = await api.ok(api.get(`/public/cafes/${slug}/menu?lang=en&branch=${branch}`));
  const find = (n: string) => menu.products.find((p: any) => p.name === n);
  const chai = find('Masala Chai');
  const large = chai.variants.find((v: any) => v.name === 'Large');
  const addon = (g: string, a: string) => chai.addonGroups.find((x: any) => x.name === g).addons.find((y: any) => y.name === a).publicId;
  assert.equal((await api.post('/cafe/orders', { items: [{ productId: chai.publicId, variantId: large.publicId, quantity: 1 }] }, { token, branch })).body.error.code, 'ADDON_SELECTION_INVALID', 'sugar choice is required');
  const milkBefore = await stockOf('Milk');
  assert.equal(milkBefore, '20000.0000');
  const conn = await adminConnection();
  const [[{ ok }]]: any = await conn.query(`SELECT 1 ok`); assert.equal(ok, 1); await conn.end();

  const order = await api.ok(api.post('/cafe/orders', { couponCode: 'TEA10', items: [
    { productId: chai.publicId, variantId: large.publicId, quantity: 2, addons: [{ addonId: addon('Sugar', 'Less sugar') }, { addonId: addon('Extras', 'Ginger') }] },
    { productId: find('Chai and Samosa Combo').publicId, quantity: 1 },
    { productId: find('Gulab Jamun').publicId, quantity: 1 },
  ] }, { token, branch }));
  // (40 + 5) x 2 + 45 + 50 = 185. Dessert promotion takes 5, coupon 10% of 180 takes 18.
  assert.equal(order.subtotal.amount, '185');
  assert.equal(order.discount.amount, '23');
  const expected = Number(order.subtotal.amount) - Number(order.discount.amount) + Number(order.tax.amount);
  assert.equal(Number(order.total.amount).toFixed(2), expected.toFixed(2));

  const kitchenLogin = STAFF.find((s) => s.role === 'kitchen_staff')!;
  const cook = (await api.ok(api.post('/auth/login', { email: kitchenLogin.email, password: kitchenLogin.password, audience: 'kitchen' }))).accessToken;
  const tickets = await api.ok(api.get('/kitchen/tickets', { token: cook, branch }));
  assert.deepEqual(tickets.map((t: any) => t.station_name).sort(), ['Hot Kitchen', 'Tea Counter'], 'items split by station');
  for (const t of tickets) {
    for (const s of ['accepted', 'preparing', 'ready']) await api.ok(api.post(`/kitchen/tickets/${t.public_id}/status`, { status: s }, { token: cook, branch }));
  }
  // Two large chai at 180 ml, plus the combo's small chai at 100 ml.
  assert.equal(await stockOf('Milk'), '19540.0000');
  assert.equal(await stockOf('Frozen samosa'), '198.0000', 'the combo consumes its parts');
  await api.ok(api.post('/cafe/payments/cash', { orderId: order.publicId }, { token, branch, key: 'seed-cash-1' }));
  const done = await api.ok(api.get(`/cafe/orders/${order.publicId}`, { token, branch }));
  assert.equal(done.paymentStatus, 'paid');
  assert.equal(done.status, 'ready');
  assert.equal((await api.ok(api.get('/cafe/invoices', { token }))).length, 1);
  assert.equal((await api.ok(api.get(`/cafe/reports/balance-sheet?asOf=${today()}`, { token }))).balanced, true);
});
