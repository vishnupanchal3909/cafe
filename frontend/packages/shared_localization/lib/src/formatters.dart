import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_core/shared_core.dart';

/// Currency display comes from the viewer's locale and the currency's real precision.
/// No symbol or decimal count is written anywhere in app code.
class MoneyFormatter {
  const MoneyFormatter({required this.locale, this.minorUnits = const {}});

  final String locale;

  /// From the backend's currency table. Unknown currencies fall back to the locale library's own data.
  final Map<String, int> minorUnits;

  String format(Money money) {
    final f = NumberFormat.simpleCurrency(locale: locale, name: money.currency, decimalDigits: minorUnits[money.currency]);
    return DecimalFormatter(f).format(money.amount);
  }

  String formatAmount(String amount, String currency) => format(Money(Decimal.parse(amount), currency));
}

class AppDateFormat {
  const AppDateFormat(this.locale);
  final String locale;
  String date(DateTime d) => DateFormat.yMMMd(locale).format(d.toLocal());
  String time(DateTime d) => DateFormat.jm(locale).format(d.toLocal());
  String dateTime(DateTime d) => '${date(d)} ${time(d)}';
  String number(num n) => NumberFormat.decimalPattern(locale).format(n);
}

extension FormatContext on BuildContext {
  String get localeTag => Localizations.localeOf(this).toLanguageTag().replaceAll('-', '_');
  AppDateFormat get dates => AppDateFormat(localeTag);
}
