import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_localization/shared_localization.dart';
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
      itemBuilder: (_, _) => Container(height: 72, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
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
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: Space.md),
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
          Icon(failure.isNetwork ? Icons.wifi_off : Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Space.md),
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
  const StatCard({super.key, required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: Space.sm)], Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge))]),
            const SizedBox(height: Space.sm),
            FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700))),
          ]),
        ),
      );
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
  const BarList({super.key, required this.title, required this.rows});
  final String title;
  final List<(String label, double value, String display)> rows;
  @override
  Widget build(BuildContext context) {
    final max = rows.fold<double>(0, (m, r) => r.$2 > m ? r.$2 : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: Space.md),
          if (rows.isEmpty) Text(context.l10n.noDataYet),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(r.$1, overflow: TextOverflow.ellipsis)), Text(r.$3)]),
                const SizedBox(height: Space.xs),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: max == 0 ? 0 : r.$2 / max, minHeight: 8)),
              ]),
            ),
        ]),
      ),
    );
  }
}
