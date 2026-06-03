import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectivityState { online, offline }

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityCubit() : super(ConnectivityState.online) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateState(result);
    } catch (_) {
      emit(ConnectivityState.offline);
    }

    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(ConnectivityResult result) {
    final hasConnection = result != ConnectivityResult.none;
    emit(hasConnection ? ConnectivityState.online : ConnectivityState.offline);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
