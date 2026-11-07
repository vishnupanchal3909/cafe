import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';
import 'config.dart';
import 'core/admin_repository.dart';
import 'features/screens.dart';

void main() {
  usePathUrlStrategy();
  final api = ApiClient(baseUrl: apiBaseUrl, tokens: PlatformTokenStore('admin'));
  GetIt.I.registerSingleton<AdminRepository>(AdminRepository(api));
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});
  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  AdminRepository get _repo => GetIt.I<AdminRepository>();
  bool _ready = false;
  bool _signedIn = false;
  bool _needsMfa = false;

  late final _router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _auth,
    redirect: (_, s) => !_ready ? (s.matchedLocation == '/splash' ? null : '/splash') : s.matchedLocation == '/splash' ? (_signedIn ? '/dashboard' : '/login') : !_signedIn ? (s.matchedLocation == '/login' ? null : '/login') : _needsMfa ? '/mfa' : (s.matchedLocation == '/login' || s.matchedLocation == '/mfa' ? '/dashboard' : null),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: SkeletonList())),
      GoRoute(path: '/login', builder: (c, _) => LoginView(title: c.l10n.adminConsole, tagline: c.l10n.adminLoginTagline, icon: Icons.hub_outlined, paneIcons: const [Icons.storefront, Icons.insights, Icons.verified_user_outlined], onSubmit: (e, p, t) async {
        _needsMfa = await _repo.signIn(e, p, t);
        _signedIn = true;
        _auth.value++;
      })),
      GoRoute(path: '/mfa', builder: (_, _) => MfaScreen(onDone: () { _needsMfa = false; _auth.value++; })),
      ShellRoute(
        builder: (c, s, child) {
          final l = c.l10n;
          return AppShell(
            title: l.adminConsole,
            currentPath: s.matchedLocation,
            onSelect: c.go,
            actions: [IconButton(tooltip: l.signOut, icon: const Icon(Icons.logout), onPressed: () async { await _repo.signOut(); _signedIn = false; _auth.value++; })],
            destinations: [
              ShellDestination(label: l.dashboard, icon: Icons.insights, path: '/dashboard'),
              ShellDestination(label: l.cafes, icon: Icons.storefront, path: '/cafes'),
              ShellDestination(label: l.users, icon: Icons.people_outline, path: '/users'),
              ShellDestination(label: l.settings, icon: Icons.tune, path: '/reference'),
              ShellDestination(label: l.plans, icon: Icons.card_membership, path: '/plans'),
              ShellDestination(label: l.currency, icon: Icons.currency_exchange, path: '/rates'),
              ShellDestination(label: l.support, icon: Icons.support_agent, path: '/support'),
              ShellDestination(label: l.auditLogs, icon: Icons.history, path: '/audit'),
              ShellDestination(label: l.health, icon: Icons.monitor_heart, path: '/health'),
            ],
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/cafes', builder: (_, _) => const CafesScreen()),
          GoRoute(path: '/users', builder: (_, _) => const UsersScreen()),
          GoRoute(path: '/reference', builder: (_, _) => const ReferenceScreen()),
          GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
          GoRoute(path: '/rates', builder: (_, _) => const CurrenciesScreen()),
          GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
          GoRoute(path: '/audit', builder: (_, _) => const AuditScreen()),
          GoRoute(path: '/health', builder: (_, _) => const HealthScreen()),
        ],
      ),
    ],
  );
  final _auth = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _repo.api.onSessionExpired = () { _signedIn = false; _auth.value++; };
    _repo.api.restoreSession().then((ok) { setState(() { _signedIn = ok; _ready = true; }); _auth.value++; });
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        onGenerateTitle: (c) => c.l10n.adminConsole,
        theme: AppThemes.admin(Brightness.light),
        darkTheme: AppThemes.admin(Brightness.dark),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: appLocalizationDelegates,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      );
}
