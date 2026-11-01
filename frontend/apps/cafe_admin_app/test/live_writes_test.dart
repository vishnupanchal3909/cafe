// Every write the admin screens make, through the real repository, against a running API.
import 'dart:convert';
import 'dart:io';
import 'package:cafe_admin_app/core/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_network/shared_network.dart';

void main() {
  final path = Platform.environment['FIXTURE_FILE'];
  if (path == null) {
    test('live writes', () {}, skip: 'FIXTURE_FILE not set');
    return;
  }
  final fx = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final tokens = MemoryTokenStore()..accessToken = fx['adminToken'] as String;
  final r = AdminRepository(ApiClient(baseUrl: fx['apiUrl'] as String, tokens: tokens));

  test('reference data', () async {
    await r.saveLanguage({'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano', 'direction': 'ltr'});
    expect((await r.languages()).cast<Map<dynamic, dynamic>>().any((l) => l['code'] == 'it'), true);
    await r.saveCurrency({'code': 'KWD', 'numericCode': '414', 'name': 'Kuwaiti Dinar', 'symbol': 'KD', 'minorUnit': 3});
    await r.saveCountry({'code': 'KW', 'name': 'Kuwait', 'defaultCurrency': 'KWD', 'defaultLanguage': 'ar', 'defaultTimezone': 'Asia/Kuwait'});
    expect((await r.countries()).cast<Map<dynamic, dynamic>>().any((c) => c['code'] == 'KW'), true);
    await r.saveTranslation({'namespace': 'errors', 'key': 'NOT_FOUND', 'language': 'it', 'value': 'Non trovato', 'isReviewed': true});
    expect(await r.translations(), isNotEmpty);
  });

  test('commissions and announcements', () async {
    await r.addCommission({'ratePercent': '0', 'validFrom': DateTime.now().toUtc().toIso8601String()});
    expect(await r.commissions(), isNotEmpty);
    await r.announce('Maintenance', 'Sunday 2am', 'en');
    expect(await r.announcements(), isNotEmpty);
  });

  test('a cafe read carries its reason into the audit log, and users can be disabled', () async {
    final cafes = await r.cafes();
    await r.cafe((cafes.first as Map)['public_id'] as String, 'support ticket 42');
    final logs = (await r.audit()).cast<Map<dynamic, dynamic>>();
    expect(logs.any((l) => l['action'] == 'platform.cafe_read' && l['reason'] == 'support ticket 42'), true);
    final users = (await r.users()).cast<Map<dynamic, dynamic>>().where((u) => u['email'] == 'cook@chai.test');
    await r.setUserStatus(users.first['public_id'] as String, 'disabled', 'test');
    await r.setUserStatus(users.first['public_id'] as String, 'active', 'test');
  });
}
