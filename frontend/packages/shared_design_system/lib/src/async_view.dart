import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
import 'depth.dart';
import 'tokens.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});
  final int count;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.all(Space.md),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
      itemBuilder: (_, i) => Container(height: 76, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [color, color.withValues(alpha: 0.45)]))),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message, this.icon = Icons.inbox_outlined, this.action});
  final String? message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatIn(child: GlossyIcon(icon: icon, size: 80, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: Space.lg),
            Text(message ?? context.l10n.emptyTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (action != null) ...[const SizedBox(height: Space.md), action!],
          ]),
        ),
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.failure, this.onRetry});
  final ApiFailure failure;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          GlossyIcon(icon: failure.isNetwork ? Icons.wifi_off : Icons.error_outline, size: 80, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Space.lg),
          Text(l.failureMessage(failure.code, failure.message), textAlign: TextAlign.center),
          if (onRetry != null) ...[const SizedBox(height: Space.md), FilledButton(onPressed: onRetry, child: Text(l.retry))],
        ]),
      ),
    );
  }
}

/// Maps a [ViewState] to its screen. No screen hand-writes loading, empty or error again.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.state, required this.builder, this.onRetry, this.empty});
  final ViewState<T> state;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => switch (state) {
        ViewInitial<T>() || ViewLoading<T>() => const SkeletonList(),
        ViewEmpty<T>() => empty ?? const EmptyState(),
        ViewFailure<T>(failure: final f) => ErrorState(failure: f, onRetry: onRetry),
        ViewSuccess<T>(data: final d) => builder(d),
      };
}

class LoadView<T> extends StatelessWidget {
  const LoadView({super.key, required this.load, required this.builder, this.isEmpty, this.empty});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T, Future<void> Function() reload) builder;
  final bool Function(T)? isEmpty;
  final Widget? empty;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => LoadCubit<T>(load, isEmpty: isEmpty)..load(),
        child: BlocBuilder<LoadCubit<T>, ViewState<T>>(
          builder: (c, s) => AsyncView<T>(state: s, empty: empty, onRetry: () => c.read<LoadCubit<T>>().load(), builder: (d) => builder(c, d, () => c.read<LoadCubit<T>>().load(silent: true))),
        ),
      );
}

void showFailure(BuildContext context, Object error) {
  final l = context.l10n;
  final text = error is ApiFailure ? l.failureMessage(error.code, error.message) : l.errorTitle;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.icon, this.color});
  final String label;
  final String value;
  final IconData? icon;

  /// The icon's accent. Defaults to the theme's primary colour.
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return Raised(
      tilt: true,
      child: Stack(children: [
        // A pool of the accent colour in the corner, as if the badge were lit.
        PositionedDirectional(top: -50, end: -40, child: IgnorePointer(child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0)]))))),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              if (icon != null) ...[GlossyIcon(icon: icon, color: accent, size: 42), const SizedBox(width: 12)],
              Expanded(child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 14),
            FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6))),
          ]),
        ),
      ]),
    );
  }
}

/// A titled card, for one block of a dashboard.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.action, this.icon});
  final String title;
  final Widget child;
  final Widget? action;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Raised(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[GlossyIcon(icon: icon, size: 32), const SizedBox(width: 10)],
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            ?action,
          ]),
          const SizedBox(height: Space.md),
          child,
        ]),
      );
}

/// Upright bars over time. Values come from recorded data only.
class TrendBars extends StatelessWidget {
  const TrendBars({super.key, required this.bars, this.height = 150});
  final List<(String label, double value, String tooltip)> bars;
  final double height;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = bars.fold<double>(0, (m, b) => b.$2 > m ? b.$2 : m);
    return SizedBox(
      height: height,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final b in bars)
          Expanded(
            child: Tooltip(
              message: b.$3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: max == 0 ? 0 : (b.$2 / max).clamp(0.0, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 30), child: CustomPaint(size: Size.infinite, painter: _PrismPainter(scheme.primary, scheme.secondary))),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(b.$1, maxLines: 1, overflow: TextOverflow.clip, style: Theme.of(context).textTheme.labelSmall),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// A picture from the network. While loading, or if it fails, a calm tinted block stands in rather than a broken image.
class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({super.key, required this.url, this.fallback, this.fit = BoxFit.cover});
  final String? url;
  final Widget? fallback;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final blank = ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHigh, child: Center(child: fallback ?? Icon(Icons.restaurant, color: Theme.of(context).colorScheme.outline)));
    if (url == null) return SizedBox.expand(child: blank);
    return Image.network(
      url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => blank,
      frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : blank,
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final columns = box.maxWidth > Breakpoints.medium ? 4 : box.maxWidth > Breakpoints.compact ? 3 : 2;
        final width = (box.maxWidth - (columns - 1) * Space.md) / columns;
        return Wrap(spacing: Space.md, runSpacing: Space.md, children: [for (final w in children) SizedBox(width: width, child: w)]);
      });
}

/// Simple accessible horizontal bars. Values come from recorded data only.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.title, required this.rows, this.icon});
  final String title;
  final IconData? icon;
  final List<(String label, double value, String display)> rows;
  @override
  Widget build(BuildContext context) {
    final max = rows.fold<double>(0, (m, r) => r.$2 > m ? r.$2 : m);
    return Raised(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[GlossyIcon(icon: icon, size: 32), const SizedBox(width: 10)],
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: Space.md),
          if (rows.isEmpty) Text(context.l10n.noDataYet),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(r.$1, overflow: TextOverflow.ellipsis)), Text(r.$3)]),
                const SizedBox(height: Space.xs),
                Semantics(value: r.$3, child: _GlossBar(fraction: max == 0 ? 0 : r.$2 / max)),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// A bar seen slightly from above and to the side: a lit top, a shaded side and a graded front.
class _PrismPainter extends CustomPainter {
  _PrismPainter(this.primary, this.secondary);
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0 || size.width <= 0) return;
    final d = (size.width * 0.28).clamp(2.0, 8.0).toDouble();
    final h = size.height;
    final w = size.width;
    final front = Rect.fromLTWH(0, d.clamp(0, h), w - d, (h - d).clamp(0, h));
    canvas.drawRRect(RRect.fromRectAndCorners(front, bottomLeft: const Radius.circular(3)), Paint()..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [toneOf(primary, 0.32), toneOf(secondary, 0.55)]).createShader(front));
    final side = Path()..moveTo(w - d, d)..lineTo(w, 0)..lineTo(w, h - d)..lineTo(w - d, h)..close();
    canvas.drawPath(side, Paint()..color = toneOf(primary, 0.22));
    final top = Path()..moveTo(0, d)..lineTo(d, 0)..lineTo(w, 0)..lineTo(w - d, d)..close();
    canvas.drawPath(top, Paint()..color = toneOf(secondary, 0.72));
    // A thin shine down the front edge.
    canvas.drawRect(Rect.fromLTWH(front.left + 2, front.top, 2, front.height), Paint()..color = Colors.white.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(_PrismPainter old) => old.primary != primary || old.secondary != secondary;
}

/// A rounded bar in a sunken track, with a highlight along its top.
class _GlossBar extends StatelessWidget {
  const _GlossBar({required this.fraction});
  final double fraction;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Container(
      height: 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(s.surfaceContainerHighest, Colors.black, 0.06)!, s.surfaceContainerHigh]),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(colors: [toneOf(s.primary, 0.4), toneOf(s.secondary, 0.55)]),
            boxShadow: [BoxShadow(color: toneOf(s.primary, 0.4).withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          foregroundDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0)], stops: const [0, 0.6])),
        ),
      ),
    );
  }
}
