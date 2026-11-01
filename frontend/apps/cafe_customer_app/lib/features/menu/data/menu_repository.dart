import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';

abstract class MenuRepository {
  Future<Menu> load({required String slug, required String language, String? branchId});
}

class ApiMenuRepository implements MenuRepository {
  ApiMenuRepository(this._api);
  final ApiClient _api;
  @override
  Future<Menu> load({required String slug, required String language, String? branchId}) async =>
      Menu.fromJson(await _api.get<Map<String, dynamic>>('/public/cafes/$slug/menu', query: {'lang': language, if (branchId != null) 'branch': branchId}));
}
