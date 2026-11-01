// Every write the owner screens make, through the real repository, against a running API.
// Run with: FIXTURE_FILE=<file from backend/test/live-stack.ts> flutter test test/live_writes_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:cafe_owner_app/core/owner_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_network/shared_network.dart';

void main() {
  final path = Platform.environment['FIXTURE_FILE'];
  if (path == null) {
    test('live writes', () {}, skip: 'FIXTURE_FILE not set');
    return;
  }
  final fx = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final api = ApiClient(baseUrl: fx['apiUrl'] as String, tokens: MemoryTokenStore());
  final r = OwnerRepository(api);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M/wHwAEBgIApD5fRAAAAABJRU5ErkJggg==');
  late String productId;
  late String ingredientId;
  late String supplierId;

  setUpAll(() async {
    final o = fx['owner'] as Map<String, dynamic>;
    await r.signIn(o['email'] as String, o['password'] as String);
    api.branchId = fx['branch'] as String;
    final menu = await r.menu();
    productId = ((menu['products'] as List).first as Map)['publicId'] as String;
  });

  test('menu: variant, extras, image, station, route', () async {
    await r.addVariant(productId, 'en', 'Small', '90');
    await r.addExtras(productId, 'en', 'Milk', 'Oat', '30');
    await r.addProductImage(productId, await r.upload(png, 'p.png', 'product_image'));
    await r.createStation('Bar');
    final st = (await r.stations()).first as Map;
    await r.routeProduct(productId, st['public_id'] as String);
    final p = ((await r.menu())['products'] as List).cast<Map<dynamic, dynamic>>().firstWhere((x) => x['publicId'] == productId);
    expect((p['variants'] as List).length, greaterThanOrEqualTo(2));
    expect((p['imageUrls'] as List), isNotEmpty);
    expect((p['addonGroups'] as List), isNotEmpty);
  });

  test('branding: logo, cover and banner', () async {
    await r.saveTheme({'logoAssetId': await r.upload(png, 'l.png', 'logo')});
    await r.saveTheme({'coverAssetId': await r.upload(png, 'c.png', 'cover')});
    await r.createBanner(await r.upload(png, 'b.png', 'banner'), 'en', 'Monsoon offer');
  });

  test('inventory: ingredient, recipe, purchase order, receive, supplier invoice and payment', () async {
    await r.createIngredient('Milk', 'ml');
    ingredientId = ((await r.stock()).cast<Map<dynamic, dynamic>>().firstWhere((x) => x['name'] == 'Milk'))['public_id'] as String;
    await r.addRecipeLine(productId, ingredientId, '200');
    await r.addRecipeLine(productId, ingredientId, '250');
    expect((await r.recipe(productId)).length, 1, reason: 'the same ingredient replaces its line');
    await r.createSupplier('Dairy Co', '9999999999');
    supplierId = ((await r.suppliers()).first as Map)['public_id'] as String;
    await r.createPurchaseOrder(supplierId, ingredientId, '1000', '0.05');
    final po = (await r.purchaseOrders()).first as Map;
    await r.receiveAll(po['public_id'] as String);
    expect(((await r.purchaseOrders()).first as Map)['status'], 'received');
    await r.createSupplierInvoice({'supplierId': supplierId, 'number': 'D-1', 'subtotal': '50', 'invoiceDate': today});
    final inv = (await r.supplierInvoices()).first as Map;
    await r.paySupplierInvoice(inv['public_id'] as String, {'amount': '50', 'methodCode': 'cash', 'paidOn': today});
    await r.expiring();
  });

  test('orders: split and transfer', () async {
    await r.createTable('T9', 2);
    final tables = (await r.tables()).cast<Map<dynamic, dynamic>>();
    final t9 = tables.firstWhere((t) => t['table_number'] == 'T9')['public_id'] as String;
    final out = await r.splitBill(fx['orderId'] as String, 3);
    expect((out['bills'] as List).length, 3);
    await r.transfer(fx['orderId'] as String, t9, 'window seat');
  });

  test('books: registers, payroll, journal reversal, reports', () async {
    await r.createRegister('Front');
    final reg = (await r.registers()).first as Map;
    await r.openRegister(reg['public_id'] as String, '500');
    final open = ((await r.registers()).first as Map)['openSession'] as Map;
    final closed = await r.closeRegister(open['public_id'] as String, '500');
    expect(closed['variance'], '0');
    final staff = (await r.staff()).cast<Map<dynamic, dynamic>>().first;
    await r.createPayroll({'staffId': staff['public_id'], 'gross': '1000', 'deductions': '100', 'periodStart': today, 'periodEnd': today});
    await r.payPayroll(((await r.payroll()).first as Map)['public_id'] as String, 'bank', today);
    final entries = (await r.journal()).cast<Map<dynamic, dynamic>>();
    await r.reverseEntry(entries.first['id'] as int, 'test reversal');
    final to = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    expect(await r.trialBalance('2000-01-01', to), isNotEmpty);
    expect((await r.balanceSheet(to))['balanced'], true);
    final periods = (await r.periods()).cast<Map<dynamic, dynamic>>();
    expect(periods, isNotEmpty);
  });

  test('people and marketing: attendance, promotion, loyalty', () async {
    await r.clockIn();
    await r.clockOut();
    expect(await r.attendance(), isNotEmpty);
    final cat = ((await r.menu())['categories'] as List).first as Map;
    await r.createPromotion({'discountType': 'percent', 'percentValue': '5', 'categoryIds': [cat['publicId']], 'translations': [{'language': 'en', 'title': 'Happy hour'}]});
    await r.saveLoyalty({'isActive': true, 'pointsPerCurrencyUnit': '1', 'currencyValuePerPoint': '0.5'});
    expect((await r.loyalty())?['is_active'], 1);
    await r.notifications();
  });

  test('setup: branch, hours, languages, gateway, subscription', () async {
    await r.createBranch({'code': 'B2', 'name': 'Second', 'addressLine1': '2 Road', 'city': 'Mumbai'});
    final branch = (await r.branches()).cast<Map<dynamic, dynamic>>().firstWhere((b) => b['code'] == 'B2');
    await r.setHours(branch['public_id'] as String, [for (var d = 0; d < 7; d++) {'weekday': d, 'opensAt': '08:00', 'closesAt': '22:00'}]);
    expect((await r.hours(branch['public_id'] as String)).length, 7);
    await r.setLanguages(['en', 'hi', 'ar', 'ja', 'fr']);
    final out = await r.saveGateway({'providerCode': 'razorpay', 'environment': 'sandbox', 'keyId': 'k', 'keySecret': 's', 'webhookSecret': 'w'});
    expect(out['webhookUrl'], contains('/webhooks/payments/razorpay/'));
    expect(jsonEncode(await r.gatewayAccounts()).contains('"s"'), false);
    await r.setPaymentMethods(['cash', 'upi', 'card', 'payment_link']);
    await expectLater(r.testGateway((await r.gatewayAccounts()).cast<Map<dynamic, dynamic>>().first['public_id'] as String), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', anyOf('GATEWAY_CREDENTIALS_INVALID', 'GATEWAY_UNAVAILABLE'))), reason: 'fake keys must never switch payments on');
    await r.subscription();
    await r.plans();
  });
}
