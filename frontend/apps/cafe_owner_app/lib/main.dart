import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_localization/shared_localization.dart';
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
  Set<String> _permissions = const {};
  Locale? _locale;

  bool get _signedIn => _profile != null;

  /// The permission each screen's main list needs. A role sees only the screens it can use; the rest are open to all staff.
  static const _screenPermission = {
    '/dashboard': 'reports.read', '/orders': 'orders.read', '/menu': 'menu.read', '/payments': 'payments.read', '/tables': 'tables.read',
    '/staff': 'staff.read', '/inventory': 'inventory.read', '/finance': 'finance.read', '/marketing': 'marketing.manage', '/settings': 'cafe.profile.read',
  };

  /// The signed-in person's main role: the most senior one if they hold several.
  String? get _roleCode {
    final codes = (((_profile?['user'] as Map?)?['roles'] as List?) ?? const []).cast<Map<dynamic, dynamic>>().map((r) => '${r['code']}').toList();
    return const ['owner', 'manager', 'cashier', 'waiter', 'kitchen_staff'].firstWhere(codes.contains, orElse: () => codes.isEmpty ? '' : codes.first);
  }

  String? _roleLabel(AppLocalizations l) {
    final code = _roleCode;
    if (code == null || code.isEmpty) return null;
    final custom = (((_profile?['user'] as Map?)?['roles'] as List?) ?? const []).cast<Map<dynamic, dynamic>>().firstWhere((r) => r['code'] == code)['name'];
    return switch (code) { 'owner' => l.roleOwner, 'manager' => l.roleManager, 'cashier' => l.roleCashier, 'waiter' => l.roleWaiter, 'kitchen_staff' => l.roleKitchen, _ => '$custom' };
  }

  /// A fixed colour per role, so two windows side by side are told apart at a glance. The badge always names the role too.
  Color _roleColor() => switch (_roleCode) {
        'owner' => Colors.amber.shade700,
        'manager' => Colors.deepPurple,
        'cashier' => Colors.green.shade600,
        'waiter' => Colors.blue.shade600,
        'kitchen_staff' => Colors.deepOrange,
        _ => Colors.blueGrey,
      };

  bool _allowed(String path) => !_screenPermission.containsKey(path) || _permissions.contains(_screenPermission[path]);

  /// Where this person lands: the first everyday screen their role can use.
  String get _home => const ['/dashboard', '/orders', '/menu', '/tables', '/payments'].firstWhere(_allowed, orElse: () => '/notifications');

  Future<void> _loadProfile() async {
    try {
      // Every role may read this. The full profile holds legal and tax details that a cashier or waiter may not see.
      final p = await _repo.workspace();
      final branches = (p['branches'] as List).cast<Map<dynamic, dynamic>>();
      if (branches.isNotEmpty) _repo.api.branchId ??= branches.first['public_id'] as String;
      _repo.currency = p['currencyCode'] as String;
      _repo.cafeName = '${p['name'] ?? ''}';
      _repo.permissions = ((p['permissions'] as List?) ?? const []).cast<String>().toSet();
      _repo.unpaidAlertMinutes = ((p['settings'] as Map?)?['unpaidAlertMinutes'] as int?) ?? 60;
      _permissions = ((p['permissions'] as List?) ?? const []).cast<String>().toSet();
      _profile = p;
    } on ApiFailure {
      _profile = null;
      _permissions = const {};
    }
    _auth.value++;
    if (mounted) setState(() {});
  }

  late final _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _auth,
    redirect: (_, s) {
      // Nothing loads until the session is known, so no screen fires a request it would have to retry.
      // A reload or a typed address waits for the session, then carries on to the page that was asked for.
      if (!_ready) return s.matchedLocation == '/splash' ? null : Uri(path: '/splash', queryParameters: {'from': s.uri.toString()}).toString();
      if (s.matchedLocation == '/splash') {
        if (!_signedIn) return '/login';
        final from = s.uri.queryParameters['from'];
        final path = from == null ? null : Uri.parse(from).path;
        return path != null && path != '/' && path != '/login' && path != '/register' && _allowed(path) ? from : _home;
      }
      final open = s.matchedLocation == '/login' || s.matchedLocation == '/register';
      if (!_signedIn) return open ? null : '/login';
      if (open) return _home;
      // A screen this role cannot use would only show a permission error.
      return _allowed(s.matchedLocation) ? null : _home;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: SkeletonList())),
      GoRoute(path: '/login', builder: (c, _) => LoginView(
            title: c.l10n.signIn,
            tagline: c.l10n.loginTagline,
            icon: Icons.storefront_outlined,
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
            userName: (p?['user'] as Map?)?['fullName'] as String?,
            role: _roleLabel(l),
            roleColor: _roleColor(),
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
              for (final d in [
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
              ])
                if (_allowed(d.path)) d,
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
          // The browser tab says whose portal it is, e.g. "Cashier · Tea Hub".
          onGenerateTitle: (c) => _profile == null ? c.l10n.signIn : [_roleLabel(c.l10n), '${_profile!['name'] ?? ''}'].whereType<String>().join(' · '),
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
