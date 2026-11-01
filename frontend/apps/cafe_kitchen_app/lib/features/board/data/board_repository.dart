import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';

abstract class BoardRepository {
  Future<void> signIn(String email, String password);
  Future<bool> restore();
  Future<void> signOut();
  Future<List<Map<String, dynamic>>> branches();
  void useBranch(String id);
  Future<List<KitchenTicket>> tickets({String? status});
  Future<List<Map<String, dynamic>>> stations();
  Future<void> setStatus(String ticketId, String status);
  Future<void> setPriority(String ticketId, int priority);
  String? get accessToken;
}

class ApiBoardRepository implements BoardRepository {
  ApiBoardRepository(this._api);
  final ApiClient _api;
  @override
  String? get accessToken => _api.tokens.accessToken;
  @override
  Future<void> signIn(String email, String password) async => _api.adoptTokens(await _api.post<Map<String, dynamic>>('/auth/login', body: {'email': email, 'password': password, 'audience': 'kitchen', 'transport': _api.transport}));
  @override
  Future<bool> restore() => _api.restoreSession();
  @override
  Future<void> signOut() => _api.signOut();
  @override
  Future<List<Map<String, dynamic>>> branches() async => (await _api.get<List<dynamic>>('/kitchen/branches')).cast<Map<String, dynamic>>();
  @override
  void useBranch(String id) => _api.branchId = id;
  @override
  Future<List<KitchenTicket>> tickets({String? status}) async => [for (final t in await _api.get<List<dynamic>>('/kitchen/tickets', query: {if (status != null) 'status': status})) KitchenTicket.fromJson(t as Map<String, dynamic>)];
  @override
  Future<List<Map<String, dynamic>>> stations() async => (await _api.get<List<dynamic>>('/kitchen/stations')).cast<Map<String, dynamic>>();
  @override
  Future<void> setStatus(String ticketId, String status) => _api.post<Map<String, dynamic>>('/kitchen/tickets/$ticketId/status', body: {'status': status});
  @override
  Future<void> setPriority(String ticketId, int priority) => _api.post<Map<String, dynamic>>('/kitchen/tickets/$ticketId/priority', body: {'priority': priority});
}
