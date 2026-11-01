import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// On mobile the refresh token sits in the OS keystore. On web it lives only in an HttpOnly cookie,
/// which script cannot read, so the access token stays in memory and a reload silently refreshes.
abstract class TokenStore {
  String? get accessToken;
  set accessToken(String? value);
  Future<String?> readRefresh();
  Future<void> writeRefresh(String? value);
  bool get usesCookie;
}

class PlatformTokenStore implements TokenStore {
  PlatformTokenStore(this._namespace);
  final String _namespace;
  final _secure = const FlutterSecureStorage();
  @override
  String? accessToken;
  @override
  bool get usesCookie => kIsWeb;

  @override
  Future<String?> readRefresh() async => kIsWeb ? null : _secure.read(key: '$_namespace.refresh');

  @override
  Future<void> writeRefresh(String? value) async {
    if (kIsWeb) return;
    if (value == null) {
      await _secure.delete(key: '$_namespace.refresh');
    } else {
      await _secure.write(key: '$_namespace.refresh', value: value);
    }
  }
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.usesCookie = false});
  @override
  String? accessToken;
  String? _refresh;
  @override
  final bool usesCookie;
  @override
  Future<String?> readRefresh() async => _refresh;
  @override
  Future<void> writeRefresh(String? value) async => _refresh = value;
}
