import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

Color hexColor(String hex) => Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Owners choose any colours, so the result is corrected to stay legible (WCAG AA 4.5:1) rather than trusted.
Color readableOn(Color background, Color preferred) {
  if (contrastRatio(background, preferred) >= 4.5) return preferred;
  final black = contrastRatio(background, Colors.black);
  final white = contrastRatio(background, Colors.white);
  return black >= white ? Colors.black : Colors.white;
}

abstract final class AppThemes {
  static ThemeData _base(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        visualDensity: VisualDensity.standard,
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );

  /// Platform operations: cool, dense, analytical.
  static ThemeData admin(Brightness b) => _base(ColorScheme.fromSeed(seedColor: const Color(0xFF34507A), brightness: b)).copyWith(visualDensity: VisualDensity.compact);

  /// Running a cafe: warm and business-like.
  static ThemeData owner(Brightness b) => _base(ColorScheme.fromSeed(seedColor: const Color(0xFF6F4E37), brightness: b));

  /// Seen from two metres in a hot, bright kitchen: always dark, very high contrast, large type and targets.
  static ThemeData kitchen() {
    final base = _base(ColorScheme.fromSeed(seedColor: const Color(0xFFFFB74D), brightness: Brightness.dark, surface: const Color(0xFF101010)));
    return base.copyWith(
      // Sized from Material's typography: the theme's own text theme has no font sizes to scale yet.
      textTheme: Typography.material2021().englishLike.merge(Typography.material2021().white).apply(fontSizeFactor: 1.25),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(120, 64), textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
    );
  }

  /// Built only from the cafe's own configuration. Nothing here knows any specific cafe.
  static ThemeData customer(CafeTheme t) {
    final primary = hexColor(t.primaryColor);
    final secondary = hexColor(t.secondaryColor);
    final background = hexColor(t.backgroundColor);
    final dark = t.themeMode == 'dark';
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: dark ? Brightness.dark : Brightness.light).copyWith(
      primary: primary,
      onPrimary: readableOn(primary, Colors.white),
      secondary: secondary,
      onSecondary: readableOn(secondary, Colors.black),
      surface: background,
      onSurface: readableOn(background, hexColor(t.textColor)),
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(switch (t.buttonStyle) { 'pill' => 28.0, 'square' => 4.0, _ => 12.0 }));
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: background,
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape, minimumSize: const Size(64, 48))),
    );
  }
}

/// Colour and an icon together, so status never depends on colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.status});
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'placed' || 'new' || 'pending_approval' || 'requested' || 'open' => (Colors.blue, Icons.fiber_new),
      'accepted' || 'partially_paid' || 'partially_refunded' => (Colors.teal, Icons.check),
      'preparing' || 'pending' || 'pending_payment' => (Colors.orange, Icons.schedule),
      'ready' || 'active' || 'paid' || 'succeeded' => (Colors.green, Icons.check_circle),
      'served' || 'completed' => (Colors.blueGrey, Icons.done_all),
      'cancelled' || 'suspended' || 'failed' || 'refunded' || 'rejected' => (Colors.red, Icons.cancel),
      _ => (Colors.grey, Icons.circle_outlined),
    };
    // Sizes to its content, so a longer translation is never clipped inside a table cell.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), border: Border.all(color: color.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color.shade700),
        const SizedBox(width: 6),
        Flexible(child: Text(label, overflow: TextOverflow.visible, softWrap: false)),
      ]),
    );
  }
}
