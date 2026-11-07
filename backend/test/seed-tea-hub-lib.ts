// Fills an existing cafe with realistic data to try the whole product. Goes through the real services, so every
// rule applies. Tax rates here are placeholders for testing, not tax advice. Creates no orders: analytics stay real.
import type { INestApplicationContext } from '@nestjs/common';
import { als, Principal, unscoped } from '../src/common/context';
import { Db } from '../src/infra/db/db.service';
import { CatalogService } from '../src/modules/catalog/catalog.service';
import { FinanceService } from '../src/modules/finance/finance.service';
import { InventoryService } from '../src/modules/inventory/inventory.service';
import { KitchenService } from '../src/modules/kitchen/kitchen.service';
import { MarketingService } from '../src/modules/marketing/marketing.service';
import { PaymentsService } from '../src/modules/payments/payments.service';
import { StaffService } from '../src/modules/staff/staff.service';
import { TenancyService } from '../src/modules/tenancy/tenancy.service';

export const STAFF = [
  { role: 'manager', email: 'manager@tea-hub.test', password: 'Manager@12345', name: 'Meera Manager' },
  { role: 'cashier', email: 'cashier@tea-hub.test', password: 'Cashier@12345', name: 'Chetan Cashier' },
  { role: 'waiter', email: 'waiter@tea-hub.test', password: 'Waiter@12345', name: 'Wasim Waiter' },
  { role: 'kitchen_staff', email: 'kitchen@tea-hub.test', password: 'Kitchen@12345', name: 'Kiran Kitchen' },
];

type Names = [en: string, hi: string, mr: string];
const tr = ([en, hi, mr]: Names, description?: Names) => [
  { language: 'en', name: en, description: description?.[0] },
  { language: 'hi', name: hi, description: description?.[1] },
  { language: 'mr', name: mr, description: description?.[2] },
];

