import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import 'adapter_stub.dart' if (dart.library.js_interop) 'adapter_web.dart';
import 'token_store.dart';

class ApiPage {
  const ApiPage(this.items, this.total);
  final List<dynamic> items;
  final int total;
}

/// The only way apps reach the backend: unwraps the envelope, maps errors, and refreshes tokens once.
class ApiClient {
  ApiClient({required this.baseUrl, required this.tokens, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = '$baseUrl/api/v1'
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers['X-Requested-With'] = 'cafe-app';
    if (dio == null) configureAdapter(_dio);
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _attach, onError: _refreshOn401));
  }

  final String baseUrl;
  final TokenStore tokens;
  final Dio _dio;
  String language = 'en';
  String? branchId;
  String? tableSession;

  /// Recorded in the audit log when a platform user reads a cafe's data.
  String? accessReason;
  Future<bool>? _refreshing;

  /// Called when a session cannot be restored, so the app can route to sign-in.
  VoidCallback? onSessionExpired;

  void _attach(RequestOptions o, RequestInterceptorHandler h) {
    final token = tokens.accessToken;
    if (token != null) o.headers['Authorization'] = 'Bearer $token';
    o.headers['Accept-Language'] = language;
    if (branchId != null) o.headers['X-Branch-Id'] = branchId;
    if (tableSession != null) o.headers['X-Table-Session'] = tableSession;
    if (accessReason != null) o.headers['X-Access-Reason'] = accessReason;
    h.next(o);
  }

  Future<void> _refreshOn401(DioException e, ErrorInterceptorHandler h) async {
    final isAuthCall = e.requestOptions.path.startsWith('/auth/');
    if (e.response?.statusCode != 401 || isAuthCall || e.requestOptions.extra['retried'] == true) return h.next(e);
    if (!await restoreSession()) {
      onSessionExpired?.call();
      return h.next(e);
    }
    try {
      final retry = e.requestOptions..extra['retried'] = true;
      retry.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      h.resolve(await _dio.fetch(retry));
    } on DioException catch (again) {
      h.next(again);
    }
  }

  /// Single-flight: rotation invalidates the old token, so parallel 401s must share one refresh.
  Future<bool> restoreSession() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    try {
      final stored = await tokens.readRefresh();
      if (stored == null && !tokens.usesCookie) return false;
      final r = await _dio.post('/auth/refresh', data: stored != null ? {'refreshToken': stored} : <String, dynamic>{});
      adoptTokens(r.data['data'] as Map<String, dynamic>);
      return true;
    } on DioException {
      tokens.accessToken = null;
      await tokens.writeRefresh(null);
      return false;
    }
  }

  void adoptTokens(Map<String, dynamic> data) {
    tokens.accessToken = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (refresh != null) tokens.writeRefresh(refresh);
  }

  String get transport => tokens.usesCookie ? 'cookie' : 'body';

  Future<void> signOut() async {
    try {
      await post('/auth/logout');
    } on ApiFailure {
      // The local session ends regardless.
    }
    tokens.accessToken = null;
    await tokens.writeRefresh(null);
  }

  Future<T> _send<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final r = await call();
      final body = r.data;
      if (body is Map && body.containsKey('data')) return body['data'] as T;
      return body as T;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  ApiFailure _map(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiFailure(code: err['code'] as String? ?? 'ERROR', message: err['message'] as String? ?? '', status: e.response?.statusCode, details: err['details']);
    }
    if (e.response == null) return const ApiFailure.network();
    return ApiFailure(code: 'HTTP_${e.response?.statusCode}', message: '', status: e.response?.statusCode);
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _send<T>(() => _dio.get(path, queryParameters: query));

  Future<ApiPage> getPage(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get(path, queryParameters: query);
      final body = r.data as Map;
      return ApiPage(body['data'] as List<dynamic>, ((body['meta'] as Map?)?['total'] as num?)?.toInt() ?? 0);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<T> post<T>(String path, {Object? body, String? idempotencyKey}) =>
      _send<T>(() => _dio.post(path, data: body ?? <String, dynamic>{}, options: idempotencyKey == null ? null : Options(headers: {'Idempotency-Key': idempotencyKey})));
  Future<T> put<T>(String path, {Object? body}) => _send<T>(() => _dio.put(path, data: body ?? <String, dynamic>{}));
  Future<T> patch<T>(String path, {Object? body}) => _send<T>(() => _dio.patch(path, data: body ?? <String, dynamic>{}));
  Future<T> delete<T>(String path) => _send<T>(() => _dio.delete(path));

  Future<Map<String, dynamic>> upload(String path, List<int> bytes, String filename, {Map<String, dynamic>? query}) => _send<Map<String, dynamic>>(() => _dio.post(path, queryParameters: query, data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename)})));

  Future<List<int>> download(String path, {Map<String, dynamic>? query}) async {
    try {
      final r = await _dio.get<List<int>>(path, queryParameters: query, options: Options(responseType: ResponseType.bytes));
      return r.data ?? const [];
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  String absolute(String path) => path.startsWith('http') ? path : '$baseUrl$path';
}
