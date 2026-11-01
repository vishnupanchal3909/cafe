import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_network/shared_network.dart';

typedef Handler = ResponseBody Function(RequestOptions o);

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  Handler handler;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async { requests.add(o); return handler(o); }
  @override
  void close({bool force = false}) {}
}

ResponseBody json_(int status, Object body) => ResponseBody.fromString(jsonEncode(body), status, headers: {'content-type': ['application/json']});

(ApiClient, FakeAdapter, MemoryTokenStore) make(Handler h) {
  final dio = Dio();
  final a = FakeAdapter(h);
  dio.httpClientAdapter = a;
  final t = MemoryTokenStore();
  return (ApiClient(baseUrl: 'http://x', tokens: t, dio: dio), a, t);
}

void main() {
  test('unwraps the envelope', () async {
    final (api, _, _) = make((_) => json_(200, {'data': {'a': 1}}));
    expect(await api.get<Map<String, dynamic>>('/thing'), {'a': 1});
  });

  test('turns an API error into a coded failure', () async {
    final (api, _, _) = make((_) => json_(409, {'error': {'code': 'ORDER_NOT_PAID', 'message': 'Not paid'}}));
    await expectLater(api.get<dynamic>('/x'), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'ORDER_NOT_PAID').having((f) => f.status, 'status', 409)));
  });

  test('a dropped connection becomes a network failure', () async {
    final (api, _, _) = make((o) => throw DioException.connectionError(requestOptions: o, reason: 'down'));
    await expectLater(api.get<dynamic>('/x'), throwsA(isA<ApiFailure>().having((f) => f.isNetwork, 'network', true)));
  });

  test('attaches token, language, branch and table session', () async {
    final (api, a, t) = make((_) => json_(200, {'data': null}));
    t.accessToken = 'tok';
    api..language = 'hi'..branchId = 'B1'..tableSession = 'S1';
    await api.get<dynamic>('/x');
    final h = a.requests.single.headers;
    expect(h['Authorization'], 'Bearer tok');
    expect(h['Accept-Language'], 'hi');
    expect(h['X-Branch-Id'], 'B1');
    expect(h['X-Table-Session'], 'S1');
  });

  test('a 401 refreshes once and retries; parallel 401s share a single refresh', () async {
    var refreshes = 0;
    late FakeAdapter adapter;
    final (api, a, t) = make((o) {
      if (o.path.endsWith('/auth/refresh')) { refreshes++; return json_(200, {'data': {'accessToken': 'new', 'refreshToken': 'r2'}}); }
      return o.headers['Authorization'] == 'Bearer new' ? json_(200, {'data': 'ok'}) : json_(401, {'error': {'code': 'TOKEN_INVALID', 'message': ''}});
    });
    adapter = a;
    t.accessToken = 'old';
    await t.writeRefresh('r1');
    final results = await Future.wait([api.get<String>('/a'), api.get<String>('/b'), api.get<String>('/c')]);
    expect(results, ['ok', 'ok', 'ok']);
    expect(refreshes, 1, reason: 'rotation would otherwise trip reuse detection');
    expect(await t.readRefresh(), 'r2');
    expect(adapter.requests.isNotEmpty, true);
  });

  test('when refresh fails, the session ends and the app is told', () async {
    var told = false;
    final (api, _, t) = make((o) => json_(401, {'error': {'code': 'TOKEN_REUSED', 'message': ''}}));
    api.onSessionExpired = () => told = true;
    t.accessToken = 'old';
    await t.writeRefresh('r1');
    await expectLater(api.get<dynamic>('/x'), throwsA(isA<ApiFailure>()));
    expect(told, true);
    expect(t.accessToken, null);
    expect(await t.readRefresh(), null);
  });

  test('a login failure is not treated as an expired session', () async {
    var refreshes = 0;
    final (api, _, t) = make((o) {
      if (o.path.endsWith('/auth/refresh')) refreshes++;
      return json_(401, {'error': {'code': 'INVALID_CREDENTIALS', 'message': ''}});
    });
    await t.writeRefresh('r1');
    await expectLater(api.post<dynamic>('/auth/login', body: {}), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'INVALID_CREDENTIALS')));
    expect(refreshes, 0);
  });

  test('idempotency keys reach the request', () async {
    final (api, a, _) = make((_) => json_(201, {'data': {}}));
    await api.post<Map<String, dynamic>>('/x', idempotencyKey: 'k1');
    expect(a.requests.single.headers['Idempotency-Key'], 'k1');
  });
}
