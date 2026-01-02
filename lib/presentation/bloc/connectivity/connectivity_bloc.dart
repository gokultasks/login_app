import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/sync_service.dart';


abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object?> get props => [];
}

class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> result;

  const ConnectivityChanged(this.result);

  @override
  List<Object?> get props => [result];
}

class CheckConnectivity extends ConnectivityEvent {}


abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}


class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  final SyncService? syncService;
  StreamSubscription? _connectivitySubscription;
  bool _wasOffline = false;

  ConnectivityBloc({this.syncService}) : super(ConnectivityInitial()) {
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged(result));
    });

  
    add(CheckConnectivity());
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) async {
    final bool isOnline = event.result.contains(ConnectivityResult.mobile) || 
        event.result.contains(ConnectivityResult.wifi);
    
    if (isOnline) {
   
      if (_wasOffline && syncService != null) {
        await syncService!.syncPendingOperations();
      }
      _wasOffline = false;
      emit(ConnectivityOnline());
    } else {
      _wasOffline = true;
      emit(ConnectivityOffline());
      emit(ConnectivityOffline());
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.mobile) || 
        result.contains(ConnectivityResult.wifi)) {
      emit(ConnectivityOnline());
    } else {
      emit(ConnectivityOffline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
