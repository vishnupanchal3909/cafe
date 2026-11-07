import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'tokens.dart';

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
  static ThemeData admin(Brightness b) {
    final dark = b == Brightness.dark;
    final seeded = ColorScheme.fromSeed(seedColor: const Color(0xFF3F4BC4), brightness: b);
    // Deep indigo with a cyan accent, on cool paper.
    return _polished(dark ? seeded : seeded.copyWith(primary: const Color(0xFF3A43B8), secondary: const Color(0xFF0E8FA6), tertiary: const Color(0xFF7A4CC2), surface: Colors.white, outlineVariant: const Color(0xFFDCE0EE)), dark ? null : const Color(0xFFF3F5FB)).copyWith(visualDensity: VisualDensity.compact);
  }

  /// Running a cafe: warm and business-like. Coffee brown with an amber accent, on cream paper.
  static ThemeData owner(Brightness b) {
    final dark = b == Brightness.dark;
    final seeded = ColorScheme.fromSeed(seedColor: const Color(0xFF6F4E37), brightness: b);
    return _polished(dark ? seeded : seeded.copyWith(primary: const Color(0xFF6B3F1F), secondary: const Color(0xFFB8741A), tertiary: const Color(0xFF2F7D5B), surface: Colors.white, outlineVariant: const Color(0xFFEADFD2)), dark ? null : const Color(0xFFF9F5EF));
  }

  static ThemeData _polished(ColorScheme s, Color? background) {
    final radius = BorderRadius.circular(14);
    final dark = s.brightness == Brightness.dark;
    final shadow = dark ? Colors.black : HSLColor.fromColor(s.primary).withLightness(0.16).toColor();
    return _base(s).copyWith(
      scaffoldBackgroundColor: background ?? s.surface,
      appBarTheme: AppBarTheme(backgroundColor: background ?? s.surface, foregroundColor: s.onSurface, elevation: 0, scrolledUnderElevation: 0, titleSpacing: Space.lg, titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: s.onSurface)),
      // Plain cards still stand off the page, with a shadow in the brand's own shade.
      cardTheme: CardThemeData(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, elevation: 3, shadowColor: shadow.withValues(alpha: dark ? 0.7 : 0.22), color: dark ? s.surfaceContainer : s.surfaceContainerLowest, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: s.outlineVariant.withValues(alpha: 0.6)))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? s.surfaceContainerHigh : s.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: s.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: glossyButton(FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: radius), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16), elevation: 3, shadowColor: shadow.withValues(alpha: 0.5), textStyle: const TextStyle(fontWeight: FontWeight.w700)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: radius), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), side: BorderSide(color: s.outlineVariant), backgroundColor: dark ? s.surfaceContainer : s.surfaceContainerLowest)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: s.primary, foregroundColor: s.onPrimary, elevation: 6, highlightElevation: 10, hoverElevation: 9, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)), backgroundColor: dark ? s.surfaceContainer : s.surfaceContainerLowest, surfaceTintColor: Colors.transparent, elevation: 24, shadowColor: shadow.withValues(alpha: 0.5)),
      popupMenuTheme: PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: radius), elevation: 10, shadowColor: shadow.withValues(alpha: 0.4), color: dark ? s.surfaceContainerHigh : s.surfaceContainerLowest, surfaceTintColor: Colors.transparent),
      tabBarTheme: TabBarThemeData(tabAlignment: TabAlignment.start, dividerColor: s.outlineVariant, labelStyle: const TextStyle(fontWeight: FontWeight.w700), indicatorSize: TabBarIndicatorSize.label),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide(color: s.outlineVariant.withValues(alpha: 0.7)), backgroundColor: dark ? s.surfaceContainer : s.surfaceContainerLowest, selectedColor: s.primary, secondaryLabelStyle: TextStyle(color: s.onPrimary), checkmarkColor: s.onPrimary, elevation: 1.5, pressElevation: 4, shadowColor: shadow.withValues(alpha: 0.3), selectedShadowColor: s.primary.withValues(alpha: 0.6), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      dataTableTheme: DataTableThemeData(headingRowColor: WidgetStatePropertyAll(s.surfaceContainerLow.withValues(alpha: 0.7)), headingTextStyle: TextStyle(fontWeight: FontWeight.w700, color: s.onSurfaceVariant, fontSize: 13), dividerThickness: 0.6, horizontalMargin: Space.lg, columnSpacing: Space.xl, dataRowMinHeight: 52, dataRowMaxHeight: 60),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: radius), elevation: 8),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: dark ? s.surfaceContainer : s.surfaceContainerLowest, surfaceTintColor: Colors.transparent, elevation: 16, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    );
  }

  /// Seen from two metres in a hot, bright kitchen: always dark, very high contrast, large type and targets.
  static ThemeData kitchen() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFFFFB74D), brightness: Brightness.dark, surface: const Color(0xFF101010));
    final base = _base(scheme);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B0B0D),
      // Sized from Material's typography: the theme's own text theme has no font sizes to scale yet.
      textTheme: Typography.material2021().englishLike.merge(Typography.material2021().white).apply(fontSizeFactor: 1.25),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, titleTextStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
      cardTheme: CardThemeData(margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias, elevation: 6, shadowColor: Colors.black, color: scheme.surfaceContainer, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
      filledButtonTheme: FilledButtonThemeData(style: glossyButton(FilledButton.styleFrom(minimumSize: const Size(120, 64), elevation: 4, shadowColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surfaceContainer, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
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
    final corner = switch (t.buttonStyle) { 'pill' => 28.0, 'square' => 4.0, _ => 14.0 };
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner));
    // The cafe's colours, with the same depth as the staff apps. Corners follow the cafe's chosen button style.
    final polished = _polished(scheme, background);
    return polished.copyWith(
      appBarTheme: polished.appBarTheme.copyWith(titleTextStyle: polished.appBarTheme.titleTextStyle?.copyWith(fontSize: 20)),
      filledButtonTheme: FilledButtonThemeData(style: glossyButton(FilledButton.styleFrom(shape: shape, minimumSize: const Size(64, 50), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16), elevation: 3, shadowColor: HSLColor.fromColor(primary).withLightness(0.16).toColor().withValues(alpha: 0.5), textStyle: const TextStyle(fontWeight: FontWeight.w700)))),
    );
  }
}

