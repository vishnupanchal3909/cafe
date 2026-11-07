import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_network/shared_network.dart';
import 'config.dart';
import 'features/board/data/board_repository.dart';
import 'features/board/presentation/board_page.dart';

void configureDependencies() {
  final api = ApiClient(baseUrl: apiBaseUrl, tokens: PlatformTokenStore('kitchen'));
  GetIt.I
    ..registerSingleton<ApiClient>(api)
    ..registerSingleton<RealtimeClient>(RealtimeClient(apiBaseUrl))
    ..registerSingleton<BoardRepository>(ApiBoardRepository(api));
}

void main() {
  configureDependencies();
  runApp(const KitchenApp());
}

class KitchenApp extends StatelessWidget {
  const KitchenApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (c) => c.l10n.kitchenDisplay,
        theme: AppThemes.kitchen(),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: appLocalizationDelegates,
        debugShowCheckedModeBanner: false,
        home: const KitchenRoot(),
      );
}

class KitchenRoot extends StatefulWidget {
  const KitchenRoot({super.key});
  @override
  State<KitchenRoot> createState() => _KitchenRootState();
}

class _KitchenRootState extends State<KitchenRoot> {
  BoardRepository get _repo => GetIt.I<BoardRepository>();
  bool _ready = false;
  bool _signedIn = false;
  String? _branch;

  @override
  void initState() {
    super.initState();
    _repo.restore().then((ok) async {
      if (ok) await _afterSignIn();
      if (mounted) setState(() => _ready = true);
    });
  }

  Future<void> _afterSignIn() async {
    final branches = await _repo.branches();
    if (branches.length == 1) _pick(branches.first['public_id'] as String);
    if (mounted) setState(() => _signedIn = true);
  }

  void _pick(String id) {
    _repo.useBranch(id);
    setState(() => _branch = id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (!_ready) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_signedIn) {
      return LoginView(title: l.kitchenDisplay, tagline: l.kitchenLoginTagline, icon: Icons.soup_kitchen_outlined, paneIcons: const [Icons.soup_kitchen_outlined, Icons.timer_outlined, Icons.room_service_outlined], onSubmit: (e, p, _) async { await _repo.signIn(e, p); await _afterSignIn(); });
    }
    if (_branch == null) {
      return AmbientBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l.selectBranch)),
          body: LoadView<List<Map<String, dynamic>>>(
            load: _repo.branches,
            builder: (c, rows, _) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(padding: const EdgeInsets.all(Space.lg), children: [
                  for (final b in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.md),
                      child: Raised(
                        onTap: () => _pick(b['public_id'] as String),
                        padding: const EdgeInsets.all(Space.lg),
                        child: Row(children: [
                          const GlossyIcon(icon: Icons.storefront_outlined, size: 52),
                          const SizedBox(width: Space.md),
                          Expanded(child: Text(b['name'] as String, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                          const Icon(Icons.arrow_forward_ios),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      );
    }
    return BoardPage(onSignOut: () async {
      await _repo.signOut();
      setState(() { _signedIn = false; _branch = null; });
    });
  }
}
