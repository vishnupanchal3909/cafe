import 'dart:convert';
import 'dart:typed_data';
import 'package:cafe_admin_app/core/admin_repository.dart';
import 'package:cafe_admin_app/features/screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.routes);
  final Map<String, Object> routes;
  final posts = <String, Object?>{};
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    if (o.method == 'POST') posts[o.path] = o.data;
    return ResponseBody.fromString(jsonEncode({'data': routes[o.path] ?? <String, Object>{}, 'meta': {'total': 1}}), 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

Adapter setup(Map<String, Object> routes) {
  GetIt.I.allowReassignment = true;
  final dio = Dio();
  final a = Adapter(routes);
  dio.httpClientAdapter = a;
  GetIt.I.registerSingleton(AdminRepository(ApiClient(baseUrl: 'http://x', tokens: MemoryTokenStore(), dio: dio)));
  return a;
}

Widget host(Widget child) => MaterialApp(supportedLocales: supportedAppLocales, localizationsDelegates: appLocalizationDelegates, home: Scaffold(body: child));

void main() {
  testWidgets('money is kept apart by currency, never added together', (t) async {
    setup({'/platform/analytics': {
      'cafes': {'total': 2, 'active': 2, 'pending': 0}, 'orders': {'total': 2}, 'customers': 0, 'subscriptions': {'active': 0}, 'cafesByCountry': <Object>[],
      'grossByCurrency': [{'currency_code': 'INR', 'gross': '357.0000'}, {'currency_code': 'JPY', 'gross': '1500.0000'}],
    }});
    t.view.physicalSize = const Size(1400, 1200); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
    await t.pumpWidget(MoneyScope(minorUnits: const {'INR': 2, 'JPY': 0}, child: host(const DashboardScreen())));
    await t.pumpAndSettle();
    expect(find.text('₹357.00'), findsOneWidget);
    expect(find.textContaining('1,500'), findsOneWidget);
  });

  testWidgets('suspending a cafe demands a reason, which reaches the audit trail', (t) async {
    final a = setup({'/platform/cafes': [{'public_id': 'C1', 'display_name': 'Chai', 'owner_name': 'A', 'owner_email': 'a@x', 'country_code': 'IN', 'currency_code': 'INR', 'status': 'active', 'created_at': '2026-01-01T00:00:00Z'}]});
    t.view.physicalSize = const Size(1400, 900); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
    await t.pumpWidget(host(const CafesScreen()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.block));
    await t.pumpAndSettle();
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(a.posts, isEmpty, reason: 'no reason, no action');
    await t.enterText(find.byType(TextFormField), 'fraud review');
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(a.posts['/platform/cafes/C1/status'], {'status': 'suspended', 'reason': 'fraud review'});
  });
}
