import 'package:cafe_owner_app/core/order_flags.dart';
import 'package:cafe_owner_app/core/owner_repository.dart';
import 'package:cafe_owner_app/features/screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';
import 'dart:convert';
import 'dart:typed_data';

class Adapter implements HttpClientAdapter {
  Adapter(this.routes);
  final Map<String, Object> routes;
  final calls = <String>[];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add('${o.method} ${o.path}');
    final body = routes[o.path];
    if (body == null) return ResponseBody.fromString(jsonEncode({'error': {'code': 'NOT_FOUND', 'message': 'nope'}}), 404, headers: {'content-type': ['application/json']});
    return ResponseBody.fromString(jsonEncode({'data': body}), 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

/// A manager's everyday permissions, unless a test says otherwise.
const managerPermissions = {'menu.read', 'menu.manage', 'orders.read', 'orders.update', 'orders.cancel', 'payments.read', 'payments.cash_confirm', 'refunds.request', 'refunds.approve', 'tables.read', 'tables.manage', 'tables.transfer', 'staff.read', 'inventory.manage', 'kitchen.read', 'kitchen.configure'};

Adapter setup(Map<String, Object> routes, {Set<String> permissions = managerPermissions}) {
  GetIt.I.allowReassignment = true;
  final dio = Dio();
  final a = Adapter(routes);
  dio.httpClientAdapter = a;
  GetIt.I.registerSingleton(OwnerRepository(ApiClient(baseUrl: 'http://x', tokens: MemoryTokenStore(), dio: dio))..permissions = permissions);
  return a;
}

Widget host(Widget child, {Locale? locale}) => MaterialApp(locale: locale, supportedLocales: supportedAppLocales, localizationsDelegates: appLocalizationDelegates, home: Scaffold(body: child));

const analytics = {'currency': 'INR', 'revenue': '125000.00', 'orders': 3, 'averageOrderValue': '41666.67', 'cancellationRate': '0.00', 'topProducts': [{'name': 'Chai', 'quantity': '5'}], 'peakHours': [{'local_hour': 9, 'orders': 2}]};

void main() {
  group('walk-outs', () {
    final now = DateTime.utc(2026, 11, 7, 12);
    Map<String, dynamic> order(String pay, String status, int minutesAgo) => {'payment_status': pay, 'status': status, 'placed_at': now.subtract(Duration(minutes: minutesAgo)).toIso8601String()};
    test('an order unpaid past the alert time is flagged with how long', () => expect(unpaidMinutes(order('unpaid', 'served', 75), alertMinutes: 60, now: now), 75));
    test('within the alert time it is not', () => expect(unpaidMinutes(order('unpaid', 'served', 30), alertMinutes: 60, now: now), isNull));
    test('part paid still counts; paid and cancelled do not', () {
      expect(unpaidMinutes(order('partially_paid', 'served', 90), alertMinutes: 60, now: now), 90);
      expect(unpaidMinutes(order('paid', 'served', 90), alertMinutes: 60, now: now), isNull);
      expect(unpaidMinutes(order('unpaid', 'cancelled', 90), alertMinutes: 60, now: now), isNull);
    });
  });

  testWidgets('the dashboard shows real figures with Indian grouping', (t) async {
    setup({'/cafe/analytics': analytics});
    await t.pumpWidget(MoneyScope(minorUnits: const {'INR': 2}, countryCode: 'IN', child: host(const DashboardScreen())));
    await t.pumpAndSettle();
    expect(find.text('₹1,25,000.00'), findsOneWidget);
    expect(find.text('Chai'), findsOneWidget);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('a dashboard with no data says so, and invents nothing', (t) async {
    setup({'/cafe/analytics': {...analytics, 'revenue': '0', 'orders': 0, 'averageOrderValue': '0', 'cancellationRate': null, 'topProducts': <Object>[], 'peakHours': <Object>[]}});
    await t.pumpWidget(host(const DashboardScreen()));
    await t.pumpAndSettle();
    expect(find.text('No data for this period yet'), findsNWidgets(2));
    expect(find.text('–'), findsOneWidget);
  });

  testWidgets('the staff screen shows owners with translated status, and no suspend button for them', (t) async {
    setup({'/cafe/staff': [
      {'public_id': 'S1', 'full_name': 'Asha', 'email': 'a@x.test', 'status': 'active', 'roles': [{'code': 'owner', 'name': 'Owner'}]},
      {'public_id': 'S2', 'full_name': 'Ravi', 'email': 'r@x.test', 'status': 'active', 'roles': [{'code': 'waiter', 'name': 'Waiter'}]},
    ]});
    t.view.physicalSize = const Size(1400, 900); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
    await t.pumpWidget(host(const StaffScreen()));
    await t.pumpAndSettle();
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('active'), findsNothing);
    expect(find.byIcon(Icons.person_off), findsOneWidget);
  });

  group('menu cards', () {
    const menu = {
      'categories': [{'publicId': 'C1', 'name': 'Tea'}, {'publicId': 'C2', 'name': 'Snacks'}],
      'products': [
        {'publicId': 'P1', 'categoryId': 'C1', 'name': 'Masala Chai', 'price': {'amount': '25.0000', 'currency': 'INR'}, 'dietaryClass': 'veg', 'isOutOfStock': false, 'imageUrls': <Object>[]},
        {'publicId': 'P2', 'categoryId': 'C2', 'name': 'Samosa', 'price': {'amount': '30.0000', 'currency': 'INR'}, 'dietaryClass': 'veg', 'isOutOfStock': true, 'imageUrls': <Object>[]},
      ],
    };
    Future<Adapter> show(WidgetTester t, {Set<String> permissions = managerPermissions}) async {
      t.view.physicalSize = const Size(1400, 900); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
      final a = setup({'/cafe/menu': menu, '/cafe/products/P1': {'ok': true}, '/cafe/products/P2': {'ok': true}}, permissions: permissions);
      await t.pumpWidget(MoneyScope(minorUnits: const {'INR': 2}, countryCode: 'IN', child: host(const MenuScreen(defaultLanguage: 'en'))));
      await t.pumpAndSettle();
      return a;
    }

    testWidgets('a product without a photo invites one, and an unavailable one says so', (t) async {
      await show(t);
      expect(find.text('Add photo'), findsNWidgets(2));
      expect(find.text('₹25.00'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('categories and search narrow the grid', (t) async {
      await show(t);
      await t.tap(find.widgetWithText(ChoiceChip, 'Snacks'));
      await t.pump();
      expect(find.text('Masala Chai'), findsNothing);
      expect(find.text('Samosa'), findsOneWidget);
      await t.tap(find.widgetWithText(ChoiceChip, 'All'));
      await t.enterText(find.byType(TextField), 'masala');
      await t.pump();
      expect(find.text('Masala Chai'), findsOneWidget);
      expect(find.text('Samosa'), findsNothing);
    });

    testWidgets('someone who may only read the menu sees it, without anything that would be refused', (t) async {
      final a = await show(t, permissions: const {'menu.read', 'orders.read'});
      expect(find.text('Masala Chai'), findsOneWidget);
      expect(find.text('Add photo'), findsNothing);
      expect(find.text('New product'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(t.widget<Switch>(find.byType(Switch).first).onChanged, isNull, reason: 'the availability switch shows, but cannot be flipped');
      expect(a.calls.where((c) => !c.startsWith('GET')), isEmpty);
    });

    testWidgets('the switch tells the server, and brings a sold-out item back too', (t) async {
      final a = await show(t);
      await t.tap(find.byType(Switch).last);
      await t.pumpAndSettle();
      expect(a.calls, contains('PATCH /cafe/products/P2'));
    });
  });

  testWidgets('a permission error from the server is shown, not swallowed', (t) async {
    setup({});
    await t.pumpWidget(host(const StaffScreen()));
    await t.pumpAndSettle();
    expect(find.text('nope'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('registration validates before calling the server', (t) async {
    final a = setup({'/public/reference': {'countries': [{'code': 'IN', 'name': 'India', 'default_currency_code': 'INR', 'default_language_code': 'en', 'default_timezone': 'Asia/Kolkata'}]}});
    t.view.physicalSize = const Size(900, 1400); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
    await t.pumpWidget(host(RegisterScreen(onDone: () {})));
    await t.pumpAndSettle();
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);
    expect(a.calls.where((c) => c.startsWith('POST')), isEmpty);
  });

  test('every money-moving request carries a fresh idempotency key', () {
    expect(idempotencyKey(), isNot(idempotencyKey()));
    expect(idempotencyKey().length, 24);
  });
}
