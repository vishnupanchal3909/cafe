import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';
import 'config.dart';
import 'core/owner_repository.dart';
import 'features/screens.dart';

void main() {
  usePathUrlStrategy();
  final api = ApiClient(baseUrl: apiBaseUrl, tokens: PlatformTokenStore('owner'));
  GetIt.I
    ..registerSingleton<OwnerRepository>(OwnerRepository(api))
    ..registerSingleton<RealtimeClient>(RealtimeClient(apiBaseUrl));
  runApp(const OwnerApp());
}

class OwnerApp extends StatefulWidget {
  const OwnerApp({super.key});
  @override
  State<OwnerApp> createState() => _OwnerAppState();
}

class _OwnerAppState extends State<OwnerApp> {
  OwnerRepository get _repo => GetIt.I<OwnerRepository>();
  final _auth = ValueNotifier(0);
  bool _ready = false;
  Map<String, dynamic>? _profile;
  Locale? _locale;

  bool get _signedIn => _profile != null;

  Future<void> _loadProfile() async {
    try {
      final p = await _repo.profile();
      final branches = (p['branches'] as List).cast<Map<dynamic, dynamic>>();
      if (branches.isNotEmpty) _repo.api.branchId ??= branches.first['public_id'] as String;
      _repo.currency = p['currencyCode'] as String;
      _profile = p;
    } on ApiFailure {
      _profile = null;
    }
    _auth.value++;
    if (mounted) setState(() {});
  }

  late final _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _auth,
    redirect: (_, s) {
      // Nothing loads until the session is known, so no screen fires a request it would have to retry.
      if (!_ready) return s.matchedLocation == '/splash' ? null : '/splash';
      if (s.matchedLocation == '/splash') return _signedIn ? '/dashboard' : '/login';
      final open = s.matchedLocation == '/login' || s.matchedLocation == '/register';
      if (!_signedIn) return open ? null : '/login';
      return open ? '/dashboard' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: SkeletonList())),
      GoRoute(path: '/login', builder: (c, _) => LoginView(
            title: c.l10n.signIn,
            onSubmit: (e, p, _) async {
              try {
                await _repo.signIn(e, p);
              } on ApiFailure catch (f) {
                if (f.code != 'CAFE_SELECTION_REQUIRED' || !c.mounted) rethrow;
                final cafes = (f.details as List).cast<Map<dynamic, dynamic>>();
                final chosen = await showFormDialog(c, title: c.l10n.chooseCafe, fields: [CrudField('id', c.l10n.chooseCafe, options: [for (final x in cafes) (x['publicId'] as String, x['name'] as String)])]);
                if (chosen == null) return;
                await _repo.signIn(e, p, cafeId: chosen['id']);
              }
              await _loadProfile();
            },
            footer: TextButton(onPressed: () => c.go('/register'), child: Text(c.l10n.registerCafe)),
          )),
      GoRoute(path: '/register', builder: (_, _) => RegisterScreen(onDone: _loadProfile)),
      ShellRoute(
        builder: (c, s, child) {
          final l = c.l10n;
          final p = _profile;
          final branches = ((p?['branches'] as List?) ?? const []).cast<Map<dynamic, dynamic>>();
          return AppShell(
            title: '${p?['name'] ?? ''}',
            currentPath: s.matchedLocation,
            onSelect: c.go,
            actions: [
              if (branches.length > 1)
                DropdownButton<String>(
                  value: _repo.api.branchId,
                  underline: const SizedBox.shrink(),
                  items: [for (final b in branches) DropdownMenuItem(value: b['public_id'] as String, child: Text(b['name'] as String))],
                  onChanged: (v) => setState(() => _repo.api.branchId = v),
                ),
              LanguageMenu(languages: [for (final loc in supportedAppLocales) (loc.languageCode, loc.languageCode)], onSelected: (code) => setState(() { _locale = Locale(code); _repo.api.language = code; })),
              IconButton(tooltip: l.signOut, icon: const Icon(Icons.logout), onPressed: () async { await _repo.signOut(); _profile = null; _auth.value++; }),
            ],
            destinations: [
              ShellDestination(label: l.dashboard, icon: Icons.space_dashboard_outlined, path: '/dashboard'),
              ShellDestination(label: l.orders, icon: Icons.receipt_long, path: '/orders'),
              ShellDestination(label: l.menuManage, icon: Icons.restaurant_menu, path: '/menu'),
              ShellDestination(label: l.payments, icon: Icons.payments_outlined, path: '/payments'),
              ShellDestination(label: l.tables, icon: Icons.table_restaurant, path: '/tables'),
              ShellDestination(label: l.staff, icon: Icons.badge_outlined, path: '/staff'),
              ShellDestination(label: l.inventory, icon: Icons.inventory_2_outlined, path: '/inventory'),
              ShellDestination(label: l.finance, icon: Icons.account_balance_outlined, path: '/finance'),
              ShellDestination(label: l.marketing, icon: Icons.campaign_outlined, path: '/marketing'),
              ShellDestination(label: l.settings, icon: Icons.settings_outlined, path: '/settings'),
              ShellDestination(label: l.notifications, icon: Icons.notifications_outlined, path: '/notifications'),
            ],
            child: Column(children: [
              if (p?['status'] == 'pending_approval') MaterialBanner(content: Text(l.pendingApproval), actions: const [SizedBox.shrink()]),
              Expanded(child: child),
            ]),
          );
        },
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
          GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
          GoRoute(path: '/menu', builder: (_, _) => MenuScreen(defaultLanguage: '${_profile?['defaultLanguage'] ?? 'en'}')),
          GoRoute(path: '/payments', builder: (_, _) => const PaymentsScreen()),
          GoRoute(path: '/tables', builder: (_, _) => const TablesScreen()),
          GoRoute(path: '/staff', builder: (_, _) => const StaffScreen()),
          GoRoute(path: '/inventory', builder: (_, _) => const InventoryScreen()),
          GoRoute(path: '/finance', builder: (_, _) => const FinanceScreen()),
          GoRoute(path: '/marketing', builder: (_, _) => MarketingScreen(language: '${_profile?['defaultLanguage'] ?? 'en'}')),
          GoRoute(path: '/settings', builder: (_, _) => SettingsScreen(language: '${_profile?['defaultLanguage'] ?? 'en'}')),
        ],
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _repo.api.onSessionExpired = () { _profile = null; _auth.value++; };
    _repo.api.restoreSession().then((ok) async {
      if (ok) await _loadProfile();
      setState(() => _ready = true);
      _auth.value++;
    });
  }

  @override
  Widget build(BuildContext context) => MoneyScope(
        minorUnits: _repo.currency.isEmpty ? const {} : {if (_profile?['currencyMinorUnit'] is int) _repo.currency: _profile!['currencyMinorUnit'] as int},
        countryCode: _profile?['countryCode'] as String?,
        child: MaterialApp.router(
          onGenerateTitle: (c) => c.l10n.dashboard,
          theme: AppThemes.owner(Brightness.light),
          darkTheme: AppThemes.owner(Brightness.dark),
          locale: _locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: appLocalizationDelegates,
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      );
}
