import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_localization/shared_localization.dart';

abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class Breakpoints {
  static const compact = 600.0;
  static const medium = 900.0;
  static const expanded = 1200.0;
  static bool isCompact(BuildContext c) => MediaQuery.sizeOf(c).width < compact;
}

const supportedAppLocales = AppLocalizations.supportedLocales;
const appLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
