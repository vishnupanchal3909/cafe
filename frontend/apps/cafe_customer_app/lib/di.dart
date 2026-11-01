import 'package:get_it/get_it.dart';
import 'package:shared_network/shared_network.dart';
import 'config.dart';
import 'features/account/data/account_repository.dart';
import 'features/menu/data/menu_repository.dart';
import 'features/orders/data/order_repository.dart';
import 'features/session/data/session_repository.dart';

void configureDependencies() {
  final g = GetIt.I;
  final api = ApiClient(baseUrl: apiBaseUrl, tokens: PlatformTokenStore('customer'));
  g
    ..registerSingleton<ApiClient>(api)
    ..registerSingleton<RealtimeClient>(RealtimeClient(apiBaseUrl))
    ..registerLazySingleton<SessionRepository>(() => ApiSessionRepository(api))
    ..registerLazySingleton<MenuRepository>(() => ApiMenuRepository(api))
    ..registerLazySingleton<OrderRepository>(() => ApiOrderRepository(api))
    ..registerLazySingleton<AccountRepository>(() => ApiAccountRepository(api));
}
