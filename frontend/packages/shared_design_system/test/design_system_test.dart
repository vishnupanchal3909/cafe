import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';

Widget host(Widget child, {Size? size}) => MaterialApp(
      supportedLocales: supportedAppLocales,
      localizationsDelegates: appLocalizationDelegates,
      home: MediaQuery(data: MediaQueryData(size: size ?? const Size(1400, 900)), child: Scaffold(body: child)),
    );

const theme = CafeTheme(primaryColor: '#FFFF00', secondaryColor: '#222222', backgroundColor: '#FFFFFF', textColor: '#FFFFFF', fontKey: 'noto_sans', buttonStyle: 'pill', menuLayout: 'grid', themeMode: 'light', version: 1);

void main() {
  group('dynamic cafe themes', () {
    test('uses the configured colours', () {
      final t = AppThemes.customer(theme);
      expect(t.colorScheme.primary, hexColor('#FFFF00'));
      expect(t.scaffoldBackgroundColor, hexColor('#FFFFFF'));
    });
    test('an illegible owner choice is corrected to meet WCAG AA', () {
      final t = AppThemes.customer(theme);
      expect(contrastRatio(t.colorScheme.surface, t.colorScheme.onSurface), greaterThanOrEqualTo(4.5), reason: 'white text on white');
      expect(contrastRatio(t.colorScheme.primary, t.colorScheme.onPrimary), greaterThanOrEqualTo(4.5), reason: 'text on a yellow button');
    });
    test('kitchen is always dark', () => expect(AppThemes.kitchen().brightness, Brightness.dark));
  });

  group('AsyncView shows the right thing for every state', () {
    Widget view(ViewState<String> s) => host(AsyncView<String>(state: s, onRetry: () {}, builder: (d) => Text(d)));
    testWidgets('loading', (t) async { await t.pumpWidget(view(const ViewLoading())); expect(find.byType(SkeletonList), findsOneWidget); });
    testWidgets('empty', (t) async { await t.pumpWidget(view(const ViewEmpty())); expect(find.byType(EmptyState), findsOneWidget); });
    testWidgets('success', (t) async { await t.pumpWidget(view(const ViewSuccess('hello'))); expect(find.text('hello'), findsOneWidget); });
    testWidgets('failure offers retry', (t) async {
      await t.pumpWidget(view(const ViewFailure(ApiFailure.network())));
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('responsive shell', () {
    final dest = [const ShellDestination(label: 'A', icon: Icons.abc, path: '/a'), const ShellDestination(label: 'B', icon: Icons.abc, path: '/b')];
    Widget shell(Size s) => MaterialApp(
          supportedLocales: supportedAppLocales,
          localizationsDelegates: appLocalizationDelegates,
          home: MediaQuery(data: MediaQueryData(size: s), child: AppShell(title: 'T', destinations: dest, currentPath: '/b', onSelect: (_) {}, child: const SizedBox())),
        );
    testWidgets('a wide screen gets a rail', (t) async {
      t.view.physicalSize = const Size(1400, 900); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
      await t.pumpWidget(shell(const Size(1400, 900)));
      expect(find.byType(NavigationRail), findsOneWidget);
    });
    testWidgets('a phone gets a drawer', (t) async {
      t.view.physicalSize = const Size(390, 800); t.view.devicePixelRatio = 1; addTearDown(t.view.reset);
      await t.pumpWidget(shell(const Size(390, 800)));
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('B'), findsOneWidget);
    });
  });

  testWidgets('money displays with the precision from the scope', (t) async {
    await t.pumpWidget(MoneyScope(minorUnits: const {'JPY': 0}, child: host(MoneyText(Money.fromJson(const {'amount': '1500', 'currency': 'JPY'})))));
    expect(find.textContaining('1,500'), findsOneWidget);
    expect(find.textContaining('.00'), findsNothing);
  });

  testWidgets('grouping follows the cafe country, even if that language has no such region in the app', (t) async {
    for (final (country, locale, expected) in [('IN', 'en', '₹1,25,000.00'), ('IN', 'hi', '₹1,25,000.00'), ('US', 'en', '₹125,000.00'), ('JP', 'ar', null)]) {
      await t.pumpWidget(MoneyScope(minorUnits: const {'INR': 2}, countryCode: country, child: MaterialApp(locale: Locale(locale), supportedLocales: supportedAppLocales, localizationsDelegates: appLocalizationDelegates, home: Scaffold(body: MoneyText(Money.fromJson(const {'amount': '125000', 'currency': 'INR'}))))));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: '$locale-$country must not throw');
      if (expected != null) expect(find.text(expected), findsOneWidget, reason: '$locale-$country');
    }
  });

  testWidgets('CrudPage validates required fields and reports server errors', (t) async {
    var created = 0;
    await t.pumpWidget(host(CrudPage(
      load: () async => [{'n': 'row'}],
      columns: [CrudColumn('Name', (r) => r['n'] as String)],
      createFields: const [CrudField('name', 'Name')],
      onCreate: (_, _) async { created++; throw const ApiFailure(code: 'DUPLICATE', message: 'Already exists'); },
    )));
    await t.pumpAndSettle();
    expect(find.text('row'), findsOneWidget);
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(created, 0);
    await t.enterText(find.byType(TextFormField), 'x');
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    expect(created, 1);
    expect(find.text('Already exists'), findsOneWidget);
  });
}

