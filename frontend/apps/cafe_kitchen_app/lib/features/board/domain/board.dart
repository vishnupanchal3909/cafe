import 'package:shared_models/shared_models.dart';

enum BoardColumn { incoming, working, ready }

BoardColumn columnOf(KitchenTicket t) => switch (t.status) {
      'new' => BoardColumn.incoming,
      'ready' => BoardColumn.ready,
      _ => BoardColumn.working,
    };

/// What one tap on a ticket does next. A kitchen screen offers a single obvious action.
String? nextStatus(String status) => switch (status) {
      'new' => 'accepted',
      'accepted' => 'preparing',
      'preparing' => 'ready',
      'ready' => 'completed',
      _ => null,
    };

/// Most urgent first: priority, then delayed, then oldest.
List<KitchenTicket> sortTickets(Iterable<KitchenTicket> tickets) => tickets.toList()
  ..sort((a, b) {
    final p = b.priority.compareTo(a.priority);
    if (p != 0) return p;
    if (a.isDelayed != b.isDelayed) return a.isDelayed ? -1 : 1;
    return b.elapsedMinutes.compareTo(a.elapsedMinutes);
  });
