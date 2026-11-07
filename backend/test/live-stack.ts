// A real running API with real data, for browser checks and the Dart contract test. Writes its ids to FIXTURE_FILE.
import { writeFileSync } from 'node:fs';
import { adminConnection, bootstrap } from './harness';
import { totp, hashPassword } from '../src/modules/identity/crypto';
import { KEY_ID, KEY_SECRET, RazorpayMock, WEBHOOK_SECRET } from './razorpay-mock';

async function main() {
  process.env.LIVE_PORT = process.env.LIVE_PORT ?? '3100';
  process.env.RUN_WORKERS = 'true';
  process.env.RATE_LIMIT_SCALE = '100';
  process.env.TEST_REDIS_URL = process.env.TEST_REDIS_URL ?? 'redis://127.0.0.1:6379';
  const mock = process.env.LIVE_RAZORPAY_MOCK ? await new RazorpayMock().start(Number(process.env.LIVE_RAZORPAY_MOCK)) : undefined;
  if (mock) process.env.RAZORPAY_API_BASE = mock.base;
  const { api } = await bootstrap();
  const conn = await adminConnection();
  const [u]: any = await conn.query(`INSERT INTO users SET public_id = 'ADMINADMINADMINADMINADMIN1', email = 'admin@example.test', password_hash = ?, full_name = 'Admin', status = 'active', is_platform_user = 1`, [await hashPassword('admin password long')]);
  await conn.query(`INSERT INTO user_roles (user_id, role_id) SELECT ?, id FROM roles WHERE code = 'super_admin' AND cafe_id IS NULL`, [u.insertId]);
  await conn.end();
  const a = await api.ok(api.post('/auth/login', { email: 'admin@example.test', password: 'admin password long', audience: 'platform' }));
  const { secret } = await api.ok(api.post('/auth/mfa/enroll', {}, { token: a.accessToken }));
  const adminToken = (await api.ok(api.post('/auth/mfa/confirm', { code: totp(secret) }, { token: a.accessToken }))).accessToken;

  const reg = await api.ok(api.post('/public/cafes/register', {
    owner: { email: 'owner@chai.test', password: 'owner password long', fullName: 'Asha Rao' },
    cafe: { name: 'Chai House', legalName: 'Chai House Pvt Ltd', countryCode: 'IN', currencyCode: 'INR', defaultLanguage: 'en', timezone: 'Asia/Kolkata', supportedLanguages: ['hi', 'ar', 'ja'] },
    branch: { name: 'Koregaon Park', addressLine1: '1 Lane 5', city: 'Pune', stateCode: 'MH' },
  }));
  await api.ok(api.post(`/platform/cafes/${reg.cafePublicId}/status`, { status: 'active', reason: 'live stack' }, { token: adminToken }));
  const token = (await api.ok(api.post('/auth/login', { email: 'owner@chai.test', password: 'owner password long', audience: 'cafe' }))).accessToken;
  const staff = { token, branch: reg.branchPublicId };
  await api.ok(api.put('/cafe/theme', { primaryColor: '#7B3F00', secondaryColor: '#E0A96D', menuLayout: 'list' }, { token }));
  await api.ok(api.post('/cafe/tax-categories', { code: 'FOOD', name: 'Food' }, { token }));
  for (const c of ['CGST', 'SGST']) await api.ok(api.post('/cafe/tax-categories/FOOD/rates', { componentCode: c, displayName: c, ratePercent: '2.5', appliesTo: 'intra_region', validFrom: '2020-01-01' }, { token }));
  const cat = await api.ok(api.post('/cafe/categories', { translations: [{ language: 'en', name: 'Hot drinks' }, { language: 'hi', name: 'गरम पेय' }, { language: 'ar', name: 'مشروبات ساخنة' }, { language: 'ja', name: 'ホットドリンク' }] }, { token }));
  const food = await api.ok(api.post('/cafe/categories', { translations: [{ language: 'en', name: 'Snacks' }, { language: 'hi', name: 'नाश्ता' }, { language: 'ar', name: 'وجبات خفيفة' }] }, { token }));
  const chai = await api.ok(api.post('/cafe/products', { categoryId: cat.publicId, basePrice: '100.00', taxCategoryId: 'FOOD', dietaryClass: 'veg', translations: [{ language: 'en', name: 'Masala Chai', description: 'Spiced milk tea' }, { language: 'hi', name: 'मसाला चाय', description: 'मसालेदार दूध वाली चाय' }, { language: 'ar', name: 'شاي ماسالا', description: 'شاي بالحليب والتوابل' }, { language: 'ja', name: 'マサラチャイ' }] }, { token }));
  const large = await api.ok(api.post(`/cafe/products/${chai.publicId}/variants`, { price: '150.00', isDefault: true, translations: [{ language: 'en', name: 'Large' }, { language: 'hi', name: 'बड़ा' }] }, { token }));
  await api.ok(api.post('/cafe/products', { categoryId: food.publicId, basePrice: '85.50', taxCategoryId: 'FOOD', dietaryClass: 'non_veg', translations: [{ language: 'en', name: 'Chicken Puff' }, { language: 'hi', name: 'चिकन पफ' }, { language: 'ar', name: 'فطيرة دجاج' }] }, { token }));
  await api.ok(api.post('/cafe/products', { categoryId: food.publicId, basePrice: '60', taxCategoryId: 'FOOD', dietaryClass: 'veg', translations: [{ language: 'en', name: 'Veg Samosa' }, { language: 'hi', name: 'वेज समोसा' }, { language: 'ar', name: 'سمبوسة' }] }, { token }));
  const group = await api.ok(api.post('/cafe/addon-groups', { maxSelect: 2, translations: [{ language: 'en', name: 'Extras' }, { language: 'hi', name: 'अतिरिक्त' }], addons: [{ price: '20.00', translations: [{ language: 'en', name: 'Ginger' }, { language: 'hi', name: 'अदरक' }] }] }, { token }));
  await api.ok(api.put(`/cafe/products/${chai.publicId}/addon-groups`, { ids: [group.publicId] }, { token }));
  const table = await api.ok(api.post('/cafe/tables', { tableNumber: 'T1', capacity: 4 }, staff));
  const qr = await api.ok(api.get(`/cafe/tables/${table.publicId}/qr`, staff));
  const invite = await api.ok(api.post('/cafe/staff', { email: 'cook@chai.test', fullName: 'Ravi', roleCode: 'kitchen_staff' }, { token }));
  await api.ok(api.post('/auth/accept-invitation', { token: invite.invitationToken, password: 'cook password long' }));

  const scan = await api.ok(api.get(`/public/qr/${qr.url.split('/t/')[1]}`));
  // Ordering needs a signed-in customer; the contract test signs in as this diner.
  const diner = { email: 'diner@chai.test', password: 'diner password long' };
  const dinerToken = (await api.ok(api.post('/customer/auth/register', { ...diner, fullName: 'Meena' }))).accessToken;
  const order = await api.ok(api.post('/customer/orders', { language: 'en', notes: 'less sugar', items: [{ productId: chai.publicId, variantId: large.publicId, quantity: 2, addons: [{ addonId: group.addons[0] }], notes: 'extra hot' }] }, { session: scan.session.token, token: dinerToken }));
  if (mock) {
    const account = await api.ok(api.put('/cafe/gateway-accounts', { providerCode: 'razorpay', environment: 'sandbox', keyId: KEY_ID, keySecret: KEY_SECRET, webhookSecret: WEBHOOK_SECRET }, { token }));
    await api.ok(api.post(`/cafe/gateway-accounts/${account.publicId}/test`, {}, { token }));
    await api.ok(api.put('/cafe/payment-methods', { methods: ['cash', 'upi', 'card', 'payment_link'] }, { token }));
  }
  writeFileSync(process.env.FIXTURE_FILE!, JSON.stringify({ diner, apiUrl: `http://localhost:${process.env.LIVE_PORT}`, slug: reg.slug, branch: reg.branchPublicId, qrToken: qr.url.split('/t/')[1], session: scan.session.token, orderId: order.publicId, ownerToken: token, adminSecret: secret, kitchen: { email: 'cook@chai.test', password: 'cook password long' }, owner: { email: 'owner@chai.test', password: 'owner password long' }, adminToken }, null, 2));
  console.log('LIVE STACK READY');
}
main().catch((e) => { console.error(e); process.exit(1); });
