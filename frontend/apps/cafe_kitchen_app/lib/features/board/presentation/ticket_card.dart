import 'package:flutter/material.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';
import '../domain/board.dart';

class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket, required this.onAdvance, required this.onPriority});
  final KitchenTicket ticket;
  final VoidCallback onAdvance;
  final VoidCallback onPriority;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = ticket;
    final text = Theme.of(context).textTheme;
    final borderColor = t.isDelayed ? Colors.redAccent : t.priority > 0 ? Colors.amber : Theme.of(context).colorScheme.outlineVariant;
    final action = switch (nextStatus(t.status)) {
      'accepted' => l.accept,
      'preparing' => l.startPreparing,
      'ready' => l.markReady,
      'completed' => l.complete,
      _ => null,
    };
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: t.isDelayed || t.priority > 0 ? 3 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(t.tableNumber != null ? l.welcomeTable(t.tableNumber!) : l.takeaway, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
            Text('#${t.orderNumber}', style: text.titleLarge),
            IconButton(tooltip: l.priority, iconSize: 32, onPressed: onPriority, icon: Icon(t.priority > 0 ? Icons.bolt : Icons.bolt_outlined, color: t.priority > 0 ? Colors.amber : null)),
          ]),
          Row(children: [
            Icon(t.isDelayed ? Icons.warning_amber : Icons.timer_outlined, color: t.isDelayed ? Colors.redAccent : null),
            const SizedBox(width: Space.xs),
            Text(l.minutesShort(t.elapsedMinutes), style: text.titleLarge?.copyWith(color: t.isDelayed ? Colors.redAccent : null, fontWeight: FontWeight.w700)),
            if (t.isDelayed) ...[const SizedBox(width: Space.sm), Text(l.delayed, style: text.titleMedium?.copyWith(color: Colors.redAccent))],
            const Spacer(),
            if (t.stationName != null) Text(t.stationName!, style: text.titleMedium),
          ]),
          const Divider(height: Space.lg),
          for (final i in t.items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i.quantity}×', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: Space.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.name, style: text.titleLarge),
                  if (i.variant != null) Text(i.variant!, style: text.titleMedium),
                  for (final a in i.addons) Text('+ ${a.quantity > 1 ? '${a.quantity}× ' : ''}${a.name}', style: text.titleMedium),
                  if (i.notes != null && i.notes!.isNotEmpty) _Note(i.notes!),
                ])),
              ]),
            ),
          if (t.customerNotes != null && t.customerNotes!.isNotEmpty) _Note(t.customerNotes!),
          if (action != null) ...[const SizedBox(height: Space.sm), FilledButton(onPressed: onAdvance, child: Text(action))],
        ]),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: Space.xs),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [const Icon(Icons.sticky_note_2_outlined, size: 20), const SizedBox(width: Space.xs), Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium))]),
      );
}
