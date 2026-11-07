// Parses REAL responses from a running API into the app's models, so the Dart and TypeScript sides cannot drift silently.
// Run with: FIXTURE_FILE=<file from backend/test/live-stack.ts> flutter test test/live_contract_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:cafe_customer_app/features/account/data/account_repository.dart';
import 'package:cafe_customer_app/features/cart/domain/cart.dart';
import 'package:cafe_customer_app/features/menu/data/menu_repository.dart';
import 'package:cafe_customer_app/features/orders/data/order_repository.dart';
import 'package:cafe_customer_app/features/session/data/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';

void main() {
  final path = Platform.environment['FIXTURE_FILE'];
  if (path == null) {
    test('live contract', () {}, skip: 'FIXTURE_FILE not set; no live API to test against');
    return;
  }
  final fx = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final api = ApiClient(baseUrl: fx['apiUrl'] as String, tokens: MemoryTokenStore());

  test('QR scan returns a config the app can read, and no client value picked the cafe', () async {
    final ctx = await ApiSessionRepository(api).scan(fx['qrToken'] as String, 'hi');
    expect(ctx.tableNumber, 'T1');
    expect(ctx.config.currency.code, 'INR');
    expect(ctx.config.languages.map((l) => l.code), containsAll(['en', 'hi', 'ar', 'ja']));
    expect(ctx.config.theme.primaryColor, '#7B3F00');
  });

  late Menu menu;
  test('the menu parses and is localized', () async {
    menu = await ApiMenuRepository(api).load(slug: fx['slug'] as String, language: 'hi', branchId: fx['branch'] as String);
    expect(menu.products.map((p) => p.name), contains('मसाला चाय'));
    expect(menu.products.firstWhere((p) => p.name == 'मसाला चाय').variants.single.price.amount.toString(), '150');
  });

  test('placing, tracking and paying use the real contract', () async {
    final repo = ApiOrderRepository(api);
    final diner = fx['diner'] as Map<String, dynamic>;
    // A guest may browse, but ordering needs a customer login, and the server refuses without one.
    await expectLater(repo.place(const Cart.empty(), language: 'hi', idempotencyKey: newIdempotencyKey()), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'CUSTOMER_LOGIN_REQUIRED')));
    await ApiAccountRepository(api).signIn(diner['email'] as String, diner['password'] as String);
    final p = menu.products.firstWhere((x) => x.name == 'मसाला चाय');
    final cart = const Cart.empty().add(CartLine(product: p, variant: p.variants.single, addons: [p.addonGroups.single.addons.single], quantity: 2));
    final order = await repo.place(cart, language: 'hi', idempotencyKey: newIdempotencyKey());
    expect(order.total.amount.toString(), '357');
    expect(order.total, isA<Money>());
    expect(order.items.single.name, 'मसाला चाय');
    expect((await repo.get(order.publicId)).status, 'placed');
    expect((await repo.forSession()).length, greaterThanOrEqualTo(2));
    expect((await repo.paymentOptions())['online'], isNull, reason: 'no gateway is configured, and the app must say so honestly');
    await expectLater(repo.startPayment(order.publicId, 'upi'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ONLINE_PAYMENT_NOT_CONFIGURED')));
  });

  test('account: addresses, wishlist, reservation', () async {
    final account = ApiClient(baseUrl: fx['apiUrl'] as String, tokens: MemoryTokenStore());
    final repo = ApiAccountRepository(account);
    await repo.register('live-${DateTime.now().millisecondsSinceEpoch}@example.test', 'a long password', 'Live', 'en');
    await repo.addAddress({'label': 'Home', 'addressLine1': '1 Road', 'city': 'Pune', 'countryCode': 'IN'});
    final addresses = await repo.addresses();
    expect(addresses.length, 1);
    await repo.removeAddress((addresses.first as Map)['public_id'] as String);
    final slug = fx['slug'] as String;
    final product = menu.products.first.publicId;
    await repo.addWish(slug, product);
    expect(((await repo.wishlist(slug)).first as Map)['name'], isNotEmpty);
    await repo.removeWish(slug, product);
    final start = DateTime.now().toUtc().add(const Duration(days: 1));
    await repo.reserve(slug, {'branchId': fx['branch'], 'partySize': 2, 'startsAt': start.toIso8601String(), 'endsAt': start.add(const Duration(hours: 2)).toIso8601String()});
  });

  test('kitchen tickets parse from the live API', () async {
    final cook = ApiClient(baseUrl: fx['apiUrl'] as String, tokens: MemoryTokenStore());
    final k = fx['kitchen'] as Map<String, dynamic>;
    cook.adoptTokens(await cook.post<Map<String, dynamic>>('/auth/login', body: {'email': k['email'], 'password': k['password'], 'audience': 'kitchen'}));
    cook.branchId = fx['branch'] as String;
    final tickets = [for (final t in await cook.get<List<dynamic>>('/kitchen/tickets')) KitchenTicket.fromJson(t as Map<String, dynamic>)];
    expect(tickets, isNotEmpty);
    expect(tickets.first.tableNumber, 'T1');
    expect(tickets.first.items.first.addons, isNotEmpty);
    final stations = await cook.get<List<dynamic>>('/kitchen/stations');
    expect(stations, isA<List<dynamic>>());
    final done = await cook.get<List<dynamic>>('/kitchen/tickets', query: {'status': 'completed'});
    expect(done, isA<List<dynamic>>());
  });
}
