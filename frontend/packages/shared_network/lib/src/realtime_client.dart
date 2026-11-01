import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

class RealtimeEvent {
  const RealtimeEvent({required this.id, required this.seq, required this.type, required this.payload});
  final String id;
  final int seq;
  final String type;
  final Map<String, dynamic> payload;
}

/// Delivers each event once, in order of arrival, and replays what was missed after a dropped connection.
/// The server decides which rooms a credential can hear; clients have no way to ask for others.
class RealtimeClient {
  RealtimeClient(this.baseUrl);
  final String baseUrl;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _connected = StreamController<bool>.broadcast();
  final _seen = <String>{};
  int _lastSeq = 0;
  io.Socket? _socket;

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<bool> get connection => _connected.stream;

  void connect({String? token, String? tableSession}) {
    disconnect();
    Map<String, dynamic> auth() => {if (token != null) 'token': token, if (tableSession != null) 'tableSession': tableSession, 'lastSeq': _lastSeq};
    final socket = io.io(baseUrl, io.OptionBuilder().setTransports(['websocket']).enableReconnection().disableAutoConnect().setAuth(auth()).build());
    socket
      ..onConnect((_) => _connected.add(true))
      ..onDisconnect((_) => _connected.add(false))
      ..onConnectError((_) => _connected.add(false))
      // lastSeq must be current each time a reconnect handshakes, or the replay would start too early.
      ..onReconnectAttempt((_) => socket.auth = auth())
      ..on('event', (dynamic raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final id = m['eventId'] as String;
        if (!_seen.add(id)) return;
        if (_seen.length > 2000) _seen.remove(_seen.first);
        final seq = (m['seq'] as num?)?.toInt() ?? 0;
        if (seq > _lastSeq) _lastSeq = seq;
        _events.add(RealtimeEvent(id: id, seq: seq, type: m['type'] as String, payload: Map<String, dynamic>.from(m['payload'] as Map)));
      })
      ..connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _events.close();
    _connected.close();
  }
}
