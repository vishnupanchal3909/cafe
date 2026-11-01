import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_network/shared_network.dart';
import '../data/session_repository.dart';

class SessionState extends Equatable {
  const SessionState({this.context, this.failure, this.language = 'en', this.loading = false});
  final TableContext? context;
  final ApiFailure? failure;
  final String language;
  final bool loading;
  @override
  List<Object?> get props => [context?.sessionToken, context?.config, failure, language, loading];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repo, this._api, {String? deviceLanguage}) : super(SessionState(language: deviceLanguage ?? 'en'));
  final SessionRepository _repo;
  final ApiClient _api;
  String? _token;

  Future<void> scan(String qrToken) async {
    _token = qrToken;
    emit(SessionState(language: state.language, loading: true));
    try {
      final ctx = await _repo.scan(qrToken, state.language);
      if (!ctx.config.languages.any((l) => l.code == state.language)) {
        _api.language = ctx.config.defaultLanguage;
        emit(SessionState(context: ctx, language: ctx.config.defaultLanguage));
        return;
      }
      _api.language = state.language;
      emit(SessionState(context: ctx, language: state.language));
    } on ApiFailure catch (f) {
      emit(SessionState(failure: f, language: state.language));
    }
  }

  Future<void> setLanguage(String code) async {
    _api.language = code;
    final current = state.context;
    emit(SessionState(context: current, language: code));
    if (_token != null) {
      final ctx = await _repo.scan(_token!, code);
      emit(SessionState(context: ctx, language: code));
    }
  }
}
