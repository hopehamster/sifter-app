import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_state.freezed.dart';

@freezed
class AppState<T> with _$AppState<T> {
  const factory AppState.initial() = _Initial;
  const factory AppState.loading() = _Loading;
  const factory AppState.success(T data) = _Success;
  const factory AppState.error(String message) = _Error;
}

extension AppStateX<T> on AppState<T> {
  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isSuccess => this is _Success;
  bool get isError => this is _Error;
  
  T? get data => isSuccess ? (this as _Success<T>).data : null;
  String? get errorMessage => isError ? (this as _Error<T>).message : null;
} 