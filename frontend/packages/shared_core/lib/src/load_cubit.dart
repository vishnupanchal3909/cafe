import 'package:flutter_bloc/flutter_bloc.dart';
import 'failure.dart';
import 'view_state.dart';

/// Runs a load and maps the outcome to a [ViewState]. Screens with no extra behaviour use this directly.
class LoadCubit<T> extends Cubit<ViewState<T>> {
  LoadCubit(this._load, {bool Function(T)? isEmpty}) : _isEmpty = isEmpty, super(ViewInitial<T>());

  final Future<T> Function() _load;
  final bool Function(T)? _isEmpty;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(ViewLoading<T>());
    try {
      final data = await _load();
      if (isClosed) return;
      final empty = _isEmpty?.call(data) ?? (data is Iterable && data.isEmpty);
      emit(empty ? ViewEmpty<T>() : ViewSuccess<T>(data));
    } on ApiFailure catch (f) {
      if (!isClosed) emit(ViewFailure<T>(f));
    }
  }
}
