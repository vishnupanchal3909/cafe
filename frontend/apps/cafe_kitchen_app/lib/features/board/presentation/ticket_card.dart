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
    final action = switch (nextStatus(t.status)) {
      'accepted' => l.accept,
      'preparing' => l.startPreparing,
      'ready' => l.markReady,
      'completed' => l.complete,
      _ => null,
    };
    final tone = t.isDelayed ? Colors.red : laneColor(columnOf(t));
    final halo = t.isDelayed ? Colors.redAccent : t.priority > 0 ? Colors.amber : null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A2A30), Color(0xFF1B1B20)]),
        border: Border.all(color: halo ?? Colors.white.withValues(alpha: 0.08), width: halo == null ? 1 : 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 14), spreadRadius: -6),
          if (halo != null) BoxShadow(color: halo.withValues(alpha: 0.45), blurRadius: 28, spreadRadius: -2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(halo == null ? 21 : 19),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(Space.md, 10, Space.xs, 10),
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [toneOf(tone, 0.5), toneOf(tone, 0.34)])),
            foregroundDecoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0)], stops: const [0, 0.5])),
            child: Row(children: [
              Expanded(child: Text(t.tableNumber != null ? l.welcomeTable(t.tableNumber!) : l.takeaway, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white))),
              Text('#${t.orderNumber}', style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              IconButton(tooltip: l.priority, iconSize: 32, onPressed: onPriority, icon: Icon(t.priority > 0 ? Icons.bolt : Icons.bolt_outlined, color: t.priority > 0 ? Colors.amberAccent : Colors.white)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(t.isDelayed ? Icons.warning_amber : Icons.timer_outlined, color: t.isDelayed ? Colors.redAccent : Colors.white70),
                const SizedBox(width: Space.xs),
                Text(l.minutesShort(t.elapsedMinutes), style: text.titleLarge?.copyWith(color: t.isDelayed ? Colors.redAccent : null, fontWeight: FontWeight.w800)),
                if (t.isDelayed) ...[const SizedBox(width: Space.sm), Text(l.delayed, style: text.titleMedium?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w700))],
                const Spacer(),
                if (t.stationName != null) Text(t.stationName!, style: text.titleMedium),
              ]),
              Divider(height: Space.lg, color: Colors.white.withValues(alpha: 0.1)),
              for (final i in t.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0.06)]),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text('${i.quantity}×', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: Space.sm),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      if (i.variant != null) Text(i.variant!, style: text.titleMedium),
                      for (final a in i.addons) Text('+ ${a.quantity > 1 ? '${a.quantity}× ' : ''}${a.name}', style: text.titleMedium),
                      if (i.notes != null && i.notes!.isNotEmpty) _Note(i.notes!),
                    ])),
                  ]),
                ),
              if (t.customerNotes != null && t.customerNotes!.isNotEmpty) _Note(t.customerNotes!),
              if (action != null) ...[
                const SizedBox(height: Space.sm),
                FilledButton(style: FilledButton.styleFrom(backgroundColor: toneOf(laneColor(columnOf(t)), 0.62), foregroundColor: Colors.black), onPressed: onAdvance, child: Text(action)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Each lane has its own colour, so a glance tells new from cooking from ready. The lane's title always says it too.
Color laneColor(BoardColumn c) => switch (c) {
      BoardColumn.incoming => Colors.lightBlue,
      BoardColumn.working => Colors.orange,
      BoardColumn.ready => Colors.green,
    };

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: Space.xs),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.45))),
        child: Row(children: [const Icon(Icons.sticky_note_2_outlined, size: 20), const SizedBox(width: Space.xs), Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium))]),
      );
}
