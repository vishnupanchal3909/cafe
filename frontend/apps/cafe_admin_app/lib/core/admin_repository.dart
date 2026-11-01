import 'package:shared_network/shared_network.dart';

/// Single data-layer entry for the admin screens, which are mostly plain lists over one route tree.
class AdminRepository {
  AdminRepository(this.api);
  final ApiClient api;

  Future<bool> signIn(String email, String password, String? totp) async {
    final r = await api.post<Map<String, dynamic>>('/auth/login', body: {'email': email, 'password': password, 'audience': 'platform', 'transport': api.transport, if (totp != null) 'totp': totp});
    api.adoptTokens(r);
    return r['mfaEnrollmentRequired'] == true;
  }
  Future<Map<String, dynamic>> beginMfa() => api.post<Map<String, dynamic>>('/auth/mfa/enroll');
  Future<void> confirmMfa(String code) async => api.adoptTokens(await api.post<Map<String, dynamic>>('/auth/mfa/confirm', body: {'code': code}));
  Future<void> signOut() => api.signOut();
  Future<Map<String, dynamic>> dashboard() => api.get<Map<String, dynamic>>('/platform/analytics');
  Future<List<dynamic>> cafes([String? status]) async => (await api.getPage('/platform/cafes', query: {if (status != null) 'status': status, 'limit': 100})).items;
  Future<void> setCafeStatus(String id, String status, String reason) => api.post<Map<String, dynamic>>('/platform/cafes/$id/status', body: {'status': status, 'reason': reason});
  Future<List<dynamic>> users() async => (await api.getPage('/platform/users', query: {'limit': 100})).items;
  Future<List<dynamic>> plans() => api.get<List<dynamic>>('/platform/plans');
  Future<void> savePlan(String code, Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/platform/plans/$code', body: body);
  Future<List<dynamic>> languages() => api.get<List<dynamic>>('/platform/languages');
  Future<List<dynamic>> currencies() => api.get<List<dynamic>>('/platform/currencies');
  Future<void> saveCurrency(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/platform/currencies', body: body);
  Future<List<dynamic>> rates() => api.get<List<dynamic>>('/platform/exchange-rates');
  Future<void> addRate(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/platform/exchange-rates', body: body);
  Future<void> setUserStatus(String id, String status, String reason) => api.post<Map<String, dynamic>>('/platform/users/$id/status', body: {'status': status, 'reason': reason});
  Future<void> saveLanguage(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/platform/languages', body: body);
  Future<List<dynamic>> translations() => api.get<List<dynamic>>('/platform/translations');
  Future<void> saveTranslation(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/platform/translations', body: body);
  Future<List<dynamic>> countries() => api.get<List<dynamic>>('/platform/countries');
  Future<void> saveCountry(Map<String, dynamic> body) => api.put<Map<String, dynamic>>('/platform/countries', body: body);
  Future<List<dynamic>> commissions() => api.get<List<dynamic>>('/platform/commissions');
  Future<void> addCommission(Map<String, dynamic> body) => api.post<Map<String, dynamic>>('/platform/commissions', body: body);
  Future<List<dynamic>> announcements() => api.get<List<dynamic>>('/platform/announcements');
  Future<Map<String, dynamic>> cafe(String id, String reason) async { api.accessReason = reason; try { return await api.get<Map<String, dynamic>>('/platform/cafes/$id'); } finally { api.accessReason = null; } }
  Future<List<dynamic>> audit() async => (await api.getPage('/platform/audit-logs', query: {'limit': 100})).items;
  Future<List<dynamic>> tickets() async => (await api.getPage('/platform/support-tickets', query: {'limit': 100})).items;
  Future<void> replyTicket(String id, String body) => api.post<Map<String, dynamic>>('/platform/support-tickets/$id/reply', body: {'body': body, 'status': 'in_progress'});
  Future<Map<String, dynamic>> health() => api.get<Map<String, dynamic>>('/platform/health');
  Future<List<dynamic>> finance() => api.get<List<dynamic>>('/platform/finance');
  Future<void> announce(String title, String body, String language) => api.post<Map<String, dynamic>>('/platform/announcements', body: {'audience': 'all_cafes', 'startsAt': DateTime.now().toUtc().toIso8601String(), 'translations': [{'language': language, 'title': title, 'body': body}]});
}
