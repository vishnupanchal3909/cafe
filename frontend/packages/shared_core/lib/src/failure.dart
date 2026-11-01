import 'package:equatable/equatable.dart';

/// A failure the UI can act on. [code] is stable and never translated; [message] is localized by the server.
class ApiFailure extends Equatable implements Exception {
  const ApiFailure({required this.code, required this.message, this.status, this.details});

  const ApiFailure.network() : this(code: 'NETWORK', message: '');

  final String code;
  final String message;
  final int? status;
  final Object? details;

  bool get isNetwork => code == 'NETWORK';

  @override
  List<Object?> get props => [code, message, status];

  @override
  String toString() => 'ApiFailure($code, $status)';
}