/// A lit, rounded look for any button: brighter at the top, a little deeper at the bottom.
/// Laid over whatever colour the button already has, so tonal and disabled buttons keep their own.
/// Apply it last, after the shape is set: the sheen is cut to that shape.
ButtonStyle glossyButton(ButtonStyle style) => style.copyWith(
      backgroundBuilder: (context, states, child) => states.contains(WidgetState.disabled)
          ? child!
          : DecoratedBox(
              decoration: ShapeDecoration(
                shape: style.shape?.resolve(states) ?? const StadiumBorder(),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.02), Colors.black.withValues(alpha: 0.12)]),
              ),
              child: child,
            ),
    );

/// A rich backdrop for white text. Built at fixed lightness, because dark themes make their primary colour pale.
LinearGradient brandGradient(ColorScheme scheme) {
  final base = HSLColor.fromColor(scheme.primary);
  final tone = base.withSaturation(base.saturation.clamp(0.45, 0.65));
  return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [tone.withLightness(0.13).toColor(), tone.withLightness(0.24).toColor(), tone.withLightness(0.36).toColor()]);
}

(MaterialColor, IconData) _statusStyle(String status) => switch (status) {
      'placed' || 'new' || 'pending_approval' || 'requested' || 'open' => (Colors.blue, Icons.fiber_new),
      'available' => (Colors.green, Icons.event_seat),
      'occupied' => (Colors.orange, Icons.people),
      'reserved' => (Colors.indigo, Icons.event_available),
      'cleaning' => (Colors.teal, Icons.cleaning_services),
      'accepted' || 'partially_paid' || 'partially_refunded' => (Colors.teal, Icons.check),
      'preparing' || 'pending' || 'pending_payment' || 'unpaid' => (Colors.orange, Icons.schedule),
      'ready' || 'active' || 'paid' || 'succeeded' => (Colors.green, Icons.check_circle),
      'served' || 'completed' => (Colors.blueGrey, Icons.done_all),
      'cancelled' || 'suspended' || 'failed' || 'refunded' || 'rejected' => (Colors.red, Icons.cancel),
      _ => (Colors.grey, Icons.circle_outlined),
    };

/// The colour for a status, for accents next to a [StatusChip]. Never the only sign of the status.
Color statusColor(String status) => _statusStyle(status).$1;

/// Colour and an icon together, so status never depends on colour alone.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.status});
  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle(status);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? color.shade200 : color.shade800;
    // Sizes to its content, so a longer translation is never clipped inside a table cell.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: ink),
        const SizedBox(width: 5),
        Flexible(child: Text(label, overflow: TextOverflow.visible, softWrap: false, style: TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
