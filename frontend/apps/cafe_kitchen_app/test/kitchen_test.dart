import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:cafe_kitchen_app/features/board/data/board_repository.dart';
import 'package:cafe_kitchen_app/features/board/domain/board.dart';
import 'package:cafe_kitchen_app/features/board/presentation/board_cubit.dart';
import 'package:cafe_kitchen_app/features/board/presentation/ticket_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_design_system/shared_design_system.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';

KitchenTicket ticket(String id, {String status = 'new', int priority = 0, int elapsed = 1, bool delayed = false, String? station}) => KitchenTicket(
      publicId: id, status: status, priority: priority, orderNumber: 1, orderType: 'dine_in', tableNumber: 'T1', elapsedMinutes: elapsed, isDelayed: delayed, stationId: station,
      items: const [KitchenTicketItem(id: 1, name: 'Masala Chai', variant: 'Large', quantity: 2, notes: 'no sugar', addons: [KitchenTicketAddon(name: 'Ginger', quantity: 1)])],
    );

class FakeRepo implements BoardRepository {
  List<KitchenTicket> data = [];
  final moved = <String>[];
  ApiFailure? failure;
  @override
  String? get accessToken => 't';
  @override
  Future<List<KitchenTicket>> tickets({String? status}) async { if (failure != null) throw failure!; return data; }
  @override
  Future<void> setStatus(String id, String status) async => moved.add('$id:$status');
  @override
  Future<void> setPriority(String id, int p) async => moved.add('$id:p$p');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class FakeRealtime extends RealtimeClient {
  FakeRealtime() : super('http://x');
  final events_ = StreamController<RealtimeEvent>.broadcast();
  @override
  Stream<RealtimeEvent> get events => events_.stream;
  @override
  void connect({String? token, String? tableSession}) {}
  void fire(String type) => events_.add(RealtimeEvent(id: type, seq: 1, type: type, payload: const {}));
}

void main() {
  group('board rules', () {
    test('tickets flow through the columns', () {
      expect(columnOf(ticket('a')), BoardColumn.incoming);
      expect(columnOf(ticket('a', status: 'preparing')), BoardColumn.working);
      expect(columnOf(ticket('a', status: 'ready')), BoardColumn.ready);
    });
    test('one obvious next step at each stage', () {
      expect(['new', 'accepted', 'preparing', 'ready', 'completed'].map(nextStatus), ['accepted', 'preparing', 'ready', 'completed', null]);
    });
    test('order: priority, then delayed, then oldest', () {
      final s = sortTickets([ticket('old', elapsed: 9), ticket('late', delayed: true, elapsed: 2), ticket('vip', priority: 1)]);
      expect(s.map((t) => t.publicId), ['vip', 'late', 'old']);
    });
  });

  group('board cubit', () {
    late FakeRepo repo;
    late FakeRealtime rt;
    setUp(() { repo = FakeRepo(); rt = FakeRealtime(); });

    blocTest<BoardCubit, BoardState>('empty and failure are distinct states', build: () => BoardCubit(repo, rt), act: (c) async {
      await c.load();
      repo.failure = const ApiFailure.network();
      await c.load();
    }, expect: () => [isA<BoardState>().having((s) => s.view, 'v', isA<ViewLoading<List<KitchenTicket>>>()), isA<BoardState>().having((s) => s.view, 'v', isA<ViewEmpty<List<KitchenTicket>>>()), isA<BoardState>().having((s) => s.view, 'v', isA<ViewLoading<List<KitchenTicket>>>()), isA<BoardState>().having((s) => s.view, 'v', isA<ViewFailure<List<KitchenTicket>>>())]);

    test('a new-order event alerts and refreshes the board', () async {
      final c = BoardCubit(repo, rt);
      await c.start();
      repo.data = [ticket('t1')];
      rt.fire('order.placed');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.state.newOrderTick, 1);
      expect((c.state.view as ViewSuccess<List<KitchenTicket>>).data.length, 1);
      await c.close();
    });

    test('advance sends the next status', () async {
      final c = BoardCubit(repo, rt);
      await c.advance(ticket('t1', status: 'accepted'));
      expect(repo.moved, ['t1:preparing']);
      await c.close();
    });

    test('filtering by station', () {
      final all = [ticket('a', station: 'grill'), ticket('b', station: 'bar')];
      expect(const BoardState(station: 'bar').column(BoardColumn.incoming, all).map((t) => t.publicId), ['b']);
    });
  });

  testWidgets('a ticket shows everything the cook needs', (t) async {
    var tapped = 0;
    await t.pumpWidget(MaterialApp(theme: AppThemes.kitchen(), supportedLocales: supportedAppLocales, localizationsDelegates: appLocalizationDelegates, home: Scaffold(body: SingleChildScrollView(child: TicketCard(ticket: ticket('x', delayed: true, elapsed: 20), onAdvance: () => tapped++, onPriority: () {})))));
    await t.pumpAndSettle();
    for (final s in ['Table T1', '2×', 'Masala Chai', 'Large', '+ Ginger', 'no sugar', '20 min', 'Delayed']) {
      expect(find.textContaining(s), findsOneWidget, reason: s);
    }
    await t.tap(find.byType(FilledButton));
    expect(tapped, 1);
    expect(t.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(64), reason: 'large touch target');
  });
}
