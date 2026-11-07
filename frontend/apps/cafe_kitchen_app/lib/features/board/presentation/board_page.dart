import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';
import '../data/board_repository.dart';
import '../domain/board.dart';
import 'alert_sound_stub.dart' if (dart.library.js_interop) 'alert_sound_web.dart';
import 'board_cubit.dart';
import 'ticket_card.dart';

class BoardPage extends StatelessWidget {
  const BoardPage({super.key, required this.onSignOut});
  final VoidCallback onSignOut;
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => BoardCubit(GetIt.I<BoardRepository>(), GetIt.I<RealtimeClient>())..start(),
        child: _Board(onSignOut: onSignOut),
      );
}

class _Board extends StatelessWidget {
  const _Board({required this.onSignOut});
  final VoidCallback onSignOut;

  Future<void> _guard(BuildContext c, Future<void> Function() action) async {
    try {
      await action();
    } on ApiFailure catch (f) {
      if (c.mounted) showFailure(c, f);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<BoardCubit, BoardState>(
      listenWhen: (a, b) => a.newOrderTick != b.newOrderTick,
      listener: (_, _) => playAlert(),
      builder: (c, s) => AmbientBackdrop(child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          toolbarHeight: 72,
          title: Row(children: [const GlossyIcon(icon: Icons.soup_kitchen_outlined, size: 44), const SizedBox(width: Space.md), Flexible(child: Text(l.kitchenDisplay, overflow: TextOverflow.ellipsis))]),
          actions: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: GetIt.I<BoardRepository>().stations(),
              builder: (_, snap) => (snap.data?.isEmpty ?? true)
                  ? const SizedBox.shrink()
                  : DropdownButton<String?>(
                      value: s.station,
                      underline: const SizedBox.shrink(),
                      items: [DropdownMenuItem(value: null, child: Text(l.allStations)), for (final st in snap.data!) DropdownMenuItem(value: st['public_id'] as String, child: Text(st['name'] as String))],
                      onChanged: c.read<BoardCubit>().filterStation,
                    ),
            ),
            IconButton(
              tooltip: l.completedOrders,
              icon: const Icon(Icons.history),
              onPressed: () => showModalBottomSheet<void>(context: c, builder: (_) => FutureBuilder<List<KitchenTicket>>(
                    future: GetIt.I<BoardRepository>().tickets(status: 'completed'),
                    builder: (sc, snap) => !snap.hasData
                        ? const SkeletonList(count: 3)
                        : snap.data!.isEmpty
                            ? EmptyState(message: l.noTickets)
                            : ListView(children: [for (final t in snap.data!) ListTile(title: Text('#${t.orderNumber} ${t.tableNumber ?? l.takeaway}'), subtitle: Text(t.items.map((i) => '${i.quantity}× ${i.name}').join(', ')), trailing: Text(l.minutesShort(t.elapsedMinutes)))]),
                  )),
            ),
            IconButton(tooltip: l.refresh, onPressed: () => c.read<BoardCubit>().load(silent: true), icon: const Icon(Icons.refresh)),
            IconButton(tooltip: l.signOut, onPressed: onSignOut, icon: const Icon(Icons.logout)),
          ],
          bottom: s.connected ? null : PreferredSize(preferredSize: const Size.fromHeight(40), child: Container(color: Colors.red.shade800, width: double.infinity, padding: const EdgeInsets.all(Space.sm), child: Text(l.connectionLost, textAlign: TextAlign.center))),
        ),
        body: AsyncView<List<KitchenTicket>>(
          state: s.view,
          onRetry: () => c.read<BoardCubit>().load(),
          empty: EmptyState(icon: Icons.soup_kitchen, message: l.noTickets),
          builder: (all) => LayoutBuilder(builder: (c, box) {
            Widget col(BoardColumn column, String title, IconData icon) {
              final tickets = s.column(column, all);
              final tone = laneColor(column);
              // Each lane is a shallow tray the tickets sit in.
              return Container(
                margin: const EdgeInsets.all(Space.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tone.withValues(alpha: 0.10), Colors.white.withValues(alpha: 0.02)]),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.xs),
                    child: Row(children: [
                      GlossyIcon(icon: icon, color: tone, size: 44),
                      const SizedBox(width: Space.md),
                      Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: toneOf(tone, 0.6), boxShadow: [BoxShadow(color: tone.withValues(alpha: 0.5), blurRadius: 14, spreadRadius: -3)]),
                        child: Text('${tickets.length}', textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
                      ),
                    ]),
                  ),
                  Expanded(child: ListView.separated(
                    padding: const EdgeInsets.all(Space.md),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Space.md),
                    itemBuilder: (_, i) => TicketCard(
                      ticket: tickets[i],
                      onAdvance: () => _guard(c, () => c.read<BoardCubit>().advance(tickets[i])),
                      onPriority: () => _guard(c, () => c.read<BoardCubit>().togglePriority(tickets[i])),
                    ),
                  )),
              ]));
            }
            final columns = [col(BoardColumn.incoming, l.kitchenNew, Icons.fiber_new), col(BoardColumn.working, l.kitchenInProgress, Icons.local_fire_department), col(BoardColumn.ready, l.kitchenReady, Icons.room_service)];
            if (box.maxWidth >= Breakpoints.medium) return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final w in columns) Expanded(child: w)]);
            return DefaultTabController(length: 3, child: Column(children: [
              TabBar(tabs: [Tab(text: l.kitchenNew), Tab(text: l.kitchenInProgress), Tab(text: l.kitchenReady)]),
              Expanded(child: TabBarView(children: columns)),
            ]));
          }),
        ),
      )),
    );
  }
}
