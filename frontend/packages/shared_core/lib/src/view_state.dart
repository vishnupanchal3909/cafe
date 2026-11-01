import 'package:equatable/equatable.dart';
import 'failure.dart';

/// Every async screen is exactly one of these, so loading, empty and error cannot be forgotten.
sealed class ViewState<T> extends Equatable {
  const ViewState();
  @override
  List<Object?> get props => const [];
}

class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewSuccess<T> extends ViewState<T> {
  const ViewSuccess(this.data);
  final T data;
  @override
  List<Object?> get props => [data];
}

class ViewFailure<T> extends ViewState<T> {
  const ViewFailure(this.failure);
  final ApiFailure failure;
  @override
  List<Object?> get props => [failure];
}
