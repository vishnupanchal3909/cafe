import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';

class TableContext {
  const TableContext({required this.tableNumber, required this.sessionToken, required this.sessionPublicId, required this.slug, required this.branchId, required this.config});
  final String tableNumber;
  final String sessionToken;
  final String sessionPublicId;
  final String slug;
  final String branchId;
  final CafeConfig config;
}

abstract class SessionRepository {
  Future<TableContext> scan(String qrToken, String language);
  Future<CafeConfig> config(String slug, String language);
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._api);
  final ApiClient _api;

  @override
  Future<TableContext> scan(String qrToken, String language) async {
    final r = await _api.get<Map<String, dynamic>>('/public/qr/${Uri.encodeComponent(qrToken)}', query: {'lang': language});
    final session = r['session'] as Map<String, dynamic>;
    final ctx = TableContext(
      tableNumber: (r['table'] as Map)['number'] as String,
      sessionToken: session['token'] as String,
      sessionPublicId: session['publicId'] as String,
      slug: r['slug'] as String,
      branchId: r['branchId'] as String,
      config: CafeConfig.fromJson(r['config'] as Map<String, dynamic>),
    );
    _api.tableSession = ctx.sessionToken;
    // A PIN entered for an earlier table session means nothing for this one.
    _api.tablePin = null;
    return ctx;
  }

  @override
  Future<CafeConfig> config(String slug, String language) async => CafeConfig.fromJson(await _api.get<Map<String, dynamic>>('/public/cafes/$slug/config', query: {'lang': language}));
}
