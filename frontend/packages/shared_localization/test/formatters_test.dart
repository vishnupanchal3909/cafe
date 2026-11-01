import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';

Money m(String a, String c) => Money(Decimal.parse(a), c);
const units = {'INR': 2, 'USD': 2, 'EUR': 2, 'JPY': 0, 'KWD': 3};

void main() {
  group('the exact examples from the brief', () {
    test('India: lakh grouping', () => expect(const MoneyFormatter(locale: 'en_IN', minorUnits: units).format(m('125000', 'INR')), '₹1,25,000.00'));
    test('United States', () => expect(const MoneyFormatter(locale: 'en_US', minorUnits: units).format(m('1250', 'USD')), r'$1,250.00'));
    test('Germany: separators and trailing symbol', () {
      expect(const MoneyFormatter(locale: 'de_DE', minorUnits: units).format(m('1250', 'EUR')).replaceAll(' ', ' '), '1.250,00 €');
    });
    test('Japan: no decimals', () {
      final out = const MoneyFormatter(locale: 'ja_JP', minorUnits: units).format(m('1250', 'JPY'));
      expect(out.replaceAll('￥', '¥'), '¥1,250');
    });
  });

  test('three-decimal currencies keep their precision', () {
    expect(const MoneyFormatter(locale: 'en_US', minorUnits: units).format(m('1.234', 'KWD')), contains('1.234'));
  });

  test('very large amounts stay exact rather than passing through a double', () {
    final out = const MoneyFormatter(locale: 'en_US', minorUnits: units).format(m('12345678901234.56', 'USD'));
    expect(out.replaceAll(',', ''), contains('12345678901234.56'));
  });

  test('money refuses to combine different currencies', () {
    expect(() => m('1', 'INR') + m('1', 'USD'), throwsArgumentError);
    expect((m('0.1', 'INR') + m('0.2', 'INR')).amount, Decimal.parse('0.3'));
  });

  group('all nine languages', () {
    test('are registered', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(), {'en', 'hi', 'mr', 'es', 'fr', 'de', 'ar', 'pt', 'ja'});
    });

    for (final locale in AppLocalizations.supportedLocales) {
      testWidgets('${locale.languageCode}: Flutter framework text resolves, and placeholders fill in', (t) async {
        late AppLocalizations l;
        await t.pumpWidget(MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          home: Builder(builder: (c) { l = AppLocalizations.of(c); return const Scaffold(body: BackButton()); }),
        ));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(l.addToCart, isNotEmpty);
        expect(l.orderNumber(42), contains('42'));
        expect(l.welcomeTable('T7'), contains('T7'));
        expect(l.orderStatus('ready'), isNot('ready'));
        expect(l.paymentStatus('paid'), isNot('paid'));
      });
    }

    testWidgets('Arabic lays out right to left', (t) async {
      late TextDirection d;
      await t.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: Builder(builder: (c) { d = Directionality.of(c); return const SizedBox(); }),
      ));
      expect(d, TextDirection.rtl);
    });
  });

  test('a status value the client does not know is shown as is, never crashes', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(l.orderStatus('something_new'), 'something_new');
  });
}
