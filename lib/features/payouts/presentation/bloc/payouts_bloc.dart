import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/warlord_estimate_entity.dart';
import '../../domain/usecases/get_warlord_estimate.dart';

// ==========================================
// EVENTS
// ==========================================
sealed class PayoutsEvent extends Equatable {
  const PayoutsEvent();

  @override
  List<Object?> get props => [];
}

final class WarlordEstimateRequested extends PayoutsEvent {
  const WarlordEstimateRequested();
}

// ==========================================
// STATES
// ==========================================
sealed class PayoutsState extends Equatable {
  const PayoutsState();

  @override
  List<Object?> get props => [];
}

final class PayoutsInitial extends PayoutsState {}

final class PayoutsLoading extends PayoutsState {}

final class WarlordEstimateLoaded extends PayoutsState {
  final WarlordEstimateEntity estimate;

  const WarlordEstimateLoaded(this.estimate);

  @override
  List<Object?> get props => [estimate];
}

final class PayoutsFailure extends PayoutsState {
  final String message;

  const PayoutsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ==========================================
// BLOC
// ==========================================
class PayoutsBloc extends Bloc<PayoutsEvent, PayoutsState> {
  final GetWarlordEstimate _getWarlordEstimate;

  PayoutsBloc({required GetWarlordEstimate getWarlordEstimate})
      : _getWarlordEstimate = getWarlordEstimate,
        super(PayoutsInitial()) {
    on<WarlordEstimateRequested>(_onWarlordEstimateRequested);
  }

  Future<void> _onWarlordEstimateRequested(
    WarlordEstimateRequested event,
    Emitter<PayoutsState> emit,
  ) async {
    emit(PayoutsLoading());
    final result = await _getWarlordEstimate();
    result.fold(
      (failure) => emit(PayoutsFailure(failure.message)),
      (estimate) => emit(WarlordEstimateLoaded(estimate)),
    );
  }
}
