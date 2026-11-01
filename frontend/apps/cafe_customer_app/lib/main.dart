import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';
import 'di.dart';
import 'features/account/presentation/account_page.dart';
import 'features/cart/presentation/cart_cubit.dart';
import 'features/cart/presentation/cart_page.dart';
import 'features/menu/presentation/menu_page.dart';
import 'features/orders/presentation/order_pages.dart';
import 'features/session/data/session_repository.dart';
import 'features/session/presentation/qr_entry_page.dart';
import 'features/session/presentation/session_cubit.dart';

void main() {
  usePathUrlStrategy();
  configureDependencies();
  runApp(const CustomerApp());
}

final router = GoRouter(initialLocation: '/', routes: [
  GoRoute(path: '/', builder: (_, _) => const NoTablePage()),
  GoRoute(path: '/t/:token', builder: (_, s) => QrEntryPage(token: s.pathParameters['token']!)),
  GoRoute(path: '/menu', builder: (_, _) => const MenuPage()),
  GoRoute(path: '/cart', builder: (_, _) => const CartPage()),
  GoRoute(path: '/orders', builder: (_, _) => const SessionOrdersPage()),
  GoRoute(path: '/orders/:id', builder: (_, s) => OrderTrackPage(orderId: s.pathParameters['id']!)),
  GoRoute(path: '/account', builder: (_, _) => const AccountPage()),
]);

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SessionCubit(GetIt.I<SessionRepository>(), GetIt.I<ApiClient>(), deviceLanguage: ui.PlatformDispatcher.instance.locale.languageCode)),
          BlocProvider(create: (_) => CartCubit()),
        ],
        child: BlocBuilder<SessionCubit, SessionState>(builder: (c, s) {
          final cfg = s.context?.config;
          return MoneyScope(
            minorUnits: cfg == null ? const {} : {cfg.currency.code: cfg.currency.minorUnit},
            countryCode: cfg?.cafe.countryCode,
            child: MaterialApp.router(
              onGenerateTitle: (c) => cfg?.cafe.name ?? c.l10n.menu,
              theme: cfg == null ? AppThemes.owner(Brightness.light) : AppThemes.customer(cfg.theme),
              locale: Locale(s.language),
              supportedLocales: supportedAppLocales,
              localizationsDelegates: appLocalizationDelegates,
              debugShowCheckedModeBanner: false,
              routerConfig: router,
            ),
          );
        }),
      );
}
