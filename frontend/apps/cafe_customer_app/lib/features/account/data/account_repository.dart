import 'package:shared_network/shared_network.dart';

abstract class AccountRepository {
  bool get signedIn;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password, String name, String language);
  Future<void> signOut();
  Future<Map<String, dynamic>> profile();
  Future<List<dynamic>> history();
  Future<List<dynamic>> favorites();
  Future<void> addFavorite(String slug);
  Future<Map<String, dynamic>> loyalty(String slug);
  Future<void> deleteAccount();
  Future<List<dynamic>> addresses();
  Future<void> addAddress(Map<String, dynamic> body);
  Future<void> removeAddress(String id);
  Future<List<dynamic>> wishlist(String slug);
  Future<void> addWish(String slug, String productId);
  Future<void> removeWish(String slug, String productId);
  Future<void> reserve(String slug, Map<String, dynamic> body);
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._api);
  final ApiClient _api;
  @override
  bool get signedIn => _api.tokens.accessToken != null;
  @override
  Future<void> signIn(String email, String password) async => _api.adoptTokens(await _api.post<Map<String, dynamic>>('/customer/auth/login', body: {'email': email, 'password': password, 'transport': _api.transport}));
  @override
  Future<void> register(String email, String password, String name, String language) async => _api.adoptTokens(await _api.post<Map<String, dynamic>>('/customer/auth/register', body: {'email': email, 'password': password, 'fullName': name, 'language': language, 'transport': _api.transport}));
  @override
  Future<void> signOut() => _api.signOut();
  @override
  Future<Map<String, dynamic>> profile() => _api.get<Map<String, dynamic>>('/customer/profile');
  @override
  Future<List<dynamic>> history() async => (await _api.getPage('/customer/history')).items;
  @override
  Future<List<dynamic>> favorites() => _api.get<List<dynamic>>('/customer/favorites');
  @override
  Future<void> addFavorite(String slug) => _api.post<Map<String, dynamic>>('/customer/favorites/$slug');
  @override
  Future<Map<String, dynamic>> loyalty(String slug) => _api.get<Map<String, dynamic>>('/customer/cafes/$slug/loyalty');
  @override
  Future<List<dynamic>> addresses() => _api.get<List<dynamic>>('/customer/addresses');
  @override
  Future<void> addAddress(Map<String, dynamic> body) => _api.post<Map<String, dynamic>>('/customer/addresses', body: body);
  @override
  Future<void> removeAddress(String id) => _api.delete<Map<String, dynamic>>('/customer/addresses/$id');
  @override
  Future<List<dynamic>> wishlist(String slug) => _api.get<List<dynamic>>('/customer/cafes/$slug/wishlist');
  @override
  Future<void> addWish(String slug, String productId) => _api.post<Map<String, dynamic>>('/customer/cafes/$slug/wishlist/$productId');
  @override
  Future<void> removeWish(String slug, String productId) => _api.delete<Map<String, dynamic>>('/customer/cafes/$slug/wishlist/$productId');
  @override
  Future<void> reserve(String slug, Map<String, dynamic> body) => _api.post<Map<String, dynamic>>('/customer/cafes/$slug/reservations', body: body);
  @override
  Future<void> deleteAccount() => _api.delete<Map<String, dynamic>>('/customer/account');
}
