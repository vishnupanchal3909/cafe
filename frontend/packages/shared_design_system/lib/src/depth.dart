import 'package:flutter/material.dart';

/// Light comes from above. Shadows take a deep shade of the theme's own colour, so depth looks part of the brand, not grey.
List<BoxShadow> depthShadows(ColorScheme s, {double lift = 1}) {
  final dark = s.brightness == Brightness.dark;
  final tint = dark ? Colors.black : HSLColor.fromColor(s.primary).withLightness(0.16).toColor();
  double a(double v) => (dark ? v * 2.6 : v).clamp(0.0, 1.0);
  return [
    BoxShadow(color: tint.withValues(alpha: a(0.06)), blurRadius: 1.5, offset: const Offset(0, 1)),
    BoxShadow(color: tint.withValues(alpha: a(0.07)), blurRadius: 8 * lift, offset: Offset(0, 4 * lift)),
    BoxShadow(color: tint.withValues(alpha: a(0.11)), blurRadius: 28 * lift, offset: Offset(0, 16 * lift), spreadRadius: -8),
  ];
}

/// A shade of [c] at a fixed lightness, so white on it stays readable whatever the theme did to the colour.
Color toneOf(Color c, double lightness) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness(lightness).withSaturation(hsl.saturation.clamp(0.0, 0.85)).toColor();
}

/// The face of a raised surface: a touch lighter at the top, as if lit from above.
LinearGradient faceGradient(ColorScheme s, {Color? color}) {
  if (color != null) return LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, 0.12)!, color]);
  final dark = s.brightness == Brightness.dark;
  return LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: dark ? [s.surfaceContainerHigh, s.surfaceContainer] : [s.surfaceContainerLowest, Color.lerp(s.surfaceContainerLowest, s.surfaceContainerLow, 0.7)!]);
}

bool _motion(BuildContext c) => !(MediaQuery.maybeDisableAnimationsOf(c) ?? false);

/// A card that stands off the page. It lifts and leans toward the pointer on hover, with a sheen where the light catches it.
/// Touch screens and reduced-motion settings get the depth without the movement.
class Raised extends StatefulWidget {
  const Raised({super.key, required this.child, this.padding = EdgeInsets.zero, this.radius = 20, this.onTap, this.tilt = false, this.lift = 1, this.color, this.gradient, this.glow});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  /// Leans toward the pointer. Best on small tiles; a big table leaning would only distract.
  final bool tilt;
  final double lift;
  final Color? color;
  final Gradient? gradient;

  /// A coloured halo, for a surface that needs attention.
  final Color? glow;

  @override
  State<Raised> createState() => _RaisedState();
}

class _RaisedState extends State<Raised> {
  Offset _pointer = Offset.zero;
  bool _hover = false;
  bool _pressed = false;

  void _track(PointerEvent e) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    setState(() {
      _hover = true;
      _pointer = Offset((e.localPosition.dx / size.width) * 2 - 1, (e.localPosition.dy / size.height) * 2 - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final dark = s.brightness == Brightness.dark;
    final motion = _motion(context);
    final active = motion && _hover;
    final lean = active && widget.tilt;
    final radius = BorderRadius.circular(widget.radius);
    final transform = Matrix4.identity()..setEntry(3, 2, 0.0011);
    if (motion) {
      transform.translateByDouble(0.0, active ? -3.0 : 0.0, 0.0, 1.0);
      if (lean) transform..rotateX(-_pointer.dy * 0.06)..rotateY(_pointer.dx * 0.06);
      if (_pressed) transform.scaleByDouble(0.985, 0.985, 1.0, 1.0);
    }
    final shadows = [
      ...depthShadows(s, lift: widget.lift * (active ? 1.7 : 1)),
      if (widget.glow != null) BoxShadow(color: widget.glow!.withValues(alpha: dark ? 0.55 : 0.4), blurRadius: 22, spreadRadius: -2),
    ];
    return MouseRegion(
      onHover: motion ? _track : null,
      onExit: (_) => setState(() { _hover = false; _pointer = Offset.zero; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: transform,
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: radius, gradient: widget.gradient ?? faceGradient(s, color: widget.color), boxShadow: shadows),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(fit: StackFit.passthrough, children: [
            Material(
              type: MaterialType.transparency,
              child: widget.onTap == null
                  ? Padding(padding: widget.padding, child: widget.child)
                  : InkWell(onTap: widget.onTap, onHighlightChanged: (v) => setState(() => _pressed = v), child: Padding(padding: widget.padding, child: widget.child)),
            ),
            if (lean)
              Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(_pointer.dx, _pointer.dy), radius: 1.1, colors: [Colors.white.withValues(alpha: dark ? 0.07 : 0.22), Colors.white.withValues(alpha: 0)]))))),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _RimPainter(widget.radius, dark, widget.gradient != null || widget.color != null ? null : s.outlineVariant)))),
          ]),
        ),
      ),
    );
  }
}

/// A bevel: a bright edge along the top fading down the sides, the way light catches a raised edge.
class _RimPainter extends CustomPainter {
  _RimPainter(this.radius, this.dark, this.outline);
  final double radius;
  final bool dark;
  final Color? outline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius));
    if (outline != null) canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = outline!.withValues(alpha: dark ? 0.35 : 0.55));
    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.white.withValues(alpha: dark ? 0.16 : 0.9), Colors.white.withValues(alpha: 0)]).createShader(rect);
    canvas.drawRRect(rrect, highlight);
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.radius != radius || old.dark != dark || old.outline != outline;
}

/// A glossy, lit badge: the colour as a gem with a highlight on top and a coloured shadow under it.
class GlossyIcon extends StatelessWidget {
  const GlossyIcon({super.key, this.icon, this.child, this.color, this.size = 44, this.circle = false});
  final IconData? icon;