export async function seedTeaHub(app: INestApplicationContext, slug: string) {
  const db = app.get(Db);
  const cafe = await unscoped('seed', () => db.q.selectFrom('cafes').select(['id', 'owner_user_id', 'default_language_code', 'currency_code']).where('slug', '=', slug).executeTakeFirst());
  if (!cafe) throw new Error(`No cafe with slug ${slug}`);
  const branch = await unscoped('seed', () => db.q.selectFrom('cafe_branches').select(['id', 'public_id']).where('cafe_id', '=', cafe.id).where('is_main', '=', 1).executeTakeFirstOrThrow());
  const existing = await unscoped('seed', () => db.q.selectFrom('categories').select('id').where('cafe_id', '=', cafe.id).where('deleted_at', 'is', null).limit(1).executeTakeFirst());
  if (existing) throw new Error('This cafe already has a menu. Nothing was changed, to avoid duplicates.');
  const perms = await unscoped('seed', () => db.q.selectFrom('permissions').select('code').where('scope', '=', 'cafe').execute());
  const principal: Principal = { type: 'user', id: cafe.owner_user_id, audience: 'cafe', permissions: new Set(perms.map((p) => p.code)), branchIds: null };

  return als.run({ requestId: 'seed-tea-hub', lang: cafe.default_language_code, cafeId: cafe.id, branchId: branch.id, principal }, async () => {
    const tenancy = app.get(TenancyService);
    const catalog = app.get(CatalogService);
    const kitchen = app.get(KitchenService);
    const inventory = app.get(InventoryService);
    const marketing = app.get(MarketingService);
    const finance = app.get(FinanceService);
    const staff = app.get(StaffService);
    const payments = app.get(PaymentsService);

    await tenancy.setLanguages(['en', 'hi', 'mr']);
    await tenancy.updateTheme({ primaryColor: '#7A3E12', secondaryColor: '#D9A441', backgroundColor: '#FFF9F2', textColor: '#2B1A0E', buttonStyle: 'rounded', menuLayout: 'list' });
    await payments.setMethods(['cash']);

    await catalog.createTaxCategory({ code: 'FOOD', name: 'Food and beverages' });
    await catalog.addTaxRate('FOOD', { componentCode: 'CGST', displayName: 'CGST', ratePercent: '2.5', appliesTo: 'intra_region', validFrom: '2020-01-01' });
    await catalog.addTaxRate('FOOD', { componentCode: 'SGST', displayName: 'SGST', ratePercent: '2.5', appliesTo: 'intra_region', validFrom: '2020-01-01' });
    await catalog.addTaxRate('FOOD', { componentCode: 'IGST', displayName: 'IGST', ratePercent: '5', appliesTo: 'inter_region', validFrom: '2020-01-01' });

    const category = async (names: Names, sortOrder: number) => (await catalog.createCategory({ translations: tr(names), sortOrder })).publicId;
    const tea = await category(['Tea', 'चाय', 'चहा'], 1);
    const coffee = await category(['Coffee', 'कॉफ़ी', 'कॉफी'], 2);
    const snacks = await category(['Snacks', 'नाश्ता', 'नाश्ता'], 3);
    const desserts = await category(['Desserts', 'मिठाई', 'गोड पदार्थ'], 4);
    const combos = await category(['Combos', 'कॉम्बो', 'कॉम्बो'], 5);

    const product = async (categoryId: string, names: Names, price: string, dietaryClass: 'veg' | 'non_veg' | 'egg', description?: Names, prepMinutes = 5) =>
      (await catalog.createProduct({ categoryId, basePrice: price, dietaryClass, taxCategoryId: 'FOOD', prepMinutes, translations: tr(names, description) })).publicId;
    const sized = async (id: string, small: string, large: string) => {
      const s = await catalog.addVariant(id, { price: small, isDefault: true, translations: tr(['Small', 'छोटा', 'लहान']) });
      const l = await catalog.addVariant(id, { price: large, translations: tr(['Large', 'बड़ा', 'मोठा']) });
      return { small: s.publicId, large: l.publicId };
    };

    const masala = await product(tea, ['Masala Chai', 'मसाला चाय', 'मसाला चहा'], '25', 'veg', ['Spiced milk tea', 'मसालेदार दूध वाली चाय', 'मसालेदार दुधाचा चहा']);
    const masalaSizes = await sized(masala, '25', '40');
    const adrak = await product(tea, ['Ginger Tea', 'अदरक चाय', 'आले चहा'], '20', 'veg', ['Fresh ginger tea', 'ताज़े अदरक की चाय', 'ताज्या आल्याचा चहा']);
    const adrakSizes = await sized(adrak, '20', '35');
    const green = await product(tea, ['Green Tea', 'ग्रीन टी', 'ग्रीन टी'], '45', 'veg', ['Light and refreshing', 'हल्की और ताज़गी भरी', 'हलका आणि ताजेतवाने']);
    const filter = await product(coffee, ['Filter Coffee', 'फ़िल्टर कॉफ़ी', 'फिल्टर कॉफी'], '50', 'veg', ['South Indian style', 'दक्षिण भारतीय शैली', 'दक्षिण भारतीय पद्धत']);
    const cappuccino = await product(coffee, ['Cappuccino', 'कैपुचीनो', 'कॅपुचिनो'], '120', 'veg');
    const cold = await product(coffee, ['Cold Coffee', 'कोल्ड कॉफ़ी', 'कोल्ड कॉफी'], '110', 'veg');
    const samosa = await product(snacks, ['Veg Samosa', 'वेज समोसा', 'व्हेज सामोसा'], '25', 'veg', ['Two pieces', 'दो पीस', 'दोन नग'], 8);
    const vada = await product(snacks, ['Vada Pav', 'वड़ा पाव', 'वडा पाव'], '30', 'veg', undefined, 6);
    const omelette = await product(snacks, ['Egg Omelette', 'अंडा ऑमलेट', 'अंड्याचे ऑम्लेट'], '60', 'egg', undefined, 10);
    const puff = await product(snacks, ['Chicken Puff', 'चिकन पफ', 'चिकन पफ'], '70', 'non_veg', undefined, 5);
    const gulab = await product(desserts, ['Gulab Jamun', 'गुलाब जामुन', 'गुलाबजाम'], '50', 'veg', undefined, 3);
    const brownie = await product(desserts, ['Chocolate Brownie', 'चॉकलेट ब्राउनी', 'चॉकलेट ब्राउनी'], '90', 'veg', undefined, 3);
    const combo = await product(combos, ['Chai and Samosa Combo', 'चाय समोसा कॉम्बो', 'चहा सामोसा कॉम्बो'], '45', 'veg', ['Small masala chai with samosa', 'छोटी मसाला चाय और समोसा', 'लहान मसाला चहा आणि सामोसा'], 8);
    await catalog.setComboItems(combo, [{ productId: masala, variantId: masalaSizes.small, quantity: 1 }, { productId: samosa, quantity: 1 }]);
    await catalog.updateProduct(cold, { isOutOfStock: true });

    const extras = await catalog.createAddonGroup({ maxSelect: 3, translations: tr(['Extras', 'अतिरिक्त', 'अतिरिक्त']), addons: [
      { price: '5', translations: tr(['Ginger', 'अदरक', 'आले']) },
      { price: '5', translations: tr(['Cardamom', 'इलायची', 'वेलची']) },
      { price: '10', translations: tr(['Extra milk', 'अतिरिक्त दूध', 'अतिरिक्त दूध']) },
    ] });
    const sugar = await catalog.createAddonGroup({ minSelect: 1, maxSelect: 1, translations: tr(['Sugar', 'चीनी', 'साखर']), addons: [
      { price: '0', translations: tr(['Regular sugar', 'सामान्य चीनी', 'नेहमीची साखर']) },
      { price: '0', translations: tr(['Less sugar', 'कम चीनी', 'कमी साखर']) },
      { price: '0', translations: tr(['No sugar', 'बिना चीनी', 'साखरेशिवाय']) },
    ] });
    await catalog.setProductAddonGroups(masala, [extras.publicId, sugar.publicId]);
    await catalog.setProductAddonGroups(adrak, [extras.publicId, sugar.publicId]);
    await catalog.setProductAddonGroups(filter, [sugar.publicId]);

    const counter = (await kitchen.createStation({ name: 'Tea Counter', delayThresholdMinutes: 10 })).publicId;
    const hot = (await kitchen.createStation({ name: 'Hot Kitchen', delayThresholdMinutes: 15 })).publicId;
    for (const p of [masala, adrak, green, filter, cappuccino, cold, combo]) await kitchen.routeProduct(p, counter);
    for (const p of [samosa, vada, omelette, puff, gulab, brownie]) await kitchen.routeProduct(p, hot);

    const ingredient = async (name: string, unitCode: string, quantity: string, unitCost: string, reorder: string, expiresOn?: string) => {
      const id = (await inventory.createIngredient({ name, unitCode, isPerishable: !!expiresOn })).publicId;
      await inventory.record({ ingredientId: id, type: 'stock_in', quantity, unitCost, expiresOn });
      await inventory.setReorderLevel(id, reorder);
      return id;
    };
    const inDays = (n: number) => new Date(Date.now() + n * 86400_000).toISOString().slice(0, 10);
    const leaves = await ingredient('Tea leaves', 'g', '5000', '0.60', '500');
    const milk = await ingredient('Milk', 'ml', '20000', '0.06', '3000', inDays(5));
    const sugarStock = await ingredient('Sugar', 'g', '10000', '0.05', '1000');
    const ginger = await ingredient('Ginger', 'g', '1000', '0.20', '100', inDays(10));
    const beans = await ingredient('Coffee powder', 'g', '3000', '1.20', '300');
    const samosaStock = await ingredient('Frozen samosa', 'pc', '200', '8', '30', inDays(30));
    const pav = await ingredient('Pav bread', 'pc', '100', '4', '20', inDays(3));

    const recipe = (p: string, variant: string | undefined, items: Array<[string, string]>) => inventory.setRecipe(p, variant, items.map(([ingredientId, quantity]) => ({ ingredientId, quantity })));
    await recipe(masala, masalaSizes.small, [[leaves, '4'], [milk, '100'], [sugarStock, '8']]);
    await recipe(masala, masalaSizes.large, [[leaves, '6'], [milk, '180'], [sugarStock, '12']]);
    await recipe(adrak, adrakSizes.small, [[leaves, '4'], [milk, '100'], [sugarStock, '8'], [ginger, '3']]);
    await recipe(adrak, adrakSizes.large, [[leaves, '6'], [milk, '180'], [sugarStock, '12'], [ginger, '5']]);
    await recipe(filter, undefined, [[beans, '12'], [milk, '120'], [sugarStock, '8']]);
    await recipe(cappuccino, undefined, [[beans, '15'], [milk, '180']]);
    await recipe(samosa, undefined, [[samosaStock, '2']]);
    await recipe(vada, undefined, [[pav, '1']]);

    const supplier = (await inventory.createSupplier({ name: 'Pune Dairy Supplies', contactName: 'Sunil', phone: '9000000001', paymentTermsDays: 15 })).publicId;
    await inventory.createSupplier({ name: 'Assam Tea Traders', contactName: 'Bora', phone: '9000000002', paymentTermsDays: 30 });
    await inventory.createPurchaseOrder({ supplierId: supplier, notes: 'Weekly milk', items: [{ ingredientId: milk, quantity: '10000', unitCost: '0.06' }] });

    await marketing.createCoupon({ code: 'TEA10', discountType: 'percent', percentValue: '10', minOrderAmount: '100', maxDiscountAmount: '50' });
    await marketing.createCoupon({ code: 'FLAT20', discountType: 'fixed', fixedAmount: '20', minOrderAmount: '150', maxRedemptions: 100 });
    await marketing.createPromotion({ discountType: 'percent', percentValue: '10', categoryIds: [desserts], translations: [{ language: 'en', title: '10% off desserts' }, { language: 'hi', title: 'मिठाई पर 10% छूट' }] });
    await marketing.saveLoyalty({ isActive: true, pointsPerCurrencyUnit: '1', currencyValuePerPoint: '0.10', minRedeemPoints: 50 });

    await finance.createRegister('Front Counter');
    for (const [name, code] of [['Rent', '6100'], ['Electricity', '6200'], ['Miscellaneous', '6900']] as const) await finance.createCategory(name, code);

    for (const s of STAFF) {
      const invited = await staff.invite({ email: s.email, fullName: s.name, roleCode: s.role, jobTitle: s.name.split(' ')[1] });
      if (invited.invitationToken) await staff.acceptInvitation(invited.invitationToken, s.password);
    }
    return { branch: branch.public_id };
  });
}
