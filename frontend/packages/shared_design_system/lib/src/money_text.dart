import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'tokens.dart';

/// Currency precision for the subtree, from the backend. All money display goes through here.
class MoneyScope extends InheritedWidget {
  const MoneyScope({super.key, required this.minorUnits, this.countryCode, required super.child});
  final Map<String, int> minorUnits;

  /// The cafe's country decides digit grouping: English in India is 1,25,000, while English elsewhere is 125,000.
  final String? countryCode;
  static MoneyScope? of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<MoneyScope>();
  @override
  bool updateShouldNotify(MoneyScope old) => old.minorUnits != minorUnits || old.countryCode != countryCode;
}

extension MoneyContext on BuildContext {
  MoneyFormatter get money {
    final scope = MoneyScope.of(this);
    final country = scope?.countryCode;
    return MoneyFormatter(locale: country == null ? localeTag : '${Localizations.localeOf(this).languageCode}_$country', minorUnits: scope?.minorUnits ?? const {});
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.style});
  final Money value;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Text(context.money.format(value), style: style);
}

class AmountRow extends StatelessWidget {
  const AmountRow({super.key, required this.label, required this.value, this.bold = false});
  final String label;
  final Money value;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final style = bold ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), MoneyText(value, style: style)]),
    );
  }
}