  /// Shown instead of [icon], for a letter or a photo.
  final Widget? child;
  final Color? color;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final base = toneOf(color ?? Theme.of(context).colorScheme.primary, 0.42);
    final radius = circle ? BorderRadius.circular(size) : BorderRadius.circular(size * 0.3);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [toneOf(base, 0.58), base, toneOf(base, 0.3)]),
        boxShadow: [BoxShadow(color: base.withValues(alpha: 0.45), blurRadius: size * 0.4, offset: Offset(0, size * 0.18), spreadRadius: -size * 0.08)],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(fit: StackFit.expand, children: [
          Center(child: child ?? Icon(icon, size: size * 0.5, color: Colors.white, shadows: [Shadow(color: toneOf(base, 0.2).withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(0, 1))])),
          Positioned(
            top: 0,
            left: size * 0.08,
            right: size * 0.08,
            height: size * 0.48,
            child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(size, size * 0.3)), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.04)])))),
          ),
        ]),
      ),
    );
  }
}

/// A deep brand backdrop with glowing light and a floor grid running into the distance.
/// Painted once and never animated, so it costs nothing while the screen is in use.
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({super.key, required this.child, this.floor = true});
  final Widget child;
  final bool floor;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return CustomPaint(painter: _AuroraPainter(toneOf(s.primary, 0.5), toneOf(s.secondary, 0.55), floor), child: child);
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.primary, this.secondary, this.floor);
  final Color primary;
  final Color secondary;
  final bool floor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [toneOf(primary, 0.07), toneOf(primary, 0.14), toneOf(primary, 0.1)]).createShader(rect));
    void glow(Offset c, double r, Color color, double alpha) => canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    final m = size.shortestSide;
    glow(Offset(size.width * 0.18, size.height * 0.2), m * 0.75, primary, 0.55);
    glow(Offset(size.width * 0.85, size.height * 0.12), m * 0.6, secondary, 0.35);
    glow(Offset(size.width * 0.7, size.height * 0.95), m * 0.7, primary, 0.4);
    if (!floor) return;
    // A grid on the floor, drawn in perspective toward a vanishing point at the horizon.
    final horizon = size.height * 0.64;
    final floorRect = Rect.fromLTRB(0, horizon, size.width, size.height);
    final line = Paint()
      ..strokeWidth = 1
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.13)]).createShader(floorRect);
    for (var i = 1; i <= 12; i++) {
      final t = i / 12;
      final y = horizon + (size.height - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final vanish = Offset(size.width / 2, horizon);
    for (var i = -14; i <= 14; i++) {
      canvas.drawLine(vanish, Offset(size.width / 2 + i * size.width * 0.12, size.height), line);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.primary != primary || old.secondary != secondary || old.floor != floor;
}

/// The working background behind every screen: the theme's paper, with soft light falling from the top corners.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = theme.colorScheme;
    final dark = s.brightness == Brightness.dark;
    return CustomPaint(painter: _AmbientPainter(theme.scaffoldBackgroundColor, s.primary, s.secondary, dark), child: child);
  }
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.paper, this.primary, this.secondary, this.dark);
  final Color paper;
  final Color primary;
  final Color secondary;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    void glow(Offset c, double r, Color color, double alpha) => canvas.drawCircle(c, r, Paint()..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r)));
    glow(Offset(size.width * 0.95, 0), size.shortestSide * 0.7, secondary, dark ? 0.10 : 0.12);
    glow(Offset(size.width * 0.15, -size.height * 0.1), size.shortestSide * 0.6, primary, dark ? 0.12 : 0.06);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.paper != paper || old.primary != primary || old.secondary != secondary || old.dark != dark;
}

/// Rises into place and tips upright, once, when it first appears. Nothing loops, so screens settle.
class FloatIn extends StatelessWidget {
  const FloatIn({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    if (!_motion(context)) return child;
    final total = const Duration(milliseconds: 650) + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform(alignment: Alignment.bottomCenter, transform: Matrix4.identity()..setEntry(3, 2, 0.0012)..translateByDouble(0.0, (1 - t) * 36, 0.0, 1.0)..rotateX((1 - t) * 0.35), child: child),
      ),
    );
  }
}

/// Three tilted panes floating one above another, each carrying one of [icons]. Decoration only: it shows no data.
class FloatingPanes extends StatelessWidget {
  const FloatingPanes({super.key, required this.icons, this.size = 300});
  final List<IconData> icons;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final tones = [s.primary, s.secondary, s.tertiary];
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 0.92,
        child: Stack(clipBehavior: Clip.none, children: [
          for (final (i, icon) in icons.take(3).indexed)
            Positioned(
              left: size * (0.04 + i * 0.2),
              top: size * (0.42 - i * 0.2),
              child: FloatIn(
                delay: Duration(milliseconds: 120 * i),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.0014)..rotateX(0.32)..rotateY(-0.42)..rotateZ(0.04),
                  child: _Pane(icon: icon, color: tones[i % tones.length], width: size * 0.56),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.icon, required this.color, required this.width});
  final IconData icon;
  final Color color;
  final double width;
  @override
  Widget build(BuildContext context) {
    final bar = Colors.white.withValues(alpha: 0.22);
    return Container(
      width: width,
      height: width * 0.66,
      padding: EdgeInsets.all(width * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.09),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.06)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(18, 30), spreadRadius: -6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GlossyIcon(icon: icon, color: color, size: width * 0.22),
        const Spacer(),
        Container(height: width * 0.04, width: width * 0.6, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(8))),
        SizedBox(height: width * 0.04),
        Container(height: width * 0.04, width: width * 0.38, decoration: BoxDecoration(color: bar, borderRadius: BorderRadius.circular(8))),
      ]),
    );
  }
}
