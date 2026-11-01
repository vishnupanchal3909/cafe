import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_network/shared_network.dart';
import '../data/board_repository.dart';
import '../domain/board.dart';

class BoardState extends Equatable {
  const BoardState({this.view = const ViewInitial(), this.connected = true, this.station, this.newOrderTick = 0});
  final ViewState<List<KitchenTicket>> view;
  final bool connected;
  final String? station;

  /// Increments whenever a new order arrives, which is what triggers the alert sound.
  final int newOrderTick;

  List<KitchenTicket> column(BoardColumn c, List<KitchenTicket> all) => sortTickets(all.where((t) => columnOf(t) == c && (station == null || t.stationId == station)));

  BoardState copyWith({ViewState<List<KitchenTicket>>? view, bool? connected, Object? station = _keep, int? newOrderTick}) =>
      BoardState(view: view ?? this.view, connected: connected ?? this.connected, station: identical(station, _keep) ? this.station : station as String?, newOrderTick: newOrderTick ?? this.newOrderTick);
  static const _keep = Object();

  @override
  List<Object?> get props => [view, connected, station, newOrderTick];
}

class BoardCubit extends Cubit<BoardState> {
  BoardCubit(this._repo, this._realtime) : super(const BoardState());
  final BoardRepository _repo;
  final RealtimeClient _realtime;
  StreamSubscription<RealtimeEvent>? _events;
  StreamSubscription<bool>? _conn;
  Timer? _tick;

  Future<void> start() async {
    await load();
    _realtime.connect(token: _repo.accessToken);
    _events = _realtime.events.listen((e) {
      if (e.type == 'order.placed') emit(state.copyWith(newOrderTick: state.newOrderTick + 1));
      if (e.type.startsWith('order.') || e.type.startsWith('kitchen.')) load(silent: true);
    });
    _conn = _realtime.connection.listen((up) {
      emit(state.copyWith(connected: up));
      if (up) load(silent: true);
    });
    // Keeps timers and delay flags honest, and covers any event lost while reconnecting.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => load(silent: true));
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(view: const ViewLoading()));
    try {
      final tickets = await _repo.tickets();
      if (!isClosed) emit(state.copyWith(view: tickets.isEmpty ? const ViewEmpty() : ViewSuccess(tickets)));
    } on ApiFailure catch (f) {
      if (!isClosed && !silent) emit(state.copyWith(view: ViewFailure(f)));
    }
  }

  void filterStation(String? id) => emit(state.copyWith(station: id));

  Future<void> advance(KitchenTicket t) async {
    final next = nextStatus(t.status);
    if (next == null) return;
    await _repo.setStatus(t.publicId, next);
    await load(silent: true);
  }

  Future<void> togglePriority(KitchenTicket t) async {
    await _repo.setPriority(t.publicId, t.priority > 0 ? 0 : 1);
    await load(silent: true);
  }

  @override
  Future<void> close() {
    _events?.cancel();
    _conn?.cancel();
    _tick?.cancel();
    _realtime.disconnect();
    return super.close();
  }
}
