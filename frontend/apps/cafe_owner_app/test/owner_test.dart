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

Adapter setup(Map<String, Object> routes) {
  GetIt.I.allowReassignment = true;
  final dio = Dio();
  final a = Adapter(routes);
  dio.httpClientAdapter = a;
  GetIt.I.registerSingleton(OwnerRepository(ApiClient(baseUrl: 'http://x', tokens: MemoryTokenStore(), dio: dio)));
  return a;
}

Widget host(Widget child, {Locale? locale}) => MaterialApp(locale: locale, supportedLocales: supportedAppLocales, localizationsDelegates: appLocalizationDelegates, home: Scaffold(body: child));

const analytics = {'currency': 'INR', 'revenue': '125000.00', 'orders': 3, 'averageOrderValue': '41666.67', 'cancellationRate': '0.00', 'topProducts': [{'name': 'Chai', 'quantity': '5'}], 'peakHours': [{'local_hour': 9, 'orders': 2}]};

void main() {
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
